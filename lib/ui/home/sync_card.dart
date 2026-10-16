import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';

/// Compact bottom card: last success, progress while running, last
/// partial/failed result (+ details) and the Quick Sync button with a
/// caption that names the actual dates.
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
    final scheme = theme.colorScheme;
    final colors = StatusColors.of(context);
    final c = context.watch<SyncController>();
    final text = SyncText(l10n);
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final last = c.lastRun;
    final showResult =
        !c.busy &&
        last != null &&
        (last.status == RunStatus.partial || last.status == RunStatus.failed);
    final today = c.today;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.busy) ...[
            LinearProgressIndicator(
              value: c.progress?.total == 0 ? null : c.progress?.fraction,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(switch (c.progress) {
              SyncProgress(:final current?, :final done, :final total) =>
                l10n.syncProgress(done + 1, total, text.date(current)),
              _ => l10n.syncProgressWriting,
            }, style: small),
            if (c.queued.isNotEmpty)
              Text(l10n.syncQueued(c.queued.length), style: small),
          ] else
            Row(
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(switch (c.lastSuccess) {
                    final s? => l10n.lastSuccessLine(
                      text.when(s.at, now: DateTime.now()),
                      text.triggerShort(s.trigger),
                    ),
                    null => l10n.homeLastSyncNever,
                  }, style: small),
                ),
              ],
            ),
          if (showResult) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              decoration: BoxDecoration(
                color:
                    (last.status == RunStatus.failed
                            ? colors.error
                            : colors.warn)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.runSummary(last),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_details)
                    for (final d in last.days)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          text.dayLine(d),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
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
          const SizedBox(height: 10),
          Text(
            l10n.homeQuickSyncLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: widget.onQuickSync,
            icon: c.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(l10n.homeQuickSyncButton),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeQuickSyncCaption(
              text.dayMonth(today.addDays(-1)),
              text.dayMonth(today),
            ),
            textAlign: TextAlign.center,
            style: small,
          ),
        ],
      ),
    );
  }
}
