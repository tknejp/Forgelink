import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';

enum _Filter { all, manual, background, issues }

/// The last runs (newest first) grouped by day, filterable; tap a run to
/// expand its per-date lines.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;
  RunResult? _open;

  bool _matches(RunResult r) => switch (_filter) {
    _Filter.all => true,
    _Filter.manual => r.trigger != SyncTrigger.background,
    _Filter.background => r.trigger == SyncTrigger.background,
    _Filter.issues =>
      r.status == RunStatus.partial || r.status == RunStatus.failed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<SyncController>();
    final text = SyncText(l10n);
    final runs = c.runs.where(_matches).toList();
    final today = c.today;

    String groupTitle(LocalDate d) => d == today
        ? l10n.historyToday
        : d == today.addDays(-1)
        ? l10n.historyYesterday
        : text.dayTitle(d);

    final groups = <LocalDate, List<RunResult>>{};
    for (final r in runs) {
      groups.putIfAbsent(LocalDate.fromDateTime(r.finishedAt), () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final (f, label) in [
                  (_Filter.all, l10n.historyFilterAll),
                  (_Filter.manual, l10n.historyFilterManual),
                  (_Filter.background, l10n.historyFilterBackground),
                  (_Filter.issues, l10n.historyFilterIssues),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterPill(
                      label: label,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: c.runs.isEmpty || runs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        c.runs.isEmpty
                            ? l10n.historyEmpty
                            : l10n.historyFilterEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: p.muted),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final MapEntry(key: day, value: list)
                          in groups.entries) ...[
                        GroupLabel(groupTitle(day)),
                        const SizedBox(height: 6),
                        Panel(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Column(
                                children: [
                                  for (var i = 0; i < list.length; i++)
                                    _RunTile(
                                      run: list[i],
                                      open: identical(_open, list[i]),
                                      last: i == list.length - 1,
                                      onTap: () => setState(
                                        () => _open = identical(_open, list[i])
                                            ? null
                                            : list[i],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({
    required this.run,
    required this.open,
    required this.last,
    required this.onTap,
  });

  final RunResult run;
  final bool open;
  final bool last;
  final VoidCallback onTap;

  static final _time = DateFormat('H:mm', 'cs');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final text = SyncText(l10n);
    final (String chip, Tone tone) = switch (run.status) {
      RunStatus.success => (l10n.runStatusSuccess, Tone.ok),
      RunStatus.noData => (l10n.runStatusNoData, Tone.neutral),
      RunStatus.partial => (l10n.runStatusPartial, Tone.warn),
      RunStatus.failed => (l10n.runStatusFailed, Tone.err),
    };
    final detail = TextStyle(fontSize: 13, height: 1.45, color: p.muted);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: p.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  switch (run.trigger) {
                    SyncTrigger.quick => Icons.bolt_rounded,
                    SyncTrigger.calendar => Icons.event_rounded,
                    SyncTrigger.range => Icons.date_range_rounded,
                    SyncTrigger.background => Icons.schedule_rounded,
                  },
                  size: 38,
                  radius: 12,
                  iconSize: 20,
                  soft: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.trigger(run.trigger),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_time.format(run.finishedAt)} · '
                        '${text.dates([for (final d in run.days) d.date])}',
                        style: TextStyle(fontSize: 12.5, color: p.muted),
                      ),
                    ],
                  ),
                ),
                TonePill(chip, tone),
              ],
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.only(left: 50, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final i in run.issues)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          text.presenter.message(i),
                          style: detail.copyWith(color: p.warn),
                        ),
                      ),
                    for (final d in run.days)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(text.dayLine(d), style: detail),
                      ),
                    Text(l10n.historyCells(run.cellsWritten), style: detail),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
