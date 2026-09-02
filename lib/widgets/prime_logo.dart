import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official Prime Capital logo, extracted at full vector quality (SVG,
/// transparent background) from the brand kit — sharp at any size/density,
/// never the soft/blurry edges a raster export would have.
///
/// `compact` renders the horizontal app-bar lockup (mark + wordmark on one
/// line); the full size renders the stacked hero lockup (mark above
/// "Prime Capital" + the "Secure. Grow. Prosper." tagline) used on the auth
/// screen. Both use the navy wordmark, tuned for the app's light
/// backgrounds — see [PrimeLogoLight] for the white-wordmark variant used
/// on dark/navy surfaces, and [PrimeMark] for the icon alone.
class PrimeLogo extends StatelessWidget {
  const PrimeLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      compact ? 'assets/images/logo/lockup_horizontal.svg' : 'assets/images/logo/lockup_full.svg',
      height: compact ? 30 : 150,
    );
    // FittedBox guards against the AppBar's title slot being narrower than
    // the wordmark on small phones — it scales the whole lockup down rather
    // than letting it clip or overflow.
    return compact ? FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: svg) : svg;
  }
}

/// White-wordmark variant of the lockup, for navy/dark backgrounds — the
/// splash/loading screen and any future dark hero section.
class PrimeLogoLight extends StatelessWidget {
  const PrimeLogoLight({super.key, this.compact = false, this.height});

  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      compact ? 'assets/images/logo/lockup_horizontal_light.svg' : 'assets/images/logo/lockup_full_light.svg',
      height: height ?? (compact ? 30 : 150),
    );
  }
}

/// Just the brand mark (no wordmark) — for tight spaces such as a loading
/// badge or a favicon-style chip.
class PrimeMark extends StatelessWidget {
  const PrimeMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/images/logo/mark.svg', height: size);
  }
}
