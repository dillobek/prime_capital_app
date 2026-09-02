import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../widgets/prime_logo.dart';

enum _Mode { login, register }

enum _Step { details, code }

const String _uzPhonePrefix = '+998 ';

/// Formats free-typed digits into `+998 XX XXX XX XX` as the user types —
/// the `+998 ` prefix is fixed (can't be edited/deleted away) and input is
/// capped at 9 digits after it, so the field can never grow past
/// `+998 99 123 45 67`.
class _UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('998')) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);

    final buffer = StringBuffer(_uzPhonePrefix);
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 4 || i == 6) && i != digits.length - 1) buffer.write(' ');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Masks a normalized `+998XXXXXXXXX` phone down to `+998 9* *** ** *6` —
/// only the very first and very last digit stay visible, same grouping as
/// the input formatter above. Used so the code-step subtitle doesn't show
/// the whole phone number back to whoever is looking at the screen.
String _maskPhone(String normalized) {
  final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 9) return normalized;
  final local = digits.substring(digits.length - 9);
  final masked = List.generate(9, (i) => (i == 0 || i == 8) ? local[i] : '*');
  final groups = [
    masked.sublist(0, 2).join(),
    masked.sublist(2, 5).join(),
    masked.sublist(5, 7).join(),
    masked.sublist(7, 9).join(),
  ];
  return '+998 ${groups.join(' ')}';
}

