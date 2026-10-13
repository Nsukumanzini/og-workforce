import 'package:flutter/material.dart';

class WorkforceTheme {
  static ThemeData light() => _theme(Brightness.light, const Color(0xFF175CD3), const Color(0xFFF8FAFC));
  static ThemeData dark() => _theme(Brightness.dark, const Color(0xFF84ADFF), const Color(0xFF101828));
  static ThemeData _theme(Brightness brightness, Color primary, Color scaffold) => ThemeData(
    useMaterial3: true, brightness: brightness, colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: brightness),
    scaffoldBackgroundColor: scaffold,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
    cardTheme: const CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
  );
}
