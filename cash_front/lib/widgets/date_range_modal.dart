import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'date_selector.dart';

class DateRangeModal extends StatefulWidget {
  final DateFilter currentFilter;
  final Function(DateFilter) onFilterSelected;

  const DateRangeModal({
    Key? key,
    required this.currentFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  _DateRangeModalState createState() => _DateRangeModalState();
}

class _DateRangeModalState extends State<DateRangeModal> {
  late DateFilterType _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentFilter.type;
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
  }

  // Выбор даты для начального или конечного периода
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate =
        isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate:
          isStartDate
              ? (_endDate ?? DateTime.now().add(Duration(days: 365)))
              : DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF5B6CF6),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2935),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF23222A),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  // Создание фильтра на основе выбранного типа и дат
  DateFilter _createFilter() {
    switch (_selectedType) {
      case DateFilterType.day:
        final day = _startDate ?? DateTime.now();
        return DateFilter(
          type: DateFilterType.day,
          startDate: DateTime(day.year, day.month, day.day),
          endDate: DateTime(day.year, day.month, day.day, 23, 59, 59),
        );
      case DateFilterType.month:
        final month = _startDate ?? DateTime.now();
        return DateFilter(
          type: DateFilterType.month,
          startDate: DateTime(month.year, month.month, 1),
          endDate: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
        );
      case DateFilterType.year:
        final year = _startDate ?? DateTime.now();
        return DateFilter(
          type: DateFilterType.year,
          startDate: DateTime(year.year, 1, 1),
          endDate: DateTime(year.year, 12, 31, 23, 59, 59),
        );
      case DateFilterType.allTime:
        return DateFilter(
          type: DateFilterType.allTime,
          startDate: DateTime(2000, 1, 1),
          endDate: DateTime.now().add(Duration(days: 365)),
        );
      case DateFilterType.customRange:
        return DateFilter(
          type: DateFilterType.customRange,
          startDate: _startDate ?? DateTime.now().subtract(Duration(days: 7)),
          endDate: _endDate ?? DateTime.now(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Color(0xFF23222A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Выбор периода',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white24, height: 1),

          // Содержимое модального окна
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Основные периоды
                _buildOptionTile(
                  'День',
                  'Данные за один день',
                  DateFilterType.day,
                  DateFilterType.day == _selectedType,
                ),
                _buildOptionTile(
                  'Месяц',
                  'Данные за месяц',
                  DateFilterType.month,
                  DateFilterType.month == _selectedType,
                ),
                _buildOptionTile(
                  'Год',
                  'Данные за год',
                  DateFilterType.year,
                  DateFilterType.year == _selectedType,
                ),
                _buildOptionTile(
                  'Все время',
                  'Все данные',
                  DateFilterType.allTime,
                  DateFilterType.allTime == _selectedType,
                ),
                _buildOptionTile(
                  'Указать период',
                  'Выбрать диапазон дат',
                  DateFilterType.customRange,
                  DateFilterType.customRange == _selectedType,
                ),

                // Дополнительные настройки для выбранного типа фильтра
                if (_selectedType == DateFilterType.day)
                  _buildDateSelectionSection('Выберите день', true, false),

                if (_selectedType == DateFilterType.month)
                  _buildMonthYearSelection(),

                if (_selectedType == DateFilterType.year) _buildYearSelection(),

                if (_selectedType == DateFilterType.customRange)
                  _buildDateSelectionSection('Выберите период', true, true),

                SizedBox(height: 40),
              ],
            ),
          ),

          // Кнопка применения фильтра
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                final filter = _createFilter();
                widget.onFilterSelected(filter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5B6CF6),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Применить',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    DateFilterType type,
    bool isSelected,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      leading: Radio<DateFilterType>(
        value: type,
        groupValue: _selectedType,
        activeColor: Color(0xFF5B6CF6),
        onChanged: (value) {
          setState(() {
            _selectedType = value!;
          });
        },
      ),
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
    );
  }

  Widget _buildDateSelectionSection(
    String title,
    bool showStartDate,
    bool showEndDate,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          if (showStartDate) _buildDateField('С', _startDate, true),

          if (showEndDate) ...[
            SizedBox(height: 16),
            _buildDateField('По', _endDate, false),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isStartDate) {
    return Row(
      children: [
        Container(
          width: 40,
          child: Text(label, style: TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, isStartDate),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF2A2935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text(
                    date != null
                        ? DateFormat('dd.MM.yyyy').format(date)
                        : 'Выберите дату',
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthYearSelection() {
    final currentDate = _startDate ?? DateTime.now();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите месяц и год',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2935),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Год
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _startDate = DateTime(
                            currentDate.year - 1,
                            currentDate.month,
                            1,
                          );
                        });
                      },
                    ),
                    Text(
                      '${currentDate.year}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed:
                          currentDate.year >= DateTime.now().year
                              ? null
                              : () {
                                setState(() {
                                  _startDate = DateTime(
                                    currentDate.year + 1,
                                    currentDate.month,
                                    1,
                                  );
                                });
                              },
                      disabledColor: Colors.white24,
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Месяцы
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  physics: NeverScrollableScrollPhysics(),
                  children: List.generate(12, (index) {
                    final month = index + 1;
                    final isSelected = month == currentDate.month;
                    final monthName =
                        DateFormat('MMMM', 'ru_RU')
                            .format(DateTime(2000, month))
                            .substring(0, 3)
                            .toUpperCase();

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _startDate = DateTime(currentDate.year, month, 1);
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Color(0xFF5B6CF6)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSelected
                                  ? null
                                  : Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            monthName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelection() {
    final currentDate = _startDate ?? DateTime.now();
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (index) => currentYear - 5 + index);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите год',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2935),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 2.0,
              physics: NeverScrollableScrollPhysics(),
              children:
                  years.map((year) {
                    final isSelected = year == currentDate.year;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _startDate = DateTime(year, 1, 1);
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Color(0xFF5B6CF6)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSelected
                                  ? null
                                  : Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            '$year',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
