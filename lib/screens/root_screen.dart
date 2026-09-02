import 'package:flutter/material.dart';

import '../core/session.dart';
import 'auth_screen.dart';
import 'shell_screen.dart';

/// Switches between the splash spinner, the auth screen, and the signed-in
/// app shell, based on `AppSession` — same three states as Webapp's
/// `WebApp()` component (`checking` / `!profile` / signed-in).
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (session.checking) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!session.isSignedIn) {
          return const AuthScreen();
        }
        return const ShellScreen();
      },
    );
  }
}
