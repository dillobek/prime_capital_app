import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('unauthorized');
}

/// Thin REST client for Backend's `api/v1` — mirrors the routes wired up in
/// `Backend/src/platform/platform.controller.ts`, `properties.controller.ts`
/// and `balances.controller.ts`. Every authenticated call sends the stored
/// JWT as `Authorization: Bearer <token>`; the server always derives
/// `userId` from that token, never from the request body.
class ApiClient {
  ApiClient({this.baseUrl = ''});

  final String baseUrl;
  static const _tokenKey = 'prime_mobile_token';
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _persistToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Decodes the `sub` (user id) claim out of the stored JWT without
  /// verifying the signature — the backend is the one that verifies it on
  /// every request; the client only needs the id to know which profile to
  /// fetch, same as Webapp does.
  String? get currentUserId {
    final jwt = _token;
    if (jwt == null) return null;
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final remainder = payload.length % 4;
      if (remainder == 2) payload += '==';
      if (remainder == 3) payload += '=';
      final decoded = jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
      return decoded['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _request(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'content-type': 'application/json',
      if (_token != null) 'authorization': 'Bearer $_token',
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: encodedBody);
    } else if (method == 'PATCH') {
      response = await http.patch(uri, headers: headers, body: encodedBody);
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers);
    } else {
      throw ApiException('Noma\'lum method: $method');
    }

    if (response.statusCode == 401) {
      await clearToken();
      throw UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractMessage(response));
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _extractMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['message'] != null) {
        final message = decoded['message'];
        if (message is List) return message.join(', ');
        return message.toString();
      }
    } catch (_) {
      /* fall through to raw body below */
    }
    return response.body.isNotEmpty ? response.body : 'Xatolik (${response.statusCode})';
  }

  // --- Auth: phone + SMS-OTP (see Backend/src/otp) ---
  // Mobile no longer offers email/password — that stays admin/Frontend-only.
  // Three steps: requestOtp -> verifyOtp -> (only for a brand-new phone) completeOtpProfile.

  /// Sends a 6-digit SMS code to [phone] (normalized server-side to
  /// `+998XXXXXXXXX`). Returns `{sentTo, expiresInSeconds, resendInSeconds}`.
  Future<Map<String, dynamic>> requestOtp(String phone) async =>
      await _request('POST', '/auth/otp/request', body: {'phone': phone}) as Map<String, dynamic>;

  /// Returns true and stores the token if the phone already had an account
  /// (login complete). Returns false when the phone is new — the caller
  /// should then collect a name and call [completeOtpProfile].
  Future<bool> verifyOtp({required String phone, required String code}) async {
    final data = await _request('POST', '/auth/otp/verify', body: {'phone': phone, 'code': code}) as Map<String, dynamic>;
    final needsProfile = data['needsProfile'] == true;
    if (!needsProfile) {
      await _persistToken(data['accessToken'] as String);
    }
    return !needsProfile;
  }

  /// Creates a phone-only account (no email/password) right after a
  /// successful [verifyOtp] that returned `needsProfile: true`.
  Future<void> completeOtpProfile({required String phone, required String name}) async {
    final data = await _request('POST', '/auth/otp/complete-profile', body: {'phone': phone, 'name': name}) as Map<String, dynamic>;
    await _persistToken(data['accessToken'] as String);
  }

  // --- Profile ---
  Future<Profile> getProfile(String userId) async {
    final data = await _request('GET', '/users/$userId') as Map<String, dynamic>;
    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile(String userId, Map<String, dynamic> patch) async {
    final data = await _request('PATCH', '/users/$userId', body: patch) as Map<String, dynamic>;
    return Profile.fromJson(data);
  }

  // --- Balances (admin-set monthly % per product; per-user amount lives on Profile) ---
  Future<List<Balance>> getBalances() async {
    final data = await _request('GET', '/balances') as List<dynamic>;
    return data.map((item) => Balance.fromJson(item as Map<String, dynamic>)).toList();
  }

  // --- Properties ---
  Future<List<PropertyListing>> getProperties({String? type, String? status, int? limit}) async {
    final query = <String, String>{
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (limit != null) 'limit': '$limit',
    };
    final path = query.isEmpty ? '/properties' : '/properties?${Uri(queryParameters: query).query}';
    final data = await _request('GET', path) as List<dynamic>;
    return data.map((item) => PropertyListing.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> incrementPropertyView(String id) => _request('POST', '/properties/$id/view');

  // --- Money movement ---
  Future<void> createInvestment({required String product, required double amount, String? note}) =>
      _request('POST', '/investments', body: {
        'product': product,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> createWithdrawal({required String product, required double amount, String? note}) =>
      _request('POST', '/withdrawals', body: {
        'product': product,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  // --- Personal finance tracker ---
  Future<List<FinanceEntry>> getFinance() async {
    final data = await _request('GET', '/finance') as List<dynamic>;
    return data.map((item) => FinanceEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<FinanceEntry> addFinance({required String type, required String category, required double amount, String? note}) async {
    final data = await _request('POST', '/finance', body: {
      'type': type,
      'category': category,
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    }) as Map<String, dynamic>;
    return FinanceEntry.fromJson(data);
  }

  Future<void> removeFinance(String id) => _request('DELETE', '/finance/$id');

  // --- Support ---
  Future<void> createSupport({required String subject, required String message}) =>
      _request('POST', '/support', body: {'subject': subject, 'message': message});

  // --- Marketing content ---
  Future<List<ContentItem>> getBanners() async {
    final data = await _request('GET', '/banners') as List<dynamic>;
    return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ContentItem>> getVideos() async {
    final data = await _request('GET', '/videos') as List<dynamic>;
    return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ContentItem>> getNotifications() async {
    final data = await _request('GET', '/notifications') as List<dynamic>;
    return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  // --- Promotion report: user submits proof of an off-platform top-up ---
  Future<void> createPromotionReport({
    double? phpInvestAmount,
    double? primeCapitalAmount,
    required String description,
    required List<String> images,
  }) =>
      _request('POST', '/promotion-reports', body: {
        if (phpInvestAmount != null) 'phpInvestAmount': phpInvestAmount,
        if (primeCapitalAmount != null) 'primeCapitalAmount': primeCapitalAmount,
        'description': description,
        'images': images,
      });
}
