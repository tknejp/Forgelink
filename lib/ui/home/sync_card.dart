import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/local_date.dart';
import '../../core/system_intents.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../sync/sheet_status.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_history.dart';
import '../../sync/sync_models.dart';
import '../day_view.dart';
import '../settings/sheet_controller.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';

/// Bottom card on Home: what Quick Sync covers (yesterday in full, today's
/// weight) with each day's state from the last sync and the Synchronizovat
/// button, which also shows progress and a short "Hotovo".
class SyncCard extends StatefulWidget {
  const SyncCard({super.key, required this.onQuickSync});

  final VoidCallback onQuickSync;

  @override
  State<SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<SyncCard> {
  bool _wasBusy = false;
  bool _justDone = false;
  Timer? _doneTimer;

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  /// A finished run that wrote or confirmed something briefly turns the
  /// button into "Hotovo" (problems come as a toast instead).
  void _trackFinish(SyncController c) {
    if (_wasBusy && !c.busy) {
      final s = c.lastRun?.status;
      if (s == RunStatus.success || s == RunStatus.noData) {
        _justDone = true;
        _doneTimer?.cancel();
        _doneTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _justDone = false);
        });
      }
    }
    if (c.busy) _justDone = false;
    _wasBusy = c.busy;
  }

  /// Reading dates fills most of the bar; writing completes it.
  double _fraction(SyncProgress? p) {
    if (p == null || p.total == 0) return 0.05;
    if (p.done >= p.total) return 0.92;
    return 0.05 + 0.8 * p.done / p.total;
  }

  String _buttonLabel(AppLocalizations l10n, SyncController c) {
    if (_justDone) return l10n.syncButtonDone;
    if (!c.busy) return l10n.homeQuickSyncButton;
    final p = c.progress;
    final base = p == null || p.total == 0 || p.done >= p.total
        ? l10n.syncButtonWriting
        : l10n.syncButtonProgress(p.done + 1, p.total);
    final queued = c.queued.length;
    return queued == 0 ? base : '$base · +$queued';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<SyncController>();
    final text = SyncText(l10n);
    final small = TextStyle(fontSize: 12, color: p.muted);
    _trackFinish(c);

    final today = c.today;
    final yesterday = today.addDays(-1);

    return Panel(
      radius: 24,
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.homeQuickSyncTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tooltip(
                  message: l10n.homeLastSync(''),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: p.muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          switch (c.lastSuccess) {
                            final s? => l10n.homeLastSyncWith(
                              text.when(s.at, now: DateTime.now()),
                              text.triggerShort(s.trigger),
                            ),
                            null => l10n.valueNever,
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: small,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _QuickRow(
            icon: Icons.restaurant_rounded,
            title: l10n.qsYesterday(text.dayShort(yesterday)),
            sub: l10n.qsYesterdaySub,
            chip: c.retryDates.contains(yesterday)
                ? (l10n.chipWaiting, Tone.warn)
                : _yesterdayChip(
                    l10n,
                    c.days[yesterday],
                    c.sheet?.days[yesterday],
                  ),
          ),
          _QuickRow(
            icon: Icons.monitor_weight_rounded,
            title: l10n.qsToday(text.dayShort(today)),
            sub: switch (cellValue(
              c.days[today],
              c.sheet?.days[today],
              SheetColumn.weight,
            )) {
              final v? => l10n.qsTodaySub(
                text.valueWithUnit(SheetColumn.weight, v),
              ),
              null => l10n.qsTodaySubNone,
            },
            chip: c.retryDates.contains(today)
                ? (l10n.chipWaiting, Tone.warn)
                : _todayChip(l10n, c.days[today], c.sheet?.days[today]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BigButton(
                  icon: _justDone ? Icons.check_rounded : Icons.sync_rounded,
                  label: _buttonLabel(l10n, c),
                  busy: c.busy,
                  progress: c.busy ? _fraction(c.progress) : null,
                  onPressed: widget.onQuickSync,
                ),
              ),
              const SizedBox(width: 10),
              _OpenSheetButton(
                spreadsheetId: context.watch<SheetController>().spreadsheetId,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sheet first (what is really there), then the last run's problems.
  (String, Tone) _yesterdayChip(
    AppLocalizations l10n,
    DayResult? day,
    SheetDay? sheet,
  ) {
    if (sheet != null) {
      final missingKt = ktColumns.where((k) => !sheet.filled.contains(k));
      final rest = [SheetColumn.weight].where((k) => !sheet.filled.contains(k));
      if (missingKt.isEmpty && rest.isEmpty) return (l10n.chipInSheet, Tone.ok);
      if (day != null && _dateProblem(day)) return (l10n.chipError, Tone.err);
      if (missingKt.length == ktColumns.length && sheet.filled.isNotEmpty) {
        return (l10n.chipNutritionMissing, Tone.warn);
      }
      if (sheet.filled.isNotEmpty) return (l10n.legendPartial, Tone.warn);
      return (l10n.chipToWrite, Tone.accent);
    }
    if (day == null) return (l10n.chipToWrite, Tone.accent);
    if (_dateProblem(day)) return (l10n.chipError, Tone.err);
    if (nutritionMissing(day)) return (l10n.chipNutritionMissing, Tone.warn);
    return switch (day.status) {
      DayStatus.ok => (l10n.chipInSheet, Tone.ok),
      DayStatus.partial => (l10n.legendPartial, Tone.warn),
      _ => (l10n.chipNoData, Tone.neutral),
    };
  }

  (String, Tone) _todayChip(
    AppLocalizations l10n,
    DayResult? day,
    SheetDay? sheet,
  ) {
    if (sheet?.filled.contains(SheetColumn.weight) ?? false) {
      return (l10n.chipInSheet, Tone.ok);
    }
    final weight = day?.fields[SheetColumn.weight];
    if (day == null) return (l10n.chipToWrite, Tone.accent);
    if (_dateProblem(day)) return (l10n.chipError, Tone.err);
    return switch (weight?.kind) {
      // In the run but no longer in the sheet → needs writing again.
      FieldOutcomeKind.written || FieldOutcomeKind.unchanged =>
        sheet == null
            ? (l10n.chipInSheet, Tone.ok)
            : (l10n.chipToWrite, Tone.accent),
      FieldOutcomeKind.missing => (l10n.chipNoData, Tone.neutral),
      FieldOutcomeKind.skippedFormula ||
      FieldOutcomeKind.failed => (l10n.chipError, Tone.err),
      null => (l10n.chipToWrite, Tone.accent),
    };
  }
}

/// Square green button next to Synchronizovat: opens the coach's sheet in
/// Google Sheets (or the browser).
/// Red only for a problem with that very date; account-wide problems are in
/// the status card, connection problems are retried.
bool _dateProblem(DayResult day) =>
    day.failures.any((i) => areaOf(i) == IssueArea.date);

class _OpenSheetButton extends StatelessWidget {
  const _OpenSheetButton({required this.spreadsheetId});

  final String? spreadsheetId;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final id = spreadsheetId;
    return Tooltip(
      message: context.l10n.actionOpenSheet,
      child: Material(
        color: p.okBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id == null
              ? null
              : () => context.read<SystemIntents>().openUrl(
                  'https://docs.google.com/spreadsheets/d/$id/edit',
                ),
          child: SizedBox.square(
            dimension: 56,
            child: Opacity(
              opacity: id == null ? 0.4 : 1,
              child: Center(
                child: SvgPicture.asset(
                  BrandLogos.sheets,
                  width: 22,
                  height: 29,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.chip,
  });

  final IconData icon;
  final String title;
  final String sub;
  final (String, Tone) chip;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconTile(icon, size: 36, radius: 12, iconSize: 20, soft: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(sub, style: TextStyle(fontSize: 12.5, color: p.muted)),
              ],
            ),
          ),
          TonePill(chip.$1, chip.$2),
        ],
      ),
    );
  }
}

/// Dates Quick Sync covers.
List<LocalDate> quickSyncDates(LocalDate today) => [today.addDays(-1), today];
