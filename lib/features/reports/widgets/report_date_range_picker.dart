import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

Future<DateTimeRange?> showReportDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: AppColors.text.withValues(alpha: 0.56),
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
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

  bool _isInRange(DateTime date) {
    if (_start == null) return false;
    final end = _end ?? _start!;
    return !date.isBefore(_start!) && !date.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final firstDayIndex = l10n.firstDayOfWeekIndex;
    final weekDays = List<String>.generate(
      DateTime.daysPerWeek,
      (index) => l10n.narrowWeekdays[(firstDayIndex + index) % 7],
    );
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final firstWeekdayIndex = firstOfMonth.weekday % 7;
    final leadingDays =
        (firstWeekdayIndex - firstDayIndex + DateTime.daysPerWeek) %
        DateTime.daysPerWeek;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingDays));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentVerySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختيار التاريخ',
                      style: AppTextStyles.cardTitle,
                    ),
                    Text(
                      _start == null
                          ? 'اختر يومًا واحدًا أو فترة زمنية'
                          : _end == null
                          ? 'اعرض هذا اليوم أو اختر نهاية للفترة'
                          : 'الفترة جاهزة للتطبيق',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('close-report-date-picker'),
                tooltip: l10n.closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.neutral700,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RangeSummary(start: _start, end: _end, l10n: l10n),
          const SizedBox(height: 12),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  IconButton(
                    key: const Key('previous-report-month'),
                    tooltip: l10n.previousMonthTooltip,
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    color: AppColors.neutral800,
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      l10n.formatMonthYear(_visibleMonth),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('next-report-month'),
                    tooltip: l10n.nextMonthTooltip,
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    color: AppColors.neutral800,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final day in weekDays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: DateTime.daysPerWeek,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final date = gridStart.add(Duration(days: index));
              return _CalendarDay(
                date: date,
                label: l10n.formatDecimal(date.day),
                semanticLabel: l10n.formatFullDate(date),
                isOutsideMonth: date.month != _visibleMonth.month,
                isStart: _sameDay(_start, date),
                isEnd: _sameDay(_end, date),
                isInRange: _isInRange(date),
                isToday: DateUtils.isSameDay(date, DateTime.now()),
                onTap: () => _selectDate(date),
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  key: const Key('cancel-report-date-range'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutral800,
                    side: const BorderSide(color: AppColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    key: const Key('confirm-report-date-range'),
                    onPressed: _start == null ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.neutral300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('عرض التقرير'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({
    required this.start,
    required this.end,
    required this.l10n,
  });

  final DateTime? start;
  final DateTime? end;
  final MaterialLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.accentVerySoft,
        border: Border.all(color: AppColors.accentSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateValue(label: 'من', date: start, l10n: l10n),
          ),
          const Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          Expanded(
            child: _DateValue(label: 'إلى', date: end, l10n: l10n),
          ),
        ],
      ),
    );
  }
}

class _DateValue extends StatelessWidget {
  const _DateValue({
    required this.label,
    required this.date,
    required this.l10n,
  });

  final String label;
  final DateTime? date;
  final MaterialLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          date == null ? '—' : l10n.formatShortDate(date!),
          maxLines: 1,
          style: AppTextStyles.label.copyWith(
            color: date == null ? AppColors.neutral500 : AppColors.accentDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
      selected: isInRange,
      button: true,
      child: InkResponse(
        key: ValueKey('report-date-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        radius: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isInRange)
              Positioned.fill(
                top: 4,
                bottom: 4,
                child: const ColoredBox(color: AppColors.accentVerySoft),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 32,
              height: 32,
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
