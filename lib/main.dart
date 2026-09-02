import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/constants.dart';
import 'core/i18n.dart';
import 'core/session.dart';
import 'screens/root_screen.dart';
import 'widgets/prime_logo.dart';

void main() {
  runApp(const PrimeCapitalApp());
}

class PrimeCapitalApp extends StatefulWidget {
  const PrimeCapitalApp({super.key});

  @override
  State<PrimeCapitalApp> createState() => _PrimeCapitalAppState();
}

class _PrimeCapitalAppState extends State<PrimeCapitalApp> {
  late final LangController _lang = LangController();
  late final AppSession _session = AppSession(ApiClient(baseUrl: kApiBaseUrl));
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _lang.restore();
    await _session.bootstrap();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Mirrors the native splash screen (navy background, brand mark) — see
      // `flutter_native_splash` config in pubspec.yaml — so there is no
      // color/logo flash when native splash hands off to this first Flutter
      // frame while `_bootstrap()` restores the language/session.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPrimeTheme(),
        home: const Scaffold(
          backgroundColor: PrimeColors.navy,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimeLogoLight(height: 130),
                SizedBox(height: 40),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return LangScope(
      controller: _lang,
      child: AnimatedBuilder(
        animation: _lang,
        builder: (context, _) {
          return SessionScope(
            session: _session,
            child: MaterialApp(
              title: 'Prime Capital',
              debugShowCheckedModeBanner: false,
              theme: buildPrimeTheme(),
              builder: (context, child) => Directionality(
                textDirection: _lang.locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              ),
              home: const RootScreen(),
            ),
          );
        },
      ),
    );
  }
}
