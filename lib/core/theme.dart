import 'package:flutter/material.dart';

/// Text styles for the two bundled font families (see pubspec.yaml's
/// `fonts:` section / assets/fonts/) — a thin drop-in replacement for the
/// GoogleFonts.manrope()/inter() helpers that used to fetch these at
/// runtime.
TextStyle _manrope() => const TextStyle(fontFamily: 'Manrope');
TextStyle _inter() => const TextStyle(fontFamily: 'Inter');

/// Monochrome professional palette — pure black / white / gray.
/// No brand colour accents; hierarchy comes from weight, size and
/// opacity of black/white rather than hue.
class AppColors {
  // Core neutrals
  static const black = Color(0xFF0A0A0A);
  static const ink900 = Color(0xFF121212);
  static const ink800 = Color(0xFF1E1E1E);
  static const ink700 = Color(0xFF2C2C2E);
  static const gray600 = Color(0xFF4B4B4F);
  static const gray500 = Color(0xFF6E6E73);
  static const gray400 = Color(0xFF9A9AA0);
  static const gray300 = Color(0xFFC7C7CC);
  static const gray200 = Color(0xFFE2E2E5);
  static const gray100 = Color(0xFFF0F0F1);
  static const white = Color(0xFFFFFFFF);

  // Semantic aliases (kept minimal — this is a black & white app)
  static const surface = Color(0xFFFAFAFA);
  static const surfaceCard = white;
  static const border = Color(0xFFE0E0E2);
  static const inkMuted = gray500;

  // Status colours are the only non-neutral hues, used sparingly
  // (success/error states) so the rest of the app can stay monochrome.
  static const success = Color(0xFF1A1A1A);
  static const error = Color(0xFFB00020);
  static const warning = Color(0xFF8A6D00);

  // Legacy aliases used elsewhere in the codebase.
  static const ink950 = black;
  static const brand900 = black;
  static const brand700 = ink800;
  static const brand500 = ink700;
  static const brand300 = gray400;
  static const accent = black;
}

class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 26.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  final display = _manrope();
  final body = _inter();

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.light,
      primary: AppColors.black,
      onPrimary: AppColors.white,
      secondary: AppColors.ink800,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.black,
      error: AppColors.error,
    ),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.black, displayColor: AppColors.black)
        .copyWith(
          headlineMedium: display.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.4,
          ),
          headlineSmall: display.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
          titleSmall: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          bodyMedium: body.copyWith(fontSize: 14, color: AppColors.gray500),
          bodySmall: body.copyWith(fontSize: 12, color: AppColors.gray500),
          labelLarge: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.black,
      titleTextStyle: display.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: AppColors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.gray300,
        disabledForegroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        side: const BorderSide(color: AppColors.black, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.black,
        textStyle: body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.black),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.gray100,
      selectedColor: AppColors.black,
      labelStyle: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.black),
      secondaryLabelStyle: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.black : AppColors.gray300,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.gray100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: const BorderSide(color: AppColors.black, width: 1.4),
      ),
      labelStyle: body.copyWith(color: AppColors.gray500, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.black,
      unselectedItemColor: AppColors.gray400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.black,
      contentTextStyle: body.copyWith(color: AppColors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
  );
}

/// Dark mode — same monochrome language, inverted. Used by Settings ▸
/// Appearance.
ThemeData buildAppDarkTheme() {
  final light = buildAppTheme();
  final display = _manrope();
  final body = _inter();

  return light.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: light.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.gray300,
      surface: AppColors.ink900,
      onSurface: AppColors.white,
    ),
    textTheme: light.textTheme.apply(bodyColor: AppColors.white, displayColor: AppColors.white),
    appBarTheme: light.appBarTheme.copyWith(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      titleTextStyle: display.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    iconTheme: const IconThemeData(color: AppColors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.white, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
    ),
    inputDecorationTheme: light.inputDecorationTheme.copyWith(
      fillColor: AppColors.ink800,
      labelStyle: body.copyWith(color: AppColors.gray400, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.ink700, thickness: 1, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.black,
      selectedItemColor: AppColors.white,
      unselectedItemColor: AppColors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
    ),
    cardColor: AppColors.ink900,
  );
}
