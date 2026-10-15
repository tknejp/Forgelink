import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/section_card.dart';

/// Last success, progress while running, last run result (+ details) and the
/// big Quick Sync button.
class SyncCard extends StatefulWidget {
  const SyncCard({super.key, required this.onQuickSync});

  final VoidCallback onQuickSync;

  @override
  State<SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<SyncCard> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final c = context.watch<SyncController>();
    final text = SyncText(l10n);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    final last = c.lastRun;
    final showResult = !c.busy &&
        last != null &&
        (last.status == RunStatus.partial || last.status == RunStatus.failed);

    return SectionCard(
      icon: Icons.sync,
      title: l10n.homeLastSyncTitle,
      children: [
        if (c.lastSuccess case final s?)
          Text(
            l10n.lastSuccessLine(
                text.when(s.at, now: DateTime.now()), text.triggerShort(s.trigger)),
            style: muted,
          )
        else
          Text(l10n.homeLastSyncNever, style: muted),
        if (c.busy) ...[
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: c.progress?.total == 0 ? null : c.progress?.fraction,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text(
            switch (c.progress) {
              SyncProgress(:final current?, :final done, :final total) =>
                l10n.syncProgress(done + 1, total, text.date(current)),
              _ => l10n.syncProgressWriting,
            },
            style: theme.textTheme.bodySmall?.merge(muted),
          ),
        ],
        if (showResult) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
            decoration: BoxDecoration(
              color: (last.status == RunStatus.failed
                      ? colors.error
                      : colors.warn)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.runSummary(last),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (_details) ...[
                  const SizedBox(height: 6),
                  for (final d in last.days)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(text.dayLine(d),
                          style: theme.textTheme.bodySmall),
                    ),
                ],
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => setState(() => _details = !_details),
                  child: Text(_details ? l10n.detailsHide : l10n.detailsShow),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: c.busy ? null : widget.onQuickSync,
            icon: c.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: Text(l10n.homeQuickSyncButton),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(l10n.homeQuickSyncSubtitle,
              style: theme.textTheme.bodySmall?.merge(muted)),
        ),
      ],
    );
  }
}
