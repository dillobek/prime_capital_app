import 'package:flutter/material.dart';

import 'api_client.dart';
import 'models.dart';

/// Holds the signed-in state for the whole app: the API client (and its
/// token), the loaded profile, and whether we're still checking for a
/// stored session on launch. Mirrors Webapp's `loadProfile()` flow in
/// `web-app.tsx`.
class AppSession extends ChangeNotifier {
  AppSession(this.api);

  final ApiClient api;
  Profile? profile;
  bool checking = true;
  String? bootError;

  bool get isSignedIn => profile != null;

  Future<void> bootstrap() async {
    await api.loadToken();
    await _loadProfileFromToken();
    checking = false;
    notifyListeners();
  }

  Future<void> _loadProfileFromToken() async {
    final userId = api.currentUserId;
    if (userId == null) return;
    try {
      profile = await api.getProfile(userId);
    } catch (_) {
      // Token invalid/expired or server unreachable — fall back to signed-out.
      profile = null;
    }
  }

  // --- Phone + SMS-OTP (see ApiClient) ---
  Future<Map<String, dynamic>> requestOtp(String phone) => api.requestOtp(phone);

  /// Returns true once fully signed in (existing phone). Returns false when
  /// the phone is new and [completeProfile] must be called next.
  Future<bool> verifyOtp({required String phone, required String code}) async {
    final signedIn = await api.verifyOtp(phone: phone, code: code);
    if (signedIn) {
      await _loadProfileFromToken();
      notifyListeners();
    }
    return signedIn;
  }

  Future<void> completeProfile({required String phone, required String name}) async {
    await api.completeOtpProfile(phone: phone, name: name);
    await _loadProfileFromToken();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfileFromToken();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.clearToken();
    profile = null;
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<AppSession> {
  const SessionScope({super.key, required AppSession session, required super.child}) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope not found in context');
    return scope!.notifier!;
  }
}
