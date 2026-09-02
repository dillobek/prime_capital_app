import 'package:flutter/material.dart';

/// Official Prime Capital wordmark (assets/images/prime_logo.png, ~397×176,
/// white background). `compact` sizes it for the app bar; the full size is
/// used on the auth screen.
class PrimeLogo extends StatelessWidget {
  const PrimeLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/prime_logo.png',
      height: compact ? 28 : 44,
      fit: BoxFit.contain,
    );
  }
}
