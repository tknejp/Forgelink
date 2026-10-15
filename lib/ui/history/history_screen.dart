import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';

/// The last runs (newest first); tap to expand per-date lines.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final runs = context.watch<SyncController>().runs;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: runs.isEmpty
          ? Center(child: Text(l10n.historyEmpty))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: runs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _RunTile(run: runs[i]),
            ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({required this.run});

  final RunResult run;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final text = SyncText(l10n);
    final color = switch (run.status) {
      RunStatus.success => colors.ok,
      RunStatus.noData => colors.neutral,
      RunStatus.partial => colors.warn,
      RunStatus.failed => colors.error,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          switch (run.trigger) {
            SyncTrigger.quick => Icons.sync,
            SyncTrigger.calendar => Icons.calendar_today_outlined,
            SyncTrigger.range => Icons.date_range_outlined,
            SyncTrigger.background => Icons.schedule,
          },
          color: theme.colorScheme.primary,
        ),
        title: Text(text.trigger(run.trigger)),
        subtitle: Text(
          '${text.when(run.finishedAt, now: DateTime.now())} · '
          '${text.dates([for (final d in run.days) d.date])}',
        ),
        trailing: Text(text.runStatus(run.status),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in run.issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(text.presenter.message(i),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.warn)),
            ),
          for (final d in run.days)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(text.dayLine(d), style: theme.textTheme.bodySmall),
            ),
          Text(l10n.historyCells(run.cellsWritten),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
