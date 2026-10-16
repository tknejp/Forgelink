import 'package:flutter/material.dart';

import '../theme.dart';
import 'ds.dart';

/// Settings card: icon tile, title, optional trailing chip, then the body
/// (label → value rows, notes, actions). [highlighted] briefly outlines it
/// (deep links).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
    this.highlighted = false,
    this.logo,
  });

  final IconData icon;

  /// Brand logo asset shown instead of [icon] (see [BrandLogos]).
  final String? logo;
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Panel(
      border: highlighted ? p.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (logo case final l?) BrandTile(l) else IconTile(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (children.isNotEmpty) ...[const SizedBox(height: 12), ...children],
        ],
      ),
    );
  }
}

/// Wrap of [CardAction]s with the design spacing.
class CardActions extends StatelessWidget {
  const CardActions(this.children, {super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Wrap(spacing: 8, runSpacing: 8, children: children),
  );
}

/// Muted (or coloured) note line inside a settings card.
class CardNote extends StatelessWidget {
  const CardNote(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: color ?? Palette.of(context).muted,
      ),
    ),
  );
}
