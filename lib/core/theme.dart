import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette — shared visual language with the web card
/// (deep ink / warm maroon foil, restrained accent blue).
class AppColors {
  static const ink950 = Color(0xFF0B0B0C);
  static const ink900 = Color(0xFF121214);
  static const ink800 = Color(0xFF1B1B1F);
  static const ink700 = Color(0xFF26262B);
  static const inkMuted = Color(0xFF6B6B72);

  static const brand900 = Color(0xFF2B0E09);
  static const brand700 = Color(0xFF4A1811);
  static const brand500 = Color(0xFF8C2F22);
  static const brand300 = Color(0xFFD98B7E);

  static const accent = Color(0xFF2F6FED);
  static const surface = Color(0xFFF6F4F1);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const border = Color(0x1A121214);

  static const success = Color(0xFF1E8E5A);
}

class AppRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 28.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  final display = GoogleFonts.fraunces();
  final body = GoogleFonts.inter();

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.ink950,
      secondary: AppColors.brand500,
      surface: AppColors.surfaceCard,
      error: const Color(0xFFB3261E),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink900, displayColor: AppColors.ink900)
        .copyWith(
          headlineMedium: display.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
          headlineSmall: display.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: body.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
          bodyMedium: body.copyWith(fontSize: 14, color: AppColors.inkMuted),
          labelLarge: body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink900,
      titleTextStyle: display.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.ink900,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink950,
        foregroundColor: Colors.white,
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
        foregroundColor: AppColors.ink900,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: const BorderSide(color: AppColors.ink900, width: 1.4),
      ),
      labelStyle: body.copyWith(color: AppColors.inkMuted, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.ink950,
      unselectedItemColor: AppColors.inkMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
