import 'package:flutter/material.dart';

class BazinoTheme {
  static const seed = Color(0xFF57D6FF);
  static const night = Color(0xFF0B0E1A);
  static const card = Color(0xFF131A2E);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: night,
      ),
      scaffoldBackgroundColor: night,
      cardTheme: const CardTheme(color: card),
      appBarTheme: const AppBarTheme(backgroundColor: night, elevation: 0),
    );
  }

  static Color readinessColor(String r) => switch (r) {
        'green' => const Color(0xFF9DFF70),
        'yellow' => const Color(0xFFFFD166),
        _ => const Color(0xFFFF5C7A),
      };

  static String readinessFa(String r) => switch (r) {
        'green' => 'آمادهٔ امتحان فصل ✔',
        'yellow' => 'در حال رشد — ادامه بازی',
        _ => 'ناامن — بازی بیشتر در این درس',
      };
}
