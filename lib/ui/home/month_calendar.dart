import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../theme.dart';

/// Compact month grid (plan §8).
///
/// - tap a day → sync it immediately;
/// - press and hold without moving → day detail;
/// - press, hold and drag across days → select a range (confirmed by the
///   caller);
/// - swipe left/right → next/previous month.
///
/// Future dates are never selectable. [actions] sit at the right end of the
/// month bar (e.g. range picker, history).
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.onTapDay,
    required this.onLongPressDay,
    required this.onSelectRange,
    this.actions = const [],
  });

  final void Function(LocalDate) onTapDay;
  final void Function(LocalDate) onLongPressDay;
  final void Function(LocalDate from, LocalDate to) onSelectRange;
  final List<Widget> actions;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late LocalDate _month; // first day of the shown month
  int _direction = 0; // -1 previous, 1 next (for the slide animation)
  LocalDate? _anchor; // where the hold started
  LocalDate? _focus; // where the finger is now

  static const cellHeight = 52.0;
  final _gridKey = GlobalKey();

  /// Grid width at gesture time (no LayoutBuilder, so the calendar can be
  /// measured by intrinsic-height parents such as SliverFillRemaining).
  double get _gridWidth =>
      (_gridKey.currentContext?.findRenderObject() as RenderBox?)?.size.width ??
      1;
  static final _title = DateFormat('LLLL yyyy', 'cs');
  static final _weekday = DateFormat.E('cs'); // po, út, st, …

  @override
  void initState() {
    super.initState();
    final t = context.read<SyncController>().today;
    _month = LocalDate(t.year, t.month, 1);
  }

  int get _leading => _month.weekday - 1; // Monday-first
  int get _daysInMonth =>
      LocalDate(_month.year, _month.month + 1, 1).addDays(-1).day;

  bool _canGoForward(LocalDate today) =>
      _month.isBefore(LocalDate(today.year, today.month, 1));

  void _shift(int months) => setState(() {
    _direction = months;
    _month = LocalDate(_month.year, _month.month + months, 1);
  });

  /// Day under [pos] (grid-local), clamped to this month and to [today].
  LocalDate _dayAt(Offset pos, double width, LocalDate today) {
    final col = (pos.dx / (width / 7)).floor().clamp(0, 6);
    final row = (pos.dy / cellHeight).floor().clamp(0, 5);
    final n = (row * 7 + col - _leading + 1).clamp(1, _daysInMonth);
    final d = LocalDate(_month.year, _month.month, n);
    return d.isAfter(today) ? today : d;
  }

  (LocalDate, LocalDate)? get _selection {
    final a = _anchor;
    final b = _focus;
    if (a == null || b == null) return null;
    return a.isAfter(b) ? (b, a) : (a, b);
  }

  void _endHold() {
    final sel = _selection;
    setState(() {
      _anchor = null;
      _focus = null;
    });
    if (sel == null) return;
    final (from, to) = sel;
    if (from == to) {
      widget.onLongPressDay(from);
    } else {
      widget.onSelectRange(from, to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<SyncController>();
    final today = c.today;
    final canGoForward = _canGoForward(today);
    final rows = ((_leading + _daysInMonth) / 7).ceil();
    final title = _title.format(_month.startOfDay);
    final sel = _selection;

    return Column(
      children: [
        // Month bar: ‹ title › … actions
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _shift(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                title[0].toUpperCase() + title.substring(1),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: canGoForward ? () => _shift(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            if (widget.actions.isNotEmpty) ...[
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: theme.colorScheme.outlineVariant,
              ),
              ...widget.actions,
            ],
          ],
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekday.format(DateTime(2026, 10, 12 + i)), // Mon..Sun
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        GestureDetector(
          // Month swipe. A hold-then-drag is claimed by the long press
          // below, so range selection and swiping don't collide.
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() < 250) return;
            if (v < 0 && canGoForward) _shift(1);
            if (v > 0) _shift(-1);
          },
          onLongPressStart: (d) {
            final day = _dayAt(d.localPosition, _gridWidth, today);
            HapticFeedback.selectionClick();
            setState(() {
              _anchor = day;
              _focus = day;
            });
          },
          onLongPressMoveUpdate: (d) {
            if (_anchor == null) return;
            final day = _dayAt(d.localPosition, _gridWidth, today);
            if (day != _focus) {
              HapticFeedback.selectionClick();
              setState(() => _focus = day);
            }
          },
          onLongPressEnd: (_) => _endHold(),
          onLongPressCancel: () => setState(() {
            _anchor = null;
            _focus = null;
          }),
          child: ClipRect(
            key: _gridKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(_month);
                final dx = (incoming ? 1 : -1) * _direction * 0.25;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(dx, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: Column(
                key: ValueKey(_month),
                children: [
                  for (var r = 0; r < rows; r++)
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(child: _cell(r, col, today, c, sel)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.calendarHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _cell(
    int r,
    int col,
    LocalDate today,
    SyncController c,
    (LocalDate, LocalDate)? sel,
  ) {
    final n = r * 7 + col - _leading + 1;
    if (n < 1 || n > _daysInMonth) {
      return const SizedBox(height: cellHeight);
    }
    final date = LocalDate(_month.year, _month.month, n);
    final selected =
        sel != null && !date.isBefore(sel.$1) && !date.isAfter(sel.$2);
    return _DayCell(
      date: date,
      isToday: date == today,
      isFuture: date.isAfter(today),
      running: c.running.contains(date),
      queued: c.queued.contains(date),
      selected: selected,
      status: c.days[date]?.status,
      onTap: () => widget.onTapDay(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.running,
    required this.queued,
    required this.selected,
    required this.status,
    required this.onTap,
  });

  final LocalDate date;
  final bool isToday;
  final bool isFuture;
  final bool running;
  final bool queued;
  final bool selected;
  final DayStatus? status;
  final VoidCallback onTap;

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

    final fill = selected
        ? scheme.primary
        : statusColor == null || status == DayStatus.noData
        ? Colors.transparent
        : statusColor.withValues(alpha: 0.18);

    final textColor = selected
        ? scheme.onPrimary
        : isFuture
        ? scheme.onSurface.withValues(alpha: 0.3)
        : statusColor ?? scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isToday && !selected
              ? BorderSide(color: scheme.primary, width: 1.5)
              : status == DayStatus.noData && !selected
              ? BorderSide(color: colors.neutral)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isFuture ? null : onTap,
          child: SizedBox(
            height: _MonthCalendarState.cellHeight - 4,
            child: Center(
              child: running
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${date.day}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isToday || selected
                                ? FontWeight.w700
                                : null,
                            color: textColor,
                          ),
                        ),
                        // Waiting in the sync queue.
                        if (queued)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
