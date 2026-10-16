import 'package:flutter/material.dart';

import '../theme.dart';

/// Small building blocks of the Forgelink design (`Forgelink App.dc.html`):
/// panels, chips, icon tiles, label → value rows, action buttons, callouts.

/// Rounded surface card.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color,
    this.border,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border!, width: 1.5),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  spreadRadius: -12,
                  offset: Offset(0, -8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Status chip ("V tabulce", "Připojeno"), optionally with a leading dot.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
    this.dot = false,
  });

  final String label;
  final Color fg;
  final Color bg;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: dot ? 5 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tone of a chip / callout.
enum Tone { ok, warn, err, accent, neutral }

extension ToneColors on Tone {
  (Color fg, Color bg) colors(Palette p) => switch (this) {
    Tone.ok => (p.ok, p.okBg),
    Tone.warn => (p.warn, p.warnBg),
    Tone.err => (p.err, p.errBg),
    Tone.accent => (p.accentText, p.accentSoft),
    Tone.neutral => (p.muted, p.surface2),
  };
}

/// [Pill] coloured by [tone].
class TonePill extends StatelessWidget {
  const TonePill(this.label, this.tone, {super.key, this.dot = false});

  final String label;
  final Tone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone.colors(Palette.of(context));
    return Pill(label: label, fg: fg, bg: bg, dot: dot);
  }
}

/// Square-ish tile with an icon (settings cards, history rows).
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.size = 40,
    this.radius = 13,
    this.iconSize = 22,
    this.soft = true,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;

  /// Accent-tinted background; false = neutral surface2.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft ? p.accentSoft : p.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: p.accentText),
    );
  }
}

/// Uppercase group label above cards ("ZDROJE DAT").
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(4, 10, 4, 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: Palette.of(context).muted,
        ),
      ),
    );
  }
}

/// "Label → value" row with a hairline on top.
class KvRow extends StatelessWidget {
  const KvRow(
    this.label,
    this.value, {
    super.key,
    this.mono = false,
    this.valueColor,
    this.topBorder = true,
  });

  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final side = BorderSide(color: p.line);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: topBorder ? Border(top: side) : Border(bottom: side),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, color: p.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: mono ? 12.5 : 13.5,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? AppTheme.monoFamily : null,
                color: valueColor ?? p.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact action button of a settings card (38 px, icon + label).
class CardAction extends StatelessWidget {
  const CardAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final fg = primary ? p.accentInk : (danger ? p.err : p.accentText);
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled || busy ? 1 : 0.5,
      child: Material(
        color: primary ? p.accent : p.surface2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else
                  Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large primary button (56 px) — "Synchronizovat".
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.progress,
    this.height = 56,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  /// 0–1 while busy: the button fills from the left (null = no fill).
  final double? progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final enabled = onPressed != null;
    final fg = enabled ? p.accentInk : p.faint;
    final filling = busy && progress != null;
    return Material(
      color: !enabled
          ? p.surface2
          : filling
          ? Color.alphaBlend(p.accent.withValues(alpha: 0.45), p.surface)
          : p.accent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (filling)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress!.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: ColoredBox(color: p.accent),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: fg,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: 24, color: fg),
                  if (busy || icon != null) const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary full-height button used next to a primary one in sheets.
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted box with an icon and text (warnings, errors, info).
class Callout extends StatelessWidget {
  const Callout({
    super.key,
    required this.text,
    this.tone = Tone.warn,
    this.icon,
    this.action,
  });

  final String text;
  final Tone tone;
  final IconData? icon;

  /// Optional button under the text.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone.colors(Palette.of(context));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ??
                switch (tone) {
                  Tone.err => Icons.error_rounded,
                  Tone.ok => Icons.check_circle_rounded,
                  Tone.warn => Icons.warning_rounded,
                  _ => Icons.info_rounded,
                },
            size: 18,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(fontSize: 13, height: 1.45, color: fg),
                ),
                if (action != null) ...[const SizedBox(height: 6), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted line with a lock icon ("Hlad, hydratace … zůstanou beze změny").
class LockNote extends StatelessWidget {
  const LockNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_rounded, size: 18, color: p.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, height: 1.45, color: p.muted),
          ),
        ),
      ],
    );
  }
}

/// Row with a label, a sub-line and a switch (automatic sync settings).
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.bottomBorder = true,
  });

  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: bottomBorder
              ? Border(bottom: BorderSide(color: p.line))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: p.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Round 44 px icon button used in headers.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        foregroundColor: Palette.of(context).text,
      ),
      icon: Icon(icon, size: 24),
    );
  }
}

/// Small filter chip ("Vše", "Ručně", …).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: selected ? p.accentSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: selected ? p.accent : p.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? p.accentText : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft (surface2) compact button with an accent icon + label — "Období".
class SoftChipButton extends StatelessWidget {
  const SoftChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 36,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: p.accentText),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.accentText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet frame of the design: drag handle, 20 px sides.
Future<T?> showDesignSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  isDismissible: isDismissible,
  enableDrag: isDismissible,
  showDragHandle: true,
  builder: (ctx) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          22 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: builder(ctx),
      ),
    ),
  ),
);
