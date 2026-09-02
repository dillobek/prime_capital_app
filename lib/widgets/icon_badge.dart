import 'package:flutter/material.dart';

/// Soft, tinted rounded-square icon badge — icon color on a light wash of
/// the same color. Used on white/card backgrounds (quick actions, balance
/// cards, list rows) instead of plain bordered squares or bare icons; this
/// one visual trick (color-matched icon chips) is a big part of what makes
/// fintech apps like Revolut/Wise read as "premium" rather than generic.
class PrimeIconBadge extends StatelessWidget {
  const PrimeIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.5),
    );
  }
}

/// Solid-fill variant — white icon on a solid color square, matching Apple's
/// own Settings app rows. Used in the Profile (iOS-style) screen.
class PrimeIconBadgeSolid extends StatelessWidget {
  const PrimeIconBadgeSolid({super.key, required this.icon, required this.color, this.size = 29});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(icon, color: Colors.white, size: size * 0.56),
    );
  }
}
