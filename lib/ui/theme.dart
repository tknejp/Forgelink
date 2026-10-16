import 'package:flutter/material.dart';

/// Design tokens from the Forgelink design handoff (`Forgelink App.dc.html`),
/// one set per brightness. Widgets read them via [Palette.of].
@immutable
class Palette extends ThemeExtension<Palette> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color text;
  final Color muted;
  final Color faint;
  final Color accent;

  /// Accent for text and icons on surfaces (darker than [accent] in light).
  final Color accentText;

  /// Text and icons on an [accent] fill.
  final Color accentInk;
  final Color accentSoft;
  final Color ok;
  final Color okBg;
  final Color warn;
  final Color warnBg;
  final Color err;
  final Color errBg;

  /// Text on an [err] fill.
  final Color errInk;
  final Color scrim;

  const Palette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentText,
    required this.accentInk,
    required this.accentSoft,
    required this.ok,
    required this.okBg,
    required this.warn,
    required this.warnBg,
    required this.err,
    required this.errBg,
    required this.errInk,
    required this.scrim,
  });

  static const dark = Palette(
    bg: Color(0xFF16151B),
    surface: Color(0xFF201E27),
    surface2: Color(0xFF2A2833),
    line: Color(0xFF34313D),
    text: Color(0xFFF2F0F6),
    muted: Color(0xFFAEABB8),
    faint: Color(0xFF6F6C7A),
    accent: Color(0xFFFFA230),
    accentText: Color(0xFFFFAB45),
    accentInk: Color(0xFF2A1700),
    accentSoft: Color(0xFF3A2A17),
    ok: Color(0xFF4CD97A),
    okBg: Color(0xFF1B3425),
    warn: Color(0xFFF5B84A),
    warnBg: Color(0xFF3A3020),
    err: Color(0xFFFF7F75),
    errBg: Color(0xFF3D2124),
    errInk: Color(0xFF2B0F0D),
    scrim: Color(0x99000000),
  );

  static const light = Palette(
    bg: Color(0xFFF5F4F0),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEECE7),
    line: Color(0xFFE2DFD8),
    text: Color(0xFF1C1B21),
    muted: Color(0xFF5D5A65),
    faint: Color(0xFFA19EA8),
    accent: Color(0xFFF7961F),
    accentText: Color(0xFFB4600A),
    accentInk: Color(0xFF2A1700),
    accentSoft: Color(0xFFFDE9CF),
    ok: Color(0xFF1D8F45),
    okBg: Color(0xFFDFF2E5),
    warn: Color(0xFF9A6200),
    warnBg: Color(0xFFFBEFD6),
    err: Color(0xFFC83A32),
    errBg: Color(0xFFFBE3E1),
    errInk: Color(0xFFFFFFFF),
    scrim: Color(0x6614121A),
  );

  /// Falls back to the light/dark set matching the theme when the app theme
  /// isn't installed (e.g. widget tests with a bare MaterialApp).
  static Palette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<Palette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      line: l(line, other.line),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      accentInk: l(accentInk, other.accentInk),
      accentSoft: l(accentSoft, other.accentSoft),
      ok: l(ok, other.ok),
      okBg: l(okBg, other.okBg),
      warn: l(warn, other.warn),
      warnBg: l(warnBg, other.warnBg),
      err: l(err, other.err),
      errBg: l(errBg, other.errBg),
      errInk: l(errInk, other.errInk),
      scrim: l(scrim, other.scrim),
    );
  }
}

/// Semantic status colours (for widgets that only need these four).
@immutable
class StatusColors {
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

  static StatusColors of(BuildContext context) {
    final p = Palette.of(context);
    return StatusColors(ok: p.ok, warn: p.warn, error: p.err, neutral: p.faint);
  }
}

abstract final class AppTheme {
  static const fontFamily = 'Manrope';
  static const monoFamily = 'monospace';

  static ThemeData dark() => _build(Brightness.dark, Palette.dark);
  static ThemeData light() => _build(Brightness.light, Palette.light);

  static ThemeData _build(Brightness brightness, Palette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.accentInk,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.accentText,
      secondary: p.accentText,
      onSecondary: p.accentInk,
      tertiary: p.ok,
      onTertiary: p.bg,
      error: p.err,
      onError: p.errInk,
      errorContainer: p.errBg,
      onErrorContainer: p.err,
      surface: p.bg,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface2,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surface2,
      outline: p.faint,
      outlineVariant: p.line,
      inverseSurface: p.text,
      onInverseSurface: p.bg,
      scrim: p.scrim,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
    );
    final text = base.textTheme.apply(bodyColor: p.text, displayColor: p.text);
    RoundedRectangleBorder r(double radius) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      extensions: [p],
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.accentInk,
          disabledBackgroundColor: p.surface2,
          disabledForegroundColor: p.faint,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: r(16),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentText,
          minimumSize: const Size(0, 40),
          shape: r(12),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface2,
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(
          color: p.accentText,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(p.accent, 1.5),
        errorBorder: border(p.err),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accentInk : p.faint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.faint,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: p.scrim,
        dragHandleColor: p.faint.withValues(alpha: 0.6),
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: r(24),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // Same tone as the cards, not an inverted (white) bar.
        backgroundColor: p.surface2,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: p.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: p.accentText,
        shape: r(14),
      ),
      listTileTheme: ListTileThemeData(iconColor: p.muted, shape: r(12)),
      dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surface2,
      ),
    );
  }
}
