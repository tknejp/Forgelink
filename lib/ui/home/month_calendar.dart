import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/local_date.dart';
import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../day_view.dart';
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
/// month bar (e.g. the "Období" button).
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.onTapDay,
    required this.onLongPressDay,
    required this.onSelectRange,
    this.actions = const [],
    this.showLegend = true,
    this.fill = false,
  });

  final void Function(LocalDate) onTapDay;
  final void Function(LocalDate) onLongPressDay;
  final void Function(LocalDate from, LocalDate to) onSelectRange;
  final List<Widget> actions;
  final bool showLegend;

  /// Take all the height the parent gives and stretch the week rows to it
  /// (Home); otherwise the cells are square.
  final bool fill;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late LocalDate _month; // first day of the shown month
  int _direction = 0; // -1 previous, 1 next (for the slide animation)
  LocalDate? _anchor; // where the hold started
  LocalDate? _focus; // where the finger is now

  final _gridKey = GlobalKey();

  /// Height of one week row from the last layout (for hit-testing drags).
  double _rowHeight = 0;

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
    final cell = width / 7;
    final col = (pos.dx / cell).floor().clamp(0, 6);
    final rowHeight = _rowHeight > 0 ? _rowHeight : cell;
    final row = (pos.dy / rowHeight).floor().clamp(0, 5);
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
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<SyncController>();
    final today = c.today;
    final canGoForward = _canGoForward(today);
    final rows = ((_leading + _daysInMonth) / 7).ceil();
    final title = _title.format(_month.startOfDay);
    final sel = _selection;

    Widget navButton(IconData icon, String tooltip, VoidCallback? onTap) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(40),
            foregroundColor: p.text,
            disabledForegroundColor: p.text.withValues(alpha: 0.3),
          ),
          icon: Icon(icon, size: 24),
        );

    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth / 7;
        // Fill mode: the card keeps its height and the rows share it
        // (5- and 6-week months), within sensible proportions.
        _rowHeight = widget.fill && constraints.maxHeight.isFinite
            ? (constraints.maxHeight / rows).clamp(
                colWidth * 0.62,
                colWidth * 1.3,
              )
            : colWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: _rowHeight * rows,
            child: _gestures(today, canGoForward, rows, c, sel),
          ),
        );
      },
    );

    return Column(
      mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month bar: ‹ title › … actions
        Row(
          children: [
            navButton(
              Icons.chevron_left_rounded,
              l10n.monthPrev,
              () => _shift(-1),
            ),
            Expanded(
              child: Text(
                title[0].toUpperCase() + title.substring(1),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            navButton(
              Icons.chevron_right_rounded,
              l10n.monthNext,
              canGoForward ? () => _shift(1) : null,
            ),
            if (widget.actions.isNotEmpty) ...[
              const SizedBox(width: 6),
              ...widget.actions,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekday.format(DateTime(2026, 10, 12 + i)), // Mon..Sun
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
        const SizedBox(height: 5),
        if (widget.fill) Expanded(child: grid) else grid,
        if (widget.showLegend) ...[
          const SizedBox(height: 8),
          _Legend(hint: l10n.calendarHint),
        ],
      ],
    );
  }

  Widget _gestures(
    LocalDate today,
    bool canGoForward,
    int rows,
    SyncController c,
    (LocalDate, LocalDate)? sel,
  ) {
    return GestureDetector(
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
      return SizedBox(height: _rowHeight);
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
      status: calendarStatus(date, today, day: c.days[date], sheet: c.sheet),
      height: _rowHeight,
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
    required this.height,
    required this.onTap,
  });

  final LocalDate date;
  final bool isToday;
  final bool isFuture;
  final bool running;
  final bool queued;
  final bool selected;
  final DayStatus? status;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    final (Color bg, Color fg) = selected
        ? (p.accent, p.accentInk)
        : isFuture
        ? (Colors.transparent, p.faint)
        : switch (status) {
            DayStatus.ok => (p.okBg, p.ok),
            DayStatus.partial => (p.warnBg, p.warn),
            DayStatus.failed => (p.errBg, p.err),
            DayStatus.noData || null => (p.surface2, p.text),
          };

    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: height - 6,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isToday && !selected ? p.accent : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isFuture ? null : onTap,
            child: Center(
              child: running
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: fg,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        // Waiting in the sync queue.
                        if (queued)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: p.accent,
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

class _Legend extends StatelessWidget {
  const _Legend({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final style = TextStyle(fontSize: 12, color: p.muted);

    Widget item(Color color, String label, {bool outlined = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: outlined ? Border.all(color: p.faint) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            item(p.ok, l10n.legendFull),
            item(p.warn, l10n.legendPartial),
            item(p.err, l10n.legendFailed),
            item(p.surface2, l10n.legendMissing, outlined: true),
          ],
        ),
        const SizedBox(height: 6),
        Text(hint, style: style.copyWith(color: p.faint)),
      ],
    );
  }
}
