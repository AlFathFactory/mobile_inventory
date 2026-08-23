import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

Future<DateTimeRange?> showReportDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ReportDateRangePicker(initialRange: initialRange),
      ),
    ),
  );
}

class ReportDateRangePicker extends StatefulWidget {
  const ReportDateRangePicker({this.initialRange, super.key});

  final DateTimeRange? initialRange;

  @override
  State<ReportDateRangePicker> createState() => _ReportDateRangePickerState();
}

class _ReportDateRangePickerState extends State<ReportDateRangePicker> {
  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange == null
        ? null
        : DateUtils.dateOnly(widget.initialRange!.start);
    _end = widget.initialRange == null
        ? null
        : DateUtils.dateOnly(widget.initialRange!.end);
    final initialDate = _start ?? DateUtils.dateOnly(DateTime.now());
    _visibleMonth = DateTime(initialDate.year, initialDate.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  void _selectDate(DateTime date) {
    final selected = DateUtils.dateOnly(date);
    setState(() {
      if (_start == null || _end != null) {
        _start = selected;
        _end = null;
      } else if (selected.isBefore(_start!)) {
        _end = _start;
        _start = selected;
      } else {
        _end = selected;
      }
      _visibleMonth = DateTime(selected.year, selected.month);
    });
  }

  void _confirm() {
    final start = _start;
    if (start == null) return;
    Navigator.of(context).pop(DateTimeRange(start: start, end: _end ?? start));
  }

  bool _sameDay(DateTime? first, DateTime second) {
    return first != null && DateUtils.isSameDay(first, second);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    final weekDays = List<String>.generate(
      DateTime.daysPerWeek,
      (index) => localizations.narrowWeekdays[(firstDayIndex + index) % 7],
    );
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final firstWeekdayIndex = firstOfMonth.weekday % 7;
    final leadingDays =
        (firstWeekdayIndex - firstDayIndex + DateTime.daysPerWeek) %
        DateTime.daysPerWeek;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingDays));

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('اختر التاريخ', style: AppTextStyles.cardTitle),
              ),
              IconButton(
                key: const Key('close-report-date-picker'),
                tooltip: localizations.closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  IconButton(
                    key: const Key('previous-report-month'),
                    tooltip: localizations.previousMonthTooltip,
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left, size: 22),
                  ),
                  Expanded(
                    child: Text(
                      localizations.formatMonthYear(_visibleMonth),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('next-report-month'),
                    tooltip: localizations.nextMonthTooltip,
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right, size: 22),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final day in weekDays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: DateTime.daysPerWeek,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final date = gridStart.add(Duration(days: index));
              final isStart = _sameDay(_start, date);
              final isEnd = _sameDay(_end, date);
              final isInRange =
                  _start != null &&
                  _end != null &&
                  date.isAfter(_start!) &&
                  date.isBefore(_end!);
              return _CalendarDay(
                date: date,
                label: localizations.formatDecimal(date.day),
                semanticLabel: localizations.formatFullDate(date),
                isOutsideMonth: date.month != _visibleMonth.month,
                isStart: isStart,
                isEnd: isEnd,
                isInRange: isInRange,
                isToday: DateUtils.isSameDay(date, DateTime.now()),
                onTap: () => _selectDate(date),
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('confirm-report-date-range'),
              onPressed: _start == null ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.neutral300,
                shape: const StadiumBorder(),
              ),
              child: const Text('تأكيد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.label,
    required this.semanticLabel,
    required this.isOutsideMonth,
    required this.isStart,
    required this.isEnd,
    required this.isInRange,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final String semanticLabel;
  final bool isOutsideMonth;
  final bool isStart;
  final bool isEnd;
  final bool isInRange;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEndpoint = isStart || isEnd;
    return Semantics(
      label: semanticLabel,
      selected: isEndpoint || isInRange,
      button: true,
      child: InkResponse(
        key: ValueKey('report-date-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        radius: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isInRange)
              Positioned.fill(
                top: 6,
                bottom: 6,
                child: const ColoredBox(color: AppColors.accentVerySoft),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isEndpoint ? AppColors.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isEndpoint
                    ? Border.all(color: AppColors.accent)
                    : null,
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isEndpoint
                      ? Colors.white
                      : isOutsideMonth
                      ? AppColors.neutral400
                      : AppColors.text,
                  fontWeight: isEndpoint ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
