import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Inline month calendar (F15).
///
/// A controlled, dialog-free month grid: the caller owns [selectedDate] and
/// receives [onDateSelected]. This is the inline companion to dialog date
/// pickers (owned by Phase 4) — same selection contract, no overlay.
///
/// [firstDayOfWeek] follows [DateTime] weekday constants ([DateTime.monday]
/// through [DateTime.sunday]). Days outside [minDate]..[maxDate] or rejected
/// by [selectableDayPredicate] render disabled.
class FwCalendar extends StatefulWidget {
  FwCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.minDate,
    this.maxDate,
    this.visibleMonth,
    this.onMonthChanged,
    this.firstDayOfWeek = DateTime.monday,
    this.selectableDayPredicate,
  }) : assert(
         minDate == null || maxDate == null || !minDate.isAfter(maxDate),
         'minDate must not be after maxDate',
       );

  /// Currently selected day (date part only). Null selects nothing.
  final DateTime? selectedDate;

  /// Fires when an enabled day is tapped.
  final ValueChanged<DateTime>? onDateSelected;

  /// Inclusive bounds for selectable days.
  final DateTime? minDate;
  final DateTime? maxDate;

  /// Month initially shown. Defaults to the selected date's month or today.
  final DateTime? visibleMonth;

  /// Fires when the visible month changes via the nav buttons.
  final ValueChanged<DateTime>? onMonthChanged;

  /// First column of the week ([DateTime.monday]..[DateTime.sunday]).
  final int firstDayOfWeek;

  /// Additional per-day enablement.
  final bool Function(DateTime day)? selectableDayPredicate;

  @override
  State<FwCalendar> createState() => _FwCalendarState();
}

class _FwCalendarState extends State<FwCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final anchor = widget.visibleMonth ?? widget.selectedDate ?? DateTime.now();
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  void _go(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    widget.onMonthChanged?.call(_visibleMonth);
  }

  bool _isEnabled(DateTime day) {
    final d = _dateOnly(day);
    if (widget.minDate != null && d.isBefore(_dateOnly(widget.minDate!))) {
      return false;
    }
    if (widget.maxDate != null && d.isAfter(_dateOnly(widget.maxDate!))) {
      return false;
    }
    if (widget.selectableDayPredicate != null &&
        !widget.selectableDayPredicate!(d)) {
      return false;
    }
    return widget.onDateSelected != null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MonthHeader(
          month: _visibleMonth,
          onPrevious: () => _go(-1),
          onNext: () => _go(1),
        ),
        _MonthView(
          visibleMonth: _visibleMonth,
          firstDayOfWeek: widget.firstDayOfWeek,
          isSelected: (day) =>
              widget.selectedDate != null &&
              _isSameDay(day, widget.selectedDate!),
          isInRange: (_) => false,
          isEnabled: _isEnabled,
          onDayTap: (day) => widget.onDateSelected?.call(_dateOnly(day)),
        ),
      ],
    );
  }
}

/// Inline date-range picker.
///
/// Controlled: the caller owns [start]/[end] and receives [onRangeSelected].
/// Tapping picks the start; tapping a second day completes the range; tapping
/// again starts a new range. The range highlight covers start..end inclusive.
class FwDateRangePicker extends StatefulWidget {
  const FwDateRangePicker({
    super.key,
    this.start,
    this.end,
    this.onRangeSelected,
    this.minDate,
    this.maxDate,
    this.visibleMonth,
    this.onMonthChanged,
    this.firstDayOfWeek = DateTime.monday,
    this.selectableDayPredicate,
  });

  /// Range start (date part only), or null.
  final DateTime? start;

  /// Range end (date part only), or null.
  final DateTime? end;

  /// Fires with the updated (start, end) after every tap.
  final void Function(DateTime? start, DateTime? end)? onRangeSelected;

  /// Inclusive bounds for selectable days.
  final DateTime? minDate;
  final DateTime? maxDate;

  /// Month initially shown.
  final DateTime? visibleMonth;

  /// Fires when the visible month changes via the nav buttons.
  final ValueChanged<DateTime>? onMonthChanged;

  /// First column of the week ([DateTime.monday]..[DateTime.sunday]).
  final int firstDayOfWeek;

  /// Additional per-day enablement.
  final bool Function(DateTime day)? selectableDayPredicate;

  @override
  State<FwDateRangePicker> createState() => _FwDateRangePickerState();
}