/// Login (phone + SMS-OTP) and register (F.I.O + phone + SMS-OTP) — see
/// Backend/src/otp. The two share the same code-verification step; only the
/// first step differs, and a link at the bottom switches between them.
///
/// Login only ever sends a phone number: if that number turns out to have
/// no account (`needsProfile: true`), it's an error ("Raqam topilmadi") —
/// login never silently registers. Register collects F.I.O up front and,
/// right after the code is verified, either logs the person in (the number
/// already existed — the typed name is simply unused) or finishes creating
/// the account with that name (brand-new number) — no extra step needed.
///
/// This is also how a user who originally registered through the Telegram
/// bot logs in outside Telegram, since both sides match on the same
/// normalized phone number.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Mode _mode = _Mode.login;
  _Step _step = _Step.details;
  bool _loading = false;
  String? _error;
  String _phone = '';
  int _resendIn = 0;
  Timer? _resendTimer;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: _uzPhonePrefix);
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    _resendTimer?.cancel();
    setState(() {
      _mode = mode;
      _step = _Step.details;
      _error = null;
      _resendIn = 0;
      _codeCtrl.clear();
    });
  }

  /// Loosely accepts "901234567", "998901234567", "+998 90 123 45 67" etc.
  /// — the backend normalizes/validates again regardless, this is just so
  /// the request is worth sending.
  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 9) return '+998$digits';
    if (digits.startsWith('998')) return '+$digits';
    final trimmed = input.trim();
    if (trimmed.startsWith('+')) return trimmed;
    return digits.isEmpty ? '' : '+$digits';
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendIn = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendIn -= 1;
        if (_resendIn <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    if (_mode == _Mode.register && _nameCtrl.text.trim().length < 2) {
      setState(() => _error = t(context, 'wa.auth.fullNameInvalid'));
      return;
    }
    final normalized = _normalizePhone(_phoneCtrl.text);
    if (!RegExp(r'^\+998\d{9}$').hasMatch(normalized)) {
      setState(() => _error = t(context, 'wa.auth.phoneInvalid'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await SessionScope.of(context).requestOtp(normalized);
      _phone = normalized;
      final resendIn = (result['resendInSeconds'] as num?)?.toInt() ?? 60;
      if (mounted) {
        setState(() => _step = _Step.code);
        _startResendTimer(resendIn);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = t(context, 'wa.auth.codeInvalid'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = SessionScope.of(context);
      final signedIn = await session.verifyOtp(phone: _phone, code: code);
      if (!signedIn) {
        if (_mode == _Mode.register) {
          // Brand-new phone number — finish creating the account right away
          // with the F.I.O. already typed on the previous (register) step.
          await session.completeProfile(phone: _phone, name: _nameCtrl.text.trim());
        } else {
          // Login never silently registers — a phone with no account is an
          // error, not an invitation to keep going.
          if (mounted) setState(() => _error = t(context, 'wa.auth.numberNotFound'));
        }
      }
      // signedIn == true: AppSession already notified — RootScreen swaps to ShellScreen on its own.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrimeColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Center(child: PrimeLogo()),
                  const SizedBox(height: 32),
                  if (_step == _Step.code) ...[
                    Center(child: _StepDots(step: _step)),
                    const SizedBox(height: 28),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey((_mode, _step)),
                      child: switch (_step) {
                        _Step.details => _buildDetailsStep(context),
                        _Step.code => _buildCodeStep(context),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep(BuildContext context) {
    final isLogin = _mode == _Mode.login;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t(context, isLogin ? 'wa.auth.login' : 'wa.auth.register'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          t(context, isLogin ? 'wa.auth.loginSubtitle' : 'wa.auth.detailsSubtitle'),
          style: const TextStyle(color: PrimeColors.slate, fontSize: 13),
        ),
        const SizedBox(height: 18),
        if (!isLogin) ...[
          _label(t(context, 'wa.auth.fullName')),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
        ],
        _label(t(context, 'wa.auth.phone')),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          autofocus: isLogin,
          inputFormatters: [_UzPhoneFormatter()],
          decoration: InputDecoration(hintText: t(context, 'wa.auth.phoneHint')),
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _sendCode,
          child: Text(_loading ? t(context, 'wa.auth.sendingCode') : t(context, 'wa.auth.sendCode')),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _loading ? null : () => _switchMode(isLogin ? _Mode.register : _Mode.login),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: PrimeColors.slate),
                children: [
                  TextSpan(text: '${t(context, isLogin ? 'wa.auth.noAccount' : 'wa.auth.haveAccount')} '),
                  TextSpan(
                    text: t(context, isLogin ? 'wa.auth.register' : 'wa.auth.login'),
                    style: const TextStyle(color: PrimeColors.blue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    final subtitle = t(context, 'wa.auth.codeSentToTemplate').replaceAll('{phone}', _maskPhone(_phone));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t(context, 'wa.auth.codeTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: PrimeColors.slate, fontSize: 13)),
        const SizedBox(height: 18),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 6),
          decoration: InputDecoration(counterText: '', hintText: t(context, 'wa.auth.codeHint')),
          onSubmitted: (_) => _verifyCode(),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _loading ? null : _verifyCode,
          child: Text(_loading ? t(context, 'wa.auth.sendingCode') : t(context, 'wa.auth.verify')),
        ),
        const SizedBox(height: 12),
        // Each side is `Expanded` and wraps to 2 lines instead of a single
        // long line — on narrow phones "32 soniyadan keyin qayta yuborish
        // mumkin" is long enough on its own to overflow a plain Row.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft, minimumSize: const Size(0, 32)),
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _step = _Step.details;
                          _error = null;
                          _codeCtrl.clear();
                          _resendTimer?.cancel();
                          _resendIn = 0;
                        }),
                child: Text(t(context, 'wa.auth.changePhone'), style: const TextStyle(fontSize: 12.5), textAlign: TextAlign.left),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // "Qayta yuborish" the whole time, with the countdown ticking
              // down next to it in parentheses (short, so it never
              // overflows) — grey/inert while it runs, then turns into an
              // actual blue underlined link the moment it hits 0.
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerRight, minimumSize: const Size(0, 32)),
                onPressed: (_loading || _resendIn > 0) ? null : _sendCode,
                child: Text(
                  _resendIn > 0 ? '${t(context, 'wa.auth.resend')} (${_resendIn}s)' : t(context, 'wa.auth.resend'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: _resendIn > 0 ? FontWeight.w500 : FontWeight.w700,
                    color: _resendIn > 0 ? PrimeColors.slate : PrimeColors.blue,
                    decoration: _resendIn > 0 ? TextDecoration.none : TextDecoration.underline,
                    decorationColor: PrimeColors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: PrimeColors.slate, fontWeight: FontWeight.w500)),
      );

  Widget _errorText() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(_error!, style: const TextStyle(color: PrimeColors.negative, fontSize: 13)),
      );
}

/// Tiny 2-dot progress indicator (ma'lumotlar → kod), shown only once the
/// code step is reached — the first (details) step has nothing to show
/// progress "against" yet, and the login/register switch link already lives
/// there.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final index = _Step.values.indexOf(step);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _Step.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i <= index ? PrimeColors.blue : PrimeColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}
