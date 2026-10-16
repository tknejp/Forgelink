import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../day_view.dart';
import '../settings/sheet_controller.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';

/// Bottom sheet with the last per-field outcome of one date.
Future<void> showDayDetail(
  BuildContext context,
  LocalDate date, {
  required VoidCallback onSync,
}) => showDesignSheet<void>(
  context,
  builder: (ctx) => _DayDetail(date: date, onSync: onSync),
);

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.date, required this.onSync});

  final LocalDate date;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<SyncController>();
    final tab = context.watch<SheetController>().tab;
    final text = SyncText(l10n);
    final day = c.days[date];
    final isToday = date == c.today;

    final sheetDay = c.sheet?.days[date];
    final (String chip, Tone chipTone) = switch (calendarStatus(
      date,
      c.today,
      day: day,
      sheet: c.sheet,
    )) {
      DayStatus.ok => (l10n.dayChipFull, Tone.ok),
      DayStatus.partial => (l10n.dayChipPartial, Tone.warn),
      DayStatus.failed => (l10n.dayChipFailed, Tone.err),
      DayStatus.noData => (l10n.dayChipNoData, Tone.neutral),
      null => (l10n.dayChipNone, Tone.neutral),
    };

    String stateLabel(CellState s) => switch (s) {
      CellState.inSheet => l10n.cellInSheet,
      CellState.toWrite => l10n.cellToWrite,
      CellState.missing => l10n.cellMissing,
      CellState.afterMidnight => l10n.cellAfterMidnight,
      CellState.formula => l10n.cellFormula,
      CellState.failed => l10n.cellFailed,
    };
    IconData stateIcon(CellState s) => switch (s) {
      CellState.inSheet => Icons.check_rounded,
      CellState.toWrite => Icons.upload_rounded,
      CellState.missing => Icons.block_rounded,
      CellState.afterMidnight => Icons.schedule_rounded,
      CellState.formula => Icons.functions_rounded,
      CellState.failed => Icons.error_rounded,
    };

    Widget fieldRow(SheetColumn col) {
      final value = cellValue(day, sheetDay, col);
      final state = cellStateWithSheet(day, sheetDay, col, isToday: isToday);
      final (fg, _) = state.tone.colors(p);
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.fieldLabel(col),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              value == null ? '—' : text.valueWithUnit(col, value),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: value == null ? p.faint : p.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(
              width: 112,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(stateIcon(state), size: 15, color: fg),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      stateLabel(state),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget group(String title, List<SheetColumn> cols) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupLabel(title, padding: const EdgeInsets.only(bottom: 4)),
        for (final col in cols) fieldRow(col),
      ],
    );

    // Missing nutrition is already explained by the day's NoData note.
    final note = c.retryDates.contains(date)
        ? l10n.dayWaitingNote
        : isToday
        ? l10n.dayTodayNote
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday
                        ? l10n.dayTodaySuffix(text.dayTitle(date))
                        : text.dayTitle(date),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(switch (c.sheet?.at) {
                    final at? => l10n.daySheetTabRead(
                      tab,
                      text.when(at, now: DateTime.now()),
                    ),
                    null => l10n.daySheetTab(tab),
                  }, style: TextStyle(fontSize: 12.5, color: p.muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TonePill(chip, chipTone),
          ],
        ),
        const SizedBox(height: 14),
        group(l10n.settingsSectionHealthConnect, hcColumns),
        const SizedBox(height: 14),
        group(l10n.settingsSectionKt, ktColumns),
        if (day?.issue != null) ...[
          const SizedBox(height: 14),
          Callout(text: text.presenter.message(day!.issue!), tone: Tone.err),
        ],
        // Why fields failed (e.g. missing login) when the whole day wasn't
        // refused.
        if (day != null && day.issue == null)
          for (final message in {
            for (final f in day.fields.values)
              if (f.issue case final i? when !i.isTransient)
                text.presenter.message(i),
          }) ...[
            const SizedBox(height: 10),
            Callout(text: message, tone: Tone.err),
          ],
        if (day != null)
          for (final n in day.notes) ...[
            const SizedBox(height: 10),
            Callout(
              text: text.presenter.message(n),
              tone: Tone.warn,
              icon: Icons.info_rounded,
            ),
          ],
        if (note != null) ...[
          const SizedBox(height: 14),
          Callout(text: note, tone: Tone.warn, icon: Icons.info_rounded),
        ],
        const SizedBox(height: 14),
        LockNote(l10n.lockNoteManual),
        const SizedBox(height: 14),
        Row(
          children: [
            SoftButton(
              label: l10n.actionClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: c.busy
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onSync();
                      },
                icon: const Icon(Icons.sync_rounded, size: 22),
                label: Text(day == null ? l10n.daySyncFirst : l10n.dayUpdate),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
