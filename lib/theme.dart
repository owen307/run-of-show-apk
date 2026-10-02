import 'package:flutter/material.dart';

const boothBg = Color(0xFF090B0E);
const boothSurface = Color(0xFF14181E);
const boothCard = Color(0xFF1C232D);
const boothLine = Color(0xFF323A48);
const boothAmber = Color(0xFFF5B942);
const boothGreen = Color(0xFF3DDC97);
const boothRed = Color(0xFFFF5C7A);
const boothText = Color(0xFFF4F1EA);
const boothMuted = Color(0xFFA7B0BE);
const boothBlue = Color(0xFF8EB4FF);

const railBreakpoint = 900.0;

ThemeData buildBoothTheme() {
  final scheme = ColorScheme.dark(
    primary: boothAmber,
    onPrimary: const Color(0xFF1A1203),
    secondary: boothGreen,
    onSecondary: const Color(0xFF04150E),
    surface: boothSurface,
    onSurface: boothText,
    error: boothRed,
    onError: Colors.white,
    outline: boothLine,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: boothBg,
    fontFamily: 'Barlow',
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Barlow',
      bodyColor: boothText,
      displayColor: boothText,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: boothSurface,
      indicatorColor: boothAmber.withValues(alpha: 0.18),
      height: 64,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Barlow',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: boothSurface,
      indicatorColor: Color(0x33F5B942),
      selectedIconTheme: IconThemeData(color: boothAmber),
      unselectedIconTheme: IconThemeData(color: boothMuted),
      selectedLabelTextStyle: TextStyle(
        color: boothAmber,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(color: boothMuted, fontSize: 12),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: boothSurface),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: boothCard,
      contentTextStyle: TextStyle(color: boothText, fontSize: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: boothCard,
      labelStyle: const TextStyle(color: boothMuted),
      hintStyle: const TextStyle(color: boothMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: boothLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: boothLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: boothAmber, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        foregroundColor: boothText,
        side: const BorderSide(color: boothLine),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

TextStyle clockStyle(double size, Color color) {
  return TextStyle(
    fontFamily: 'JetBrainsMono',
    fontWeight: FontWeight.w700,
    fontSize: size,
    height: 0.9,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

TextStyle condensed(
  double size, {
  FontWeight weight = FontWeight.w600,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'BarlowCondensed',
    fontSize: size,
    fontWeight: weight,
    height: 1.05,
    color: color ?? boothText,
  );
}

Color heroColor(String label, int remaining) {
  if (label == 'HOLD') return boothAmber;
  if (label == 'OVER' || label == 'LATE' || remaining < 0) return boothRed;
  if (label == 'COMPLETE' || label == 'EMPTY') return boothMuted;
  if (remaining <= 10 && label == 'REMAINING') return boothRed;
  if (remaining <= 60 && label == 'REMAINING') return boothAmber;
  return boothText;
}
