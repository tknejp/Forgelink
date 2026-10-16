import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';

/// "Synchronizovat období": presets, then tap the first and the last day.
/// Pops with the chosen inclusive range, or null when closed.
class RangeScreen extends StatefulWidget {
  const RangeScreen({super.key});

  static Future<(LocalDate, LocalDate)?> open(BuildContext context) =>
      Navigator.of(context).push<(LocalDate, LocalDate)>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const RangeScreen(),
        ),
      );

  @override
  State<RangeScreen> createState() => _RangeScreenState();
}

class _RangeScreenState extends State<RangeScreen> {
  late LocalDate _today;
  late LocalDate _month;
  LocalDate? _a;
  LocalDate? _b;

  static final _title = DateFormat('LLLL yyyy', 'cs');
  static final _weekday = DateFormat.E('cs');

  @override
  void initState() {
    super.initState();
    _today = context.read<SyncController>().today;
    _month = LocalDate(_today.year, _today.month, 1);
  }

  LocalDate get _thisMonth => LocalDate(_today.year, _today.month, 1);

  void _preset(LocalDate from) => setState(() {
    _month = _thisMonth;
    _a = from;
    _b = _today;
  });

  void _tap(LocalDate d) => setState(() {
    final a = _a;
    if (a == null || _b != null) {
      _a = d;
      _b = null;
    } else if (d.isBefore(a)) {
      _a = d;
      _b = a;
    } else {
      _b = d;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final text = SyncText(l10n);
    final a = _a;
    final b = _b ?? _a;
    final count = a == null ? 0 : a.daysUntil(b!) + 1;
    final tooLong = count > AppConfig.maxRangeDays;

    final summary = a == null
        ? l10n.rangePickFirst
        : tooLong
        ? l10n.rangeTooLong(AppConfig.maxRangeDays)
        : _b == null
        ? l10n.rangePickEnd(text.dayMonth(a))
        : l10n.rangeSummary(text.dayMonth(a), text.dayMonth(b!), count);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.actionClose,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.homeRangeSync),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(l10n.rangePreset3, () => _preset(_today.addDays(-2))),
              _PresetChip(l10n.rangePreset7, () => _preset(_today.addDays(-6))),
              _PresetChip(l10n.rangePresetMonth, () => _preset(_thisMonth)),
            ],
          ),
          const SizedBox(height: 14),
          Panel(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.monthPrev,
                      onPressed: () => setState(
                        () => _month = LocalDate(
                          _month.year,
                          _month.month - 1,
                          1,
                        ),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        () {
                          final t = _title.format(_month.startOfDay);
                          return t[0].toUpperCase() + t.substring(1);
                        }(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.monthNext,
                      onPressed: _month.isBefore(_thisMonth)
                          ? () => setState(
                              () => _month = LocalDate(
                                _month.year,
                                _month.month + 1,
                                1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Center(
                          child: Text(
                            _weekday.format(DateTime(2026, 10, 12 + i)),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.faint,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _grid(p, a, b),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LockNote(l10n.rangeLockNote),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                summary,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tooLong ? p.err : p.muted,
                ),
              ),
              const SizedBox(height: 10),
              BigButton(
                icon: Icons.sync_rounded,
                label: a == null || tooLong
                    ? l10n.homeQuickSyncButton
                    : l10n.rangeButton(count),
                onPressed: a == null || tooLong
                    ? null
                    : () => Navigator.of(context).pop((a, b!)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(Palette p, LocalDate? a, LocalDate? b) {
    final leading = _month.weekday - 1;
    final days = LocalDate(_month.year, _month.month + 1, 1).addDays(-1).day;
    final rows = ((leading + days) / 7).ceil();
    final hasBand = a != null && b != null && a != b;

    Widget cell(int index) {
      final n = index - leading + 1;
      if (n < 1 || n > days) return const SizedBox(height: 44);
      final d = LocalDate(_month.year, _month.month, n);
      final future = d.isAfter(_today);
      final inRange = a != null && b != null && !d.isBefore(a) && !d.isAfter(b);
      final isEnd = inRange && (d == a || d == b);
      final col = index % 7;
      final roundLeft = d == a || col == 0;
      final roundRight = d == b || col == 6;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : () => _tap(d),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: inRange && hasBand ? p.accentSoft : null,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(roundLeft ? 22 : 0),
              right: Radius.circular(roundRight ? 22 : 0),
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEnd ? p.accent : null,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isEnd ? p.accentInk : (future ? p.faint : p.text),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: cell(r * 7 + col)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
