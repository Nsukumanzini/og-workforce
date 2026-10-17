import 'package:flutter/material.dart';

/// OG Workforce's shared visual language.
///
/// A warm, quiet canvas and deep evergreen accents make operational screens
/// feel focused without losing the friendly character of the product.
class WorkforceTheme {
  static const ink = Color(0xFF182720);
  static const mutedInk = Color(0xFF66736C);
  static const forest = Color(0xFF176B52);
  static const forestDeep = Color(0xFF0F4D3B);
  static const mint = Color(0xFFE5F2EB);
  static const canvas = Color(0xFFF5F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3E9E2);
  static const amber = Color(0xFFE2A33A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
      primary: forest,
      onPrimary: Colors.white,
      secondary: Color(0xFFB4D6C3),
      onSecondary: forestDeep,
      surface: surface,
      onSurface: ink,
      error: Color(0xFFB5473C),
      outline: line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
    );
    final text = base.textTheme;

    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: text.displaySmall?.copyWith(color: ink, fontWeight: FontWeight.w700, letterSpacing: -1.4),
        headlineLarge: text.headlineLarge?.copyWith(color: ink, fontWeight: FontWeight.w700, letterSpacing: -1.1),
        headlineMedium: text.headlineMedium?.copyWith(color: ink, fontWeight: FontWeight.w700, letterSpacing: -.7),
        headlineSmall: text.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w700, letterSpacing: -.4),
        titleLarge: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w700, letterSpacing: -.2),
        titleMedium: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(color: ink, height: 1.45),
        bodyMedium: text.bodyMedium?.copyWith(color: mutedInk, height: 1.45),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -.3),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: line)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: mutedInk, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF98A39C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: forest, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB5473C))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: forest.withValues(alpha: .45),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestDeep,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: forest, textStyle: const TextStyle(fontWeight: FontWeight.w600))),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: forest, linearTrackColor: mint),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: mint,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(color: states.contains(WidgetState.selected) ? forestDeep : mutedInk, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  static ThemeData dark() {
    const darkCanvas = Color(0xFF111A16);
    const darkSurface = Color(0xFF1A2520);
    const darkLine = Color(0xFF2B3932);
    const darkText = Color(0xFFE7EEE9);
    const darkMuted = Color(0xFFACB9B1);
    const darkGreen = Color(0xFF67C49A);
    final scheme = ColorScheme.fromSeed(
      seedColor: darkGreen,
      brightness: Brightness.dark,
      primary: darkGreen,
      onPrimary: const Color(0xFF092A1D),
      secondary: const Color(0xFF294C3A),
      onSecondary: darkText,
      surface: darkSurface,
      onSurface: darkText,
      outline: darkLine,
    );
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: scheme, scaffoldBackgroundColor: darkCanvas);
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: darkText, displayColor: darkText),
      appBarTheme: const AppBarTheme(backgroundColor: darkCanvas, foregroundColor: darkText, surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(color: darkSurface, surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)), side: BorderSide(color: darkLine))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: darkMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: darkLine)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: darkLine)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: darkGreen, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: darkGreen, foregroundColor: const Color(0xFF092A1D), minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: darkText, minimumSize: const Size(48, 50), side: const BorderSide(color: darkLine), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: darkGreen)),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: darkSurface, contentTextStyle: const TextStyle(color: darkText), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      dividerTheme: const DividerThemeData(color: darkLine),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: darkGreen, linearTrackColor: darkLine),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: darkSurface, indicatorColor: Color(0xFF294C3A), elevation: 0),
    );
  }
}
