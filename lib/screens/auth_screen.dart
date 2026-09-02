import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../widgets/prime_logo.dart';

enum _Step { phone, code, name }

/// Phone + SMS-OTP sign-in (see Backend/src/otp): enter phone -> enter the
/// 6-digit code -> (only for a brand-new phone) enter a name to finish
/// creating the account. Also the way a user who originally registered
/// through the Telegram bot logs in outside Telegram, since both sides
/// match on the same normalized phone number.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Step _step = _Step.phone;
  bool _loading = false;
  String? _error;
  String _phone = '';
  int _resendIn = 0;
  Timer? _resendTimer;

  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
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
      final signedIn = await SessionScope.of(context).verifyOtp(phone: _phone, code: code);
      if (!signedIn && mounted) setState(() => _step = _Step.name);
      // signedIn == true: AppSession already notified — RootScreen swaps to ShellScreen on its own.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeProfile() async {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = t(context, 'wa.auth.fullName'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).completeProfile(phone: _phone, name: _nameCtrl.text.trim());
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
                  Center(child: _StepDots(step: _step)),
                  const SizedBox(height: 28),
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
                      key: ValueKey(_step),
                      child: switch (_step) {
                        _Step.phone => _buildPhoneStep(context),
                        _Step.code => _buildCodeStep(context),
                        _Step.name => _buildNameStep(context),
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

  Widget _buildPhoneStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(t(context, 'wa.auth.phone')),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(hintText: t(context, 'wa.auth.phoneHint')),
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _sendCode,
          child: Text(_loading ? t(context, 'wa.auth.sendingCode') : t(context, 'wa.auth.sendCode')),
        ),
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t(context, 'wa.auth.codeTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('${t(context, 'wa.auth.codeSentTo')} $_phone', style: const TextStyle(color: PrimeColors.slate, fontSize: 13)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _step = _Step.phone;
                        _error = null;
                        _codeCtrl.clear();
                        _resendTimer?.cancel();
                        _resendIn = 0;
                      }),
              child: Text(t(context, 'wa.auth.changePhone')),
            ),
            TextButton(
              onPressed: (_loading || _resendIn > 0) ? null : _sendCode,
              child: Text(_resendIn > 0 ? '$_resendIn ${t(context, 'wa.auth.resendIn')}' : t(context, 'wa.auth.resend')),
            ),
          ],
        ),
        if (_error != null) _errorText(),
      ],
    );
  }

  Widget _buildNameStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t(context, 'wa.auth.nameTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text(t(context, 'wa.auth.nameSubtitle'), style: const TextStyle(color: PrimeColors.slate, fontSize: 13)),
        const SizedBox(height: 18),
        _label(t(context, 'wa.auth.fullName')),
        TextField(controller: _nameCtrl, autofocus: true, onSubmitted: (_) => _completeProfile()),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _completeProfile,
          child: Text(_loading ? t(context, 'wa.auth.sendingCode') : t(context, 'wa.auth.continueBtn')),
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

/// Tiny 3-dot progress indicator (telefon → kod → ism) — no label text
/// needed, just gives the user a sense of "qayerdaman, nechta qadam qoldi"
/// during onboarding, which reads as both simpler and more polished.
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
