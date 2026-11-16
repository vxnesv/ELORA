import 'package:material_ui/material_ui.dart';

class CoresElora {
  const CoresElora({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.border,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color border;
  final Color heroStart;
  final Color heroEnd;

  static const light = CoresElora(
    background: Color(0xFFFCF7F1),
    surface: Color(0xFFFFFDF9),
    surfaceAlt: Color(0xFFF9EDE2),
    text: Color(0xFF3C1B14),
    muted: Color(0xFF80675D),
    accent: Color(0xFFB75217),
    accentSoft: Color(0xFFFFE3C2),
    border: Color(0xFFECDDD1),
    heroStart: Color(0xFF73351E),
    heroEnd: Color(0xFFE88719),
  );

  static const dark = CoresElora(
    background: Color(0xFF14070D),
    surface: Color(0xFF25121B),
    surfaceAlt: Color(0xFF351924),
    text: Color(0xFFFFF1E6),
    muted: Color(0xFFC5A7A4),
    accent: Color(0xFFFFA12E),
    accentSoft: Color(0xFF5D2A17),
    border: Color(0xFF53303A),
    heroStart: Color(0xFF5F1D12),
    heroEnd: Color(0xFFCB5B0D),
  );

  static CoresElora of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class TemaElora {
  static ThemeData get light => _build(CoresElora.light, Brightness.light);
  static ThemeData get dark => _build(CoresElora.dark, Brightness.dark);

  static ThemeData _build(CoresElora colors, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          onPrimary: brightness == Brightness.dark
              ? colors.background
              : Colors.white,
          surface: colors.surface,
          onSurface: colors.text,
          outline: colors.border,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.12,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          height: 1.16,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: colors.text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: colors.text),
        bodySmall: TextStyle(fontSize: 12, height: 1.35, color: colors.muted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      dividerColor: colors.border,
    );
  }
}
