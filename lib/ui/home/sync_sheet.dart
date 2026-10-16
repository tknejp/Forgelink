import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/local_date.dart';
import '../../core/sync_issue.dart';
import '../../core/system_intents.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../day_view.dart';
import '../issue_actions.dart';
import '../settings/sheet_controller.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';

/// Progress and result of one manual sync (Quick Sync, range). The sheet can
/// be swiped away at any time; the sync keeps running and calendar taps keep
/// queueing. Resolves to true when the sheet was still open at the end.
Future<void> showSyncSheet(
  BuildContext context, {
  required String label,
  required List<LocalDate> dates,
  required Future<RunResult?> result,
  required Future<RunResult?> Function() restart,
}) => showDesignSheet<void>(
  context,
  builder: (_) => _SyncSheet(
    label: label,
    dates: sortedDates(dates),
    result: result,
    restart: restart,
  ),
);

class _SyncSheet extends StatefulWidget {
  const _SyncSheet({
    required this.label,
    required this.dates,
    required this.result,
    required this.restart,
  });

  final String label;
  final List<LocalDate> dates;
  final Future<RunResult?> result;
  final Future<RunResult?> Function() restart;

  @override
  State<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<_SyncSheet> {
  RunResult? _result;
  bool _finished = false;
  int _attempt = 0;

  static const _maxRows = 6;

  @override
  void initState() {
    super.initState();
    _watch(widget.result);
  }

  void _watch(Future<RunResult?> future) {
    final attempt = ++_attempt;
    future.then((r) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _result = r;
        _finished = true;
      });
    });
  }

  void _retry() {
    setState(() {
      _result = null;
      _finished = false;
    });
    _watch(widget.restart());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<SyncController>();
    final text = SyncText(l10n);
    final result = _result;

    // ─── header ───────────────────────────────────────────────────────────
    final status = result?.status;
    final ours = {
      for (final d in result?.days ?? const <DayResult>[])
        if (widget.dates.contains(d.date)) d.date: d,
    };
    final warnings = <String>[
      if (result != null && status != RunStatus.failed)
        for (final i in result.issues) text.presenter.message(i),
      for (final d in ours.values)
        for (final n in d.notes) text.presenter.message(n),
    ];
    final (String title, IconData icon, Tone tone) = !_finished
        ? (l10n.syncSheetRunning, Icons.sync_rounded, Tone.accent)
        : switch (status) {
            RunStatus.success when warnings.isEmpty => (
              l10n.syncSheetDone,
              Icons.check_circle_rounded,
              Tone.ok,
            ),
            RunStatus.success || RunStatus.partial => (
              l10n.syncSheetWarn,
              Icons.warning_rounded,
              Tone.warn,
            ),
            RunStatus.noData => (
              l10n.syncSheetNoData,
              Icons.info_rounded,
              Tone.warn,
            ),
            RunStatus.failed ||
            null => (l10n.syncSheetFailed, Icons.error_rounded, Tone.err),
          };
    final (toneFg, toneBg) = tone.colors(p);

    // ─── progress ─────────────────────────────────────────────────────────
    final running = sortedDates(c.running);
    final ourRunning = widget.dates.any(running.contains);
    final progress = c.progress;
    double fraction;
    if (_finished) {
      fraction = 1;
    } else if (ourRunning && progress != null && progress.total > 0) {
      fraction = (progress.done / progress.total) * 0.9 + 0.05;
    } else {
      fraction = 0.03;
    }

    // ─── per-day rows ─────────────────────────────────────────────────────
    _Row rowFor(LocalDate date) {
      final dayTitle = text.dayTitle(date);
      if (_finished) {
        final day = ours[date];
        if (day == null) {
          return _Row(
            dayTitle,
            l10n.runStatusFailed,
            Icons.error_rounded,
            p.err,
            p.err,
          );
        }
        if (day.issue != null) {
          return _Row(
            dayTitle,
            text.presenter.message(day.issue!),
            Icons.error_rounded,
            p.err,
            p.err,
          );
        }
        if (day.status == DayStatus.noData) {
          return _Row(
            dayTitle,
            l10n.syncRowNoData,
            Icons.remove_circle_rounded,
            p.faint,
            p.muted,
          );
        }
        final written = day
            .fieldsWhere((f) => f.kind == FieldOutcomeKind.written)
            .length;
        final unchanged = day
            .fieldsWhere((f) => f.kind == FieldOutcomeKind.unchanged)
            .length;
        final ktMissing = nutritionMissing(day) && date != c.today;
        final restLater =
            date == c.today &&
            day.fields.length > 1 &&
            day.fields.values.any((f) => f.kind == FieldOutcomeKind.missing);
        final failed = day.status == DayStatus.failed;
        final warn = ktMissing || day.status == DayStatus.partial;
        return _Row(
          dayTitle,
          [
            l10n.syncRowResult(written, unchanged),
            if (ktMissing) l10n.syncRowNutritionMissing,
            if (restLater) l10n.syncRowRestAfterMidnight,
          ].join(' · '),
          failed
              ? Icons.error_rounded
              : warn
              ? Icons.warning_rounded
              : Icons.check_circle_rounded,
          failed ? p.err : (warn ? p.warn : p.ok),
          p.muted,
        );
      }
      final pos = running.indexOf(date);
      if (pos < 0 || progress == null) {
        return _Row(
          dayTitle,
          l10n.syncRowWaiting,
          Icons.radio_button_unchecked_rounded,
          p.faint,
          p.faint,
        );
      }
      if (progress.done >= progress.total) {
        return _Row(
          dayTitle,
          l10n.syncRowWriting,
          null,
          p.accentText,
          p.accentText,
        );
      }
      if (pos < progress.done) {
        return _Row(
          dayTitle,
          l10n.syncRowRead,
          Icons.check_rounded,
          p.muted,
          p.muted,
        );
      }
      if (pos == progress.done) {
        return _Row(
          dayTitle,
          l10n.syncRowReading,
          null,
          p.accentText,
          p.accentText,
        );
      }
      return _Row(
        dayTitle,
        l10n.syncRowWaiting,
        Icons.radio_button_unchecked_rounded,
        p.faint,
        p.faint,
      );
    }

    final rows = [for (final d in widget.dates) rowFor(d)];
    final shown = rows.length > _maxRows ? rows.take(_maxRows).toList() : rows;

    // ─── actions ──────────────────────────────────────────────────────────
    final blocking = status == RunStatus.failed
        ? [
            ...?result?.issues,
            for (final d in ours.values) ?d.issue,
          ].firstOrNull
        : null;
    final fixAction = blocking?.action;
    final sheetId = context.watch<SheetController>().spreadsheetId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: toneBg, shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: toneFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.syncSheetSub(widget.label, widget.dates.length),
                    style: TextStyle(fontSize: 12.5, color: p.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: _finished ? toneFg : p.accent,
              backgroundColor: p.surface2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final r in shown) _RowView(r),
        if (rows.length > _maxRows)
          _RowView(
            _Row(
              l10n.syncMoreDays(rows.length - _maxRows),
              '',
              Icons.more_horiz_rounded,
              p.muted,
              p.muted,
            ),
          ),
        for (final w in warnings) ...[
          const SizedBox(height: 10),
          Callout(text: w, tone: Tone.warn),
        ],
        if (blocking != null) ...[
          const SizedBox(height: 10),
          Callout(text: text.presenter.message(blocking), tone: Tone.err),
        ],
        if (_finished) ...[
          const SizedBox(height: 16),
          if (fixAction != null)
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: SoftButton(
                    label: l10n.actionClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 14,
                  child: FilledButton(
                    onPressed: () async {
                      if (fixAction.kind == IssueActionKind.retry) {
                        _retry();
                        return;
                      }
                      await runIssueAction(context, fixAction);
                      if (mounted) _retry();
                    },
                    child: Text(text.presenter.actionLabel(fixAction)),
                  ),
                ),
              ],
            )
          else
            // Closing is the main action; the sheet can be opened, but
            // quieter (green, on the left).
            Row(
              children: [
                if (status != RunStatus.failed && sheetId != null) ...[
                  Expanded(flex: 13, child: _OpenSheetButton(sheetId: sheetId)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 10,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionClose),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Green, secondary "Otevřít tabulku" with the Sheets logo.
class _OpenSheetButton extends StatelessWidget {
  const _OpenSheetButton({required this.sheetId});

  final String sheetId;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.okBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<SystemIntents>().openUrl(
          'https://docs.google.com/spreadsheets/d/$sheetId/edit',
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(BrandLogos.sheets, width: 16, height: 21),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.actionOpenSheet,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.ok,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.title, this.sub, this.icon, this.iconColor, this.subColor);
  final String title;
  final String sub;

  /// null = spinner.
  final IconData? icon;
  final Color iconColor;
  final Color subColor;
}

class _RowView extends StatelessWidget {
  const _RowView(this.row);
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 22,
            child: row.icon == null
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: row.iconColor,
                    ),
                  )
                : Icon(row.icon, size: 22, color: row.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (row.sub.isNotEmpty)
                  Text(
                    row.sub,
                    style: TextStyle(fontSize: 12.5, color: row.subColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
