import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/constants.dart';
import 'core/i18n.dart';
import 'core/session.dart';
import 'screens/root_screen.dart';

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
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPrimeTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
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
