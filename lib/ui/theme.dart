import 'package:flutter/material.dart';

/// Colours sampled from the Forgelink logo (assets/branding/app-icon.png).
abstract final class Brand {
  static const orange = Color(0xFFFCA030);
  static const orangeDeep = Color(0xFFF05A18);
  static const green = Color(0xFF3CE05A);
  static const sky = Color(0xFF60C4FC);
  static const night = Color(0xFF221F2D); // logo background
}

/// Semantic status colours, readable in both themes.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color ok;
  final Color warn;
  final Color error;
  final Color neutral;

  const StatusColors({
    required this.ok,
    required this.warn,
    required this.error,
    required this.neutral,
  });

  /// Falls back to colours derived from the scheme when the app theme isn't
  /// installed (e.g. widget tests).
  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.extension<StatusColors>() ??
        StatusColors(
          ok: scheme.tertiary,
          warn: scheme.primary,
          error: scheme.error,
          neutral: scheme.outline,
        );
  }

  @override
  StatusColors copyWith({Color? ok, Color? warn, Color? error, Color? neutral}) =>
      StatusColors(
        ok: ok ?? this.ok,
        warn: warn ?? this.warn,
        error: error ?? this.error,
        neutral: neutral ?? this.neutral,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      error: Color.lerp(error, other.error, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData dark() => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: Brand.orange,
          onPrimary: Brand.night,
          primaryContainer: Color(0xFF4A3420),
          onPrimaryContainer: Color(0xFFFFDDB8),
          secondary: Brand.sky,
          onSecondary: Brand.night,
          secondaryContainer: Color(0xFF1F3A4A),
          onSecondaryContainer: Color(0xFFCDEBFF),
          tertiary: Brand.green,
          onTertiary: Brand.night,
          error: Color(0xFFFF7A6B),
          onError: Brand.night,
          errorContainer: Color(0xFF5A1F1A),
          onErrorContainer: Color(0xFFFFDAD5),
          surface: Color(0xFF1A1823),
          onSurface: Color(0xFFEDEAF3),
          onSurfaceVariant: Color(0xFFB4AFC2),
          surfaceContainerLowest: Color(0xFF15131C),
          surfaceContainerLow: Brand.night,
          surfaceContainer: Color(0xFF282534),
          surfaceContainerHigh: Color(0xFF312D3E),
          surfaceContainerHighest: Color(0xFF3A3548),
          outline: Color(0xFF6E687D),
          outlineVariant: Color(0xFF3A3548),
        ),
        const StatusColors(
          ok: Brand.green,
          warn: Brand.orange,
          error: Color(0xFFFF7A6B),
          neutral: Color(0xFF8E889C),
        ),
      );

  static ThemeData light() => _build(
        const ColorScheme(
          brightness: Brightness.light,
          // Deeper orange keeps text/icons on white above 3:1.
          primary: Color(0xFFD9670A),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFFFE2C4),
          onPrimaryContainer: Color(0xFF3D1E00),
          secondary: Color(0xFF0B6E99),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFD6EEFA),
          onSecondaryContainer: Color(0xFF00283A),
          tertiary: Color(0xFF15873A),
          onTertiary: Colors.white,
          error: Color(0xFFC0392B),
          onError: Colors.white,
          errorContainer: Color(0xFFFDE3DF),
          onErrorContainer: Color(0xFF5A130C),
          surface: Color(0xFFFAF7F3),
          onSurface: Color(0xFF1E1B26),
          onSurfaceVariant: Color(0xFF5C5768),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainer: Color(0xFFF3EEE8),
          surfaceContainerHigh: Color(0xFFECE6DF),
          surfaceContainerHighest: Color(0xFFE5DED6),
          outline: Color(0xFF8C8696),
          outlineVariant: Color(0xFFE6E0D8),
        ),
        const StatusColors(
          ok: Color(0xFF15873A),
          warn: Color(0xFFD9670A),
          error: Color(0xFFC0392B),
          neutral: Color(0xFF8C8696),
        ),
      );

  static ThemeData _build(ColorScheme scheme, StatusColors status) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;
    final shape12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [status],
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: shape12,
          textStyle: text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: shape12,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: shape12,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: shape12,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape12,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
