import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../theme.dart';

/// Compact month grid (plan §8). Tap = sync that date immediately;
/// long-press = details. Future dates are disabled.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.onTapDay,
    required this.onLongPressDay,
  });

  final void Function(LocalDate) onTapDay;
  final void Function(LocalDate) onLongPressDay;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late LocalDate _month; // first day of the shown month

  static final _title = DateFormat('LLLL yyyy', 'cs');
  static final _weekday = DateFormat.E('cs'); // po, út, st, …

  @override
  void initState() {
    super.initState();
    final t = LocalDate.today();
    _month = LocalDate(t.year, t.month, 1);
  }

  void _shift(int months) =>
      setState(() => _month = LocalDate(_month.year, _month.month + months, 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<SyncController>();
    final today = c.today;
    final thisMonth = LocalDate(today.year, today.month, 1);
    final canGoForward = _month.isBefore(thisMonth);

    final daysInMonth = LocalDate(_month.year, _month.month + 1, 1)
        .addDays(-1)
        .day;
    final leading = _month.weekday - 1; // Monday-first
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    final title = _title.format(_month.startOfDay);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _shift(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                title[0].toUpperCase() + title.substring(1),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: canGoForward ? () => _shift(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekday.format(DateTime(2026, 10, 12 + i)), // Mon..Sun
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(builder: (_) {
                    final n = r * 7 + col - leading + 1;
                    if (n < 1 || n > daysInMonth) {
                      return const SizedBox(height: 46);
                    }
                    final date = LocalDate(_month.year, _month.month, n);
                    return _DayCell(
                      date: date,
                      isToday: date == today,
                      isFuture: date.isAfter(today),
                      running: c.running.contains(date),
                      disabled: c.busy,
                      status: c.days[date]?.status,
                      onTap: () => widget.onTapDay(date),
                      onLongPress: () => widget.onLongPressDay(date),
                    );
                  }),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          context.l10n.calendarHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.running,
    required this.disabled,
    required this.status,
    required this.onTap,
    required this.onLongPress,
  });

  final LocalDate date;
  final bool isToday;
  final bool isFuture;
  final bool running;
  final bool disabled;
  final DayStatus? status;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = StatusColors.of(context);

    final Color? statusColor = switch (status) {
      DayStatus.ok => colors.ok,
      DayStatus.partial => colors.warn,
      DayStatus.failed => colors.error,
      DayStatus.noData => colors.neutral,
      null => null,
    };

    final fill = statusColor == null || status == DayStatus.noData
        ? Colors.transparent
        : statusColor.withValues(alpha: 0.18);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isToday
              ? BorderSide(color: scheme.primary, width: 1.5)
              : status == DayStatus.noData
                  ? BorderSide(color: colors.neutral)
                  : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isFuture || disabled ? null : onTap,
          onLongPress: isFuture ? null : onLongPress,
          child: SizedBox(
            height: 42,
            child: Center(
              child: running
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      '${date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isToday ? FontWeight.w700 : null,
                        color: isFuture
                            ? scheme.onSurface.withValues(alpha: 0.3)
                            : statusColor ?? scheme.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
