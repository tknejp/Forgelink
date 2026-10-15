import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';

/// Bottom sheet with the last per-field outcome of one date.
Future<void> showDayDetail(
  BuildContext context,
  LocalDate date, {
  required VoidCallback onSync,
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _DayDetail(date: date, onSync: onSync),
    );

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.date, required this.onSync});

  final LocalDate date;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final c = context.watch<SyncController>();
    final text = SyncText(l10n);
    final day = c.days[date];

    Color colorOf(FieldOutcomeKind k) => switch (k) {
          FieldOutcomeKind.written || FieldOutcomeKind.unchanged => colors.ok,
          FieldOutcomeKind.missing => colors.neutral,
          FieldOutcomeKind.skippedFormula => colors.warn,
          FieldOutcomeKind.failed => colors.error,
        };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text.date(date), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (date == c.today)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.dayTodayWeightOnly,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            if (day == null)
              Text(l10n.dayNeverSynced)
            else if (day.issue != null)
              Text(text.presenter.message(day.issue!),
                  style: TextStyle(color: colors.error))
            else
              for (final col in SheetColumn.values)
                if (day.fields[col] case final f?)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: colorOf(f.kind), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(text.field(col))),
                        if (f.value != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(text.value(col, f.value!),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                        Text(text.outcome(f.kind),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colorOf(f.kind))),
                      ],
                    ),
                  ),
            if (day != null)
              for (final n in day.notes)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(text.presenter.message(n),
                      style: theme.textTheme.bodySmall),
                ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: c.busy
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onSync();
                      },
                icon: const Icon(Icons.sync),
                label: Text(l10n.daySyncNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
