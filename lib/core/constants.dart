import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Backend base URL. Overridable at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://api.primecapital.uz/api/v1
/// Defaults to the production API so a plain `flutter run` on a phone works
/// out of the box; use 10.0.2.2 for the Android emulator talking to a
/// backend running on your own machine, or your machine's LAN IP on a real
/// device (localhost/127.0.0.1 inside the app always means the phone itself).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.primecapital.uz/api/v1',
);

/// Brand palette. `blue`/`cyan` match the logo and Webapp's globals.css;
/// everything else (background/card/border/fieldFill/shadow) is tuned for a
/// soft, minimal-premium look (Revolut/Wise-style light theme) — a slightly
/// warm off-white page, cards on pure white with a soft diffused shadow
/// instead of a hard border, and a light blue-grey field fill.
class PrimeColors {
  PrimeColors._();
  static const Color blue = Color(0xFF068CEF);
  static const Color blueDeep = Color(0xFF0468C4);
  static const Color cyan = Color(0xFF17C3B2);
  static const Color ink = Color(0xFF0F172A);

  /// The exact brand navy from the logo/brand kit (#131254) — distinct from
  /// [ink], which is the app's body-text color. Used where the true brand
  /// dark is needed: the splash/loading screen and the app-icon background,
  /// matching the native app icon 1:1.
  static const Color navy = Color(0xFF131254);
  static const Color slate = Color(0xFF64748B);
  static const Color background = Color(0xFFF6F7FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEBEEF3);
  static const Color fieldFill = Color(0xFFF1F4F9);
  static const Color negative = Color(0xFFE0432B);
  static const Color positive = Color(0xFF17A24A);

  /// Soft, brand-tinted shadow (instead of pure black) — the single biggest
  /// lever for making flat cards read as "premium" rather than "flat/plain".
  static Color get shadow => ink.withOpacity(0.07);

  static List<BoxShadow> softShadow({double blur = 28, double y = 12, double opacity = 0.07}) => [
        BoxShadow(color: ink.withOpacity(opacity), blurRadius: blur, offset: Offset(0, y)),
      ];
}

ThemeData buildPrimeTheme() {
  final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: PrimeColors.blue,
    scaffoldBackgroundColor: PrimeColors.background,
    textTheme: baseTextTheme.apply(bodyColor: PrimeColors.ink, displayColor: PrimeColors.ink),
    splashColor: PrimeColors.blue.withOpacity(0.06),
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: PrimeColors.background,
      foregroundColor: PrimeColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: PrimeColors.ink),
    ),
    cardTheme: CardTheme(
      color: PrimeColors.card,
      elevation: 3,
      shadowColor: PrimeColors.shadow,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PrimeColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: PrimeColors.blue.withOpacity(0.35),
        disabledForegroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PrimeColors.ink,
        side: const BorderSide(color: PrimeColors.border, width: 1.3),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PrimeColors.blue,
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PrimeColors.fieldFill,
      hintStyle: GoogleFonts.plusJakartaSans(color: PrimeColors.slate, fontWeight: FontWeight.w500, fontSize: 14.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PrimeColors.blue, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: PrimeColors.border, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: PrimeColors.slate,
      textColor: PrimeColors.ink,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: PrimeColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: PrimeColors.blue.withOpacity(0.12),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? PrimeColors.blue : PrimeColors.slate,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return IconThemeData(color: selected ? PrimeColors.blue : PrimeColors.slate, size: 24);
      }),
    ),
  );
}
