import 'package:cash_flip_app/utils/date_utils.dart';
import 'package:cash_flip_app/widgets/date_range_modal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateFilterType { day, month, year, allTime, customRange }

class DateFilter {
  final DateFilterType type;
  final DateTime? startDate;
  final DateTime? endDate;

  DateFilter({required this.type, this.startDate, this.endDate});

  String get displayText {
    switch (type) {
      case DateFilterType.day:
        return DateFormat('dd MMMM yyyy', 'ru_RU').format(startDate!);
      case DateFilterType.month:
        return DateFormat(
          'MMMM yyyy',
          'ru_RU',
        ).format(startDate!).toUpperCase();
      case DateFilterType.year:
        return DateFormat('yyyy', 'ru_RU').format(startDate!);
      case DateFilterType.allTime:
        return 'ВСЕ ВРЕМЯ';
      case DateFilterType.customRange:
        return '${DateFormat('dd.MM.yy').format(startDate!)} - ${DateFormat('dd.MM.yy').format(endDate!)}';
    }
  }
}

class DateSelector extends StatefulWidget {
  final Function(DateFilter) onDateChanged;
  final DateFilter? initialFilter;

  const DateSelector({
    Key? key,
    required this.onDateChanged,
    this.initialFilter,
  }) : super(key: key);

  @override
  _DateSelectorState createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  late DateFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter =
        widget.initialFilter ??
        DateFilter(
          type: DateFilterType.month,
          startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          endDate: DateTime(
            DateTime.now().year,
            DateTime.now().month + 1,
            0,
          ), // Последний день текущего месяца
        );
  }

  void _previousPeriod() {
    setState(() {
      _currentFilter = AppDateUtils.movePrevious(_currentFilter);
      widget.onDateChanged(_currentFilter);
    });
  }

  void _nextPeriod() {
    setState(() {
      _currentFilter = AppDateUtils.moveNext(_currentFilter);
      widget.onDateChanged(_currentFilter);
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DateRangeModal(
            currentFilter: _currentFilter,
            onFilterSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
              widget.onDateChanged(_currentFilter);
              Navigator.pop(context);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Проверка если сегодняшний день/текущий месяц - отключаем кнопку "вперед"
    bool disableNextButton = false;

    if (_currentFilter.type == DateFilterType.day) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      disableNextButton =
          _currentFilter.startDate!.isAtSameMomentAs(today) ||
          _currentFilter.startDate!.isAfter(today);
    } else if (_currentFilter.type == DateFilterType.month) {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      disableNextButton =
          _currentFilter.startDate!.year == currentMonth.year &&
          _currentFilter.startDate!.month == currentMonth.month;
    } else if (_currentFilter.type == DateFilterType.year) {
      final currentYear = DateTime.now().year;
      disableNextButton = _currentFilter.startDate!.year >= currentYear;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _previousPeriod,
            child: Icon(Icons.chevron_left, color: Colors.white54),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showFilterModal,
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentFilter.displayText,
                      style: TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
                backgroundColor: Color(0xFF393848),
                padding: EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
          GestureDetector(
            onTap: disableNextButton ? null : _nextPeriod,
            child: Icon(
              Icons.chevron_right,
              color: disableNextButton ? Colors.white24 : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