class _FwDateRangePickerState extends State<FwDateRangePicker> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final anchor =
        widget.visibleMonth ?? widget.start ?? widget.end ?? DateTime.now();
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  void _go(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    widget.onMonthChanged?.call(_visibleMonth);
  }

  bool _isEnabled(DateTime day) {
    final d = _dateOnly(day);
    if (widget.minDate != null && d.isBefore(_dateOnly(widget.minDate!))) {
      return false;
    }
    if (widget.maxDate != null && d.isAfter(_dateOnly(widget.maxDate!))) {
      return false;
    }
    if (widget.selectableDayPredicate != null &&
        !widget.selectableDayPredicate!(d)) {
      return false;
    }
    return widget.onRangeSelected != null;
  }

  void _tap(DateTime day) {
    final d = _dateOnly(day);
    final start = widget.start == null ? null : _dateOnly(widget.start!);
    final end = widget.end == null ? null : _dateOnly(widget.end!);
    if (start == null || end != null) {
      // Start a new range.
      widget.onRangeSelected?.call(d, null);
    } else if (d.isBefore(start)) {
      widget.onRangeSelected?.call(d, start);
    } else {
      widget.onRangeSelected?.call(start, d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.start == null ? null : _dateOnly(widget.start!);
    final end = widget.end == null ? null : _dateOnly(widget.end!);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MonthHeader(
          month: _visibleMonth,
          onPrevious: () => _go(-1),
          onNext: () => _go(1),
        ),
        _MonthView(
          visibleMonth: _visibleMonth,
          firstDayOfWeek: widget.firstDayOfWeek,
          isSelected: (day) =>
              (start != null && _isSameDay(day, start)) ||
              (end != null && _isSameDay(day, end)),
          isInRange: (day) =>
              start != null &&
              end != null &&
              !day.isBefore(start) &&
              !day.isAfter(end),
          isEnabled: _isEnabled,
          onDayTap: _tap,
        ),
      ],
    );
  }
}

/// Month navigation header: [‹] [Month Year] [›].
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final titleStyle = theme.typeScale.resolve(FwTextRole.h6, context);
    final strings = MaterialLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            strings.formatMonthYear(month),
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// The month grid shared by [FwCalendar] and [FwDateRangePicker].
class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.visibleMonth,
    required this.firstDayOfWeek,
    required this.isSelected,
    required this.isInRange,
    required this.isEnabled,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final int firstDayOfWeek;
  final bool Function(DateTime day) isSelected;
  final bool Function(DateTime day) isInRange;
  final bool Function(DateTime day) isEnabled;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final strings = MaterialLocalizations.of(context);
    final labelStyle = theme.typeScale.resolve(FwTextRole.label, context);
    final captionStyle = theme.typeScale.resolve(FwTextRole.caption, context);
    final today = _dateOnly(DateTime.now());

    // Weekday headers, rotated to firstDayOfWeek. narrowWeekdays[0] is Sunday.
    final weekdays = List.generate(
      7,
      (i) => strings.narrowWeekdays[(firstDayOfWeek + i) % 7],
    );

    final first = DateTime(visibleMonth.year, visibleMonth.month);
    final leading = (first.weekday - firstDayOfWeek + 7) % 7;
    final total = leading + _daysInMonth(first.year, first.month);
    final rows = (total / 7).ceil();

    Widget dayCell(int day) {
      final date = DateTime(first.year, first.month, day);
      final selected = isSelected(date);
      final inRange = isInRange(date);
      final enabled = isEnabled(date);
      final isToday = _isSameDay(date, today);

      final foreground = !enabled
          ? colors.of(FwColorRole.textMuted).withValues(alpha: 0.5)
          : selected
          ? colors.of(FwColorRole.onPrimary)
          : colors.of(FwColorRole.text);

      return Semantics(
        button: true,
        enabled: enabled,
        label: strings.formatFullDate(date),
        selected: selected,
        child: InkWell(
          onTap: enabled ? () => onDayTap(date) : null,
          customBorder: const CircleBorder(),
          child: Container(
            // The range band fills the whole cell; the selected/today
            // treatments sit on the inner circle.
            color: inRange && !selected
                ? colors.of(FwColorRole.primaryContainer)
                : null,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 36,
              decoration: selected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.of(FwColorRole.primary),
                    )
                  : isToday
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.of(FwColorRole.primary)),
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: labelStyle.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final name in weekdays)
              Expanded(
                child: Text(
                  name,
                  style: captionStyle.copyWith(
                    color: colors.of(FwColorRole.textMuted),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: () {
                    final index = r * 7 + c - leading + 1;
                    if (index < 1 ||
                        index > _daysInMonth(first.year, first.month)) {
                      return const SizedBox(height: 44);
                    }
                    return SizedBox(height: 44, child: dayCell(index));
                  }(),
                ),
            ],
          ),
      ],
    );
  }
}
