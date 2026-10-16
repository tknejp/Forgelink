import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../day_view.dart';
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
            chip: _yesterdayChip(l10n, c.days[yesterday]),
          ),
          _QuickRow(
            icon: Icons.monitor_weight_rounded,
            title: l10n.qsToday(text.dayShort(today)),
            sub: switch (c.days[today]?.fields[SheetColumn.weight]?.value) {
              final v? => l10n.qsTodaySub(
                text.valueWithUnit(SheetColumn.weight, v),
              ),
              null => l10n.qsTodaySubNone,
            },
            chip: _todayChip(l10n, c.days[today]),
          ),
          const SizedBox(height: 12),
          BigButton(
            icon: _justDone ? Icons.check_rounded : Icons.sync_rounded,
            label: _buttonLabel(l10n, c),
            busy: c.busy,
            progress: c.busy ? _fraction(c.progress) : null,
            onPressed: widget.onQuickSync,
          ),
        ],
      ),
    );
  }

  (String, Tone) _yesterdayChip(AppLocalizations l10n, DayResult? day) {
    if (day == null) return (l10n.chipToWrite, Tone.accent);
    if (day.status == DayStatus.failed) return (l10n.chipError, Tone.err);
    if (nutritionMissing(day)) return (l10n.chipNutritionMissing, Tone.warn);
    return switch (day.status) {
      DayStatus.ok => (l10n.chipInSheet, Tone.ok),
      DayStatus.partial => (l10n.legendPartial, Tone.warn),
      _ => (l10n.chipNoData, Tone.neutral),
    };
  }

  (String, Tone) _todayChip(AppLocalizations l10n, DayResult? day) {
    final weight = day?.fields[SheetColumn.weight];
    if (day == null) return (l10n.chipToWrite, Tone.accent);
    if (day.issue != null) return (l10n.chipError, Tone.err);
    return switch (weight?.kind) {
      FieldOutcomeKind.written ||
      FieldOutcomeKind.unchanged => (l10n.chipInSheet, Tone.ok),
      FieldOutcomeKind.missing => (l10n.chipNoData, Tone.neutral),
      FieldOutcomeKind.skippedFormula ||
      FieldOutcomeKind.failed => (l10n.chipError, Tone.err),
      null => (l10n.chipToWrite, Tone.accent),
    };
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
