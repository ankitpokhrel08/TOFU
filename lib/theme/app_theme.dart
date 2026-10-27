import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const ink = Color(0xFF2B0F3F);
  static const inkDeep = Color(0xFF1B0A28);
  static const cream = Color(0xFFFFF7FB);

  static const pink = Color(0xFFFF3D9A);
  static const pinkDark = Color(0xFFC21C72);
  static const pinkSoft = Color(0xFFFF7DBE);
  static const pinkTint = Color(0xFFFFE6F2);

  static const purple = Color(0xFF7B2CF0);
  static const purpleDark = Color(0xFF5216B0);
  static const purpleTint = Color(0xFFEDE0FF);
  static const purpleMuted = Color(0xFFD9C2FF);

  static const lime = Color(0xFFB8F03A);
  static const limeDark = Color(0xFF7FAE1C);
  static const orange = Color(0xFFFF8A1F);
  static const orangeDark = Color(0xFFC8620B);
  static const yellow = Color(0xFFFFC93D);
  static const green = Color(0xFF22C493);
  static const red = Color(0xFFFF4D6A);

  static const line = Color(0xFFEBDDF2);
  static const lavender = Color(0xFFF3E8F7);
  static const track = Color(0xFFF0E3F5);
  static const disabled = Color(0xFFE2D0EC);
  static const disabledShadow = Color(0xFFCDB8DA);

  static const textMuted = Color(0xFF7A6689);
  static const textFaint = Color(0xFF9A86A8);
  static const textGhost = Color(0xFFB9A8C6);
  static const textOnDark = Color(0xFFD9C7E6);
}

/// Display face (Baloo 2, always extra-bold in the design).
TextStyle baloo(double size, {double? height, Color? color, double? letterSpacing}) =>
    GoogleFonts.baloo2(
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );

/// Body face (Nunito).
TextStyle nunito(
  double size, {
  FontWeight weight = FontWeight.w800,
  double? height,
  Color? color,
  double? letterSpacing,
}) => GoogleFonts.nunito(
  fontSize: size,
  fontWeight: weight,
  height: height,
  color: color,
  letterSpacing: letterSpacing,
);

/// A flat, unblurred "3D" drop shadow used throughout the design.
List<BoxShadow> hardShadow(Color color, [double dy = 3]) => [
  BoxShadow(color: color, offset: Offset(0, dy)),
];

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.cream,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink, surface: AppColors.cream),
  fontFamily: GoogleFonts.nunito().fontFamily,
  splashFactory: NoSplash.splashFactory,
);
