import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? dynamicColorScheme) {
    final scheme =
        dynamicColorScheme ?? ColorScheme.fromSeed(seedColor: Colors.blue);
    final tone90 = HSLColor.fromColor(
      scheme.primary,
    ).withLightness(0.9).toColor();
    final tone97 = HSLColor.fromColor(
      scheme.primary,
    ).withLightness(0.98).toColor();

    final modifiedScheme = scheme.copyWith(
      surface: tone97,
      surfaceContainerHighest: tone97,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: modifiedScheme,
      scaffoldBackgroundColor: tone90,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: modifiedScheme.onSurface,
        displayColor: modifiedScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tone90,
        foregroundColor: modifiedScheme.onSurface,
        centerTitle: false,
      ),
    );
  }

  static ThemeData darkTheme(ColorScheme? dynamicColorScheme) {
    final scheme =
        dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );
    final tone5 = HSLColor.fromColor(
      scheme.primary,
    ).withLightness(0.062).toColor();

    final modifiedScheme = scheme.copyWith(surfaceContainerHighest: tone5);

    return ThemeData(
      useMaterial3: true,
      colorScheme: modifiedScheme,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
    );
  }
}
