import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

/// Design tokens matching the "Seventh" streetwear reference site —
/// warm paper background, ink-black type, wood/olive/rust accents,
/// condensed display type paired with a clean grotesque body face.
class AppColors {
  static const paper = Color(0xFFF2EDE4);
  static const paperDim = Color(0xFFE8E1D3);
  static const ink = Color(0xFF15130F);
  static const inkSoft = Color(0xFF3B362C);
  static const wood = Color(0xFF2B2016);
  static const woodDeep = Color(0xFF1A130C);
  static const olive = Color(0xFF6B6F47);
  static const rust = Color(0xFF8A5A3A);
  static const line = Color(0x2415130F);

  // Back-compat aliases used across existing screens (Admin dashboard etc.)
  static const primary = ink;
  static const accent = rust;
  static const background = paper;
  static const surfaceDark = woodDeep;
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFB8863B);
}

class AppRadii {
  static const card = 4.0;
  static const button = 2.0;
  static const chip = 20.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 900);
}

/// Condensed display face for headlines — mirrors the site's Anton usage.
TextStyle displayFont({double? fontSize, Color? color, double? letterSpacing}) =>
    GoogleFonts.anton(
      fontSize: fontSize,
      color: color ?? AppColors.ink,
      letterSpacing: letterSpacing ?? 0.5,
      height: 0.95,
    );

/// Body/UI face — mirrors the site's Archivo usage.
TextStyle bodyFont({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing}) =>
    GoogleFonts.archivo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );

TextStyle eyebrowFont({Color? color}) => GoogleFonts.archivo(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.2,
      color: color ?? AppColors.inkSoft,
    );

ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.ink,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.paper,
  );
  return base.copyWith(
    textTheme: GoogleFonts.archivoTextTheme(base.textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.paperDim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        textStyle: GoogleFonts.archivo(fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.archivo(fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      elevation: 0,
      foregroundColor: AppColors.ink,
      centerTitle: true,
      titleTextStyle: GoogleFonts.anton(fontSize: 20, color: AppColors.ink, letterSpacing: 0.5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.paper,
      indicatorColor: AppColors.ink.withOpacity(0.08),
      surfaceTintColor: Colors.transparent,
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.olive,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.woodDeep,
  );
  return base.copyWith(
    textTheme: GoogleFonts.archivoTextTheme(base.textTheme),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.wood,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
    ),
  );
}
