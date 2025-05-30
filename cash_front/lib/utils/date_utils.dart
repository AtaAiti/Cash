import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';

class AppDateUtils {
  // Создание фильтра определенного типа на основе даты
  static DateFilter createFilterOfType(
    DateFilterType type, {
    DateTime? refDate,
  }) {
    final date = refDate ?? DateTime.now();

    switch (type) {
      case DateFilterType.day:
        return DateFilter(
          type: type,
          startDate: DateTime(date.year, date.month, date.day),
          endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
        );
      case DateFilterType.month:
        return DateFilter(
          type: type,
          startDate: DateTime(date.year, date.month, 1),
          endDate: DateTime(date.year, date.month + 1, 0, 23, 59, 59),
        );
      case DateFilterType.year:
        return DateFilter(
          type: type,
          startDate: DateTime(date.year, 1, 1),
          endDate: DateTime(date.year, 12, 31, 23, 59, 59),
        );
      case DateFilterType.allTime:
        return DateFilter(
          type: type,
          startDate: DateTime(2000, 1, 1),
          endDate: DateTime.now().add(Duration(days: 1)),
        );
      case DateFilterType.customRange:
        // По умолчанию последняя неделя
        return DateFilter(
          type: type,
          startDate: DateTime(date.year, date.month, date.day - 7),
          endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
        );
    }
  }

  // Перемещение периода фильтра вперед
  static DateFilter moveNext(DateFilter filter) {
    switch (filter.type) {
      case DateFilterType.day:
        return DateFilter(
          type: filter.type,
          startDate: filter.startDate!.add(Duration(days: 1)),
          endDate: filter.endDate!.add(Duration(days: 1)),
        );
      case DateFilterType.month:
        // Переход к следующему месяцу
        final nextMonth =
            filter.startDate!.month == 12
                ? DateTime(filter.startDate!.year + 1, 1, 1)
                : DateTime(
                  filter.startDate!.year,
                  filter.startDate!.month + 1,
                  1,
                );

        final lastDayOfMonth = DateTime(
          nextMonth.year,
          nextMonth.month + 1,
          0,
          23,
          59,
          59,
        );

        return DateFilter(
          type: filter.type,
          startDate: nextMonth,
          endDate: lastDayOfMonth,
        );
      case DateFilterType.year:
        // Переход к следующему году
        return DateFilter(
          type: filter.type,
          startDate: DateTime(filter.startDate!.year + 1, 1, 1),
          endDate: DateTime(filter.startDate!.year + 1, 12, 31, 23, 59, 59),
        );
      case DateFilterType.customRange:
        // Для диапазона: смещаем на длину диапазона с сохранением его длины
        final durationInDays =
            filter.endDate!.difference(filter.startDate!).inDays;

        // Используем полночь начала и конца дня для большей точности
        final newStartDate = DateTime(
          filter.startDate!.year,
          filter.startDate!.month,
          filter.startDate!.day +
              durationInDays +
              1, // +1 чтобы не было наложения
        );

        final newEndDate = DateTime(
          newStartDate.year,
          newStartDate.month,
          newStartDate.day + durationInDays,
          23,
          59,
          59,
        );

        return DateFilter(
          type: filter.type,
          startDate: newStartDate,
          endDate: newEndDate,
        );
      case DateFilterType.allTime:
        // "Все время" не двигается
        return filter;
    }
  }

  // Перемещение периода фильтра назад
  static DateFilter movePrevious(DateFilter filter) {
    switch (filter.type) {
      case DateFilterType.day:
        return DateFilter(
          type: filter.type,
          startDate: filter.startDate!.subtract(Duration(days: 1)),
          endDate: filter.endDate!.subtract(Duration(days: 1)),
        );
      case DateFilterType.month:
        // Переход к предыдущему месяцу
        final prevMonth =
            filter.startDate!.month == 1
                ? DateTime(filter.startDate!.year - 1, 12, 1)
                : DateTime(
                  filter.startDate!.year,
                  filter.startDate!.month - 1,
                  1,
                );

        final lastDayOfMonth = DateTime(
          prevMonth.year,
          prevMonth.month + 1,
          0,
          23,
          59,
          59,
        );

        return DateFilter(
          type: filter.type,
          startDate: prevMonth,
          endDate: lastDayOfMonth,
        );
      case DateFilterType.year:
        // Переход к предыдущему году
        return DateFilter(
          type: filter.type,
          startDate: DateTime(filter.startDate!.year - 1, 1, 1),
          endDate: DateTime(filter.startDate!.year - 1, 12, 31, 23, 59, 59),
        );
      case DateFilterType.customRange:
        // Для диапазона: смещаем на длину диапазона с сохранением его длины
        final durationInDays =
            filter.endDate!.difference(filter.startDate!).inDays;

        // Используем полночь начала и конца дня для большей точности
        final newStartDate = DateTime(
          filter.startDate!.year,
          filter.startDate!.month,
          filter.startDate!.day -
              durationInDays -
              1, // -1 чтобы не было наложения
        );

        final newEndDate = DateTime(
          newStartDate.year,
          newStartDate.month,
          newStartDate.day + durationInDays,
          23,
          59,
          59,
        );

        return DateFilter(
          type: filter.type,
          startDate: newStartDate,
          endDate: newEndDate,
        );
      case DateFilterType.allTime:
        // "Все время" не двигается
        return filter;
    }
  }

  // Проверка ограничения перемещения в будущее
  static bool isAtFutureBoundary(DateFilter filter) {
    final now = DateTime.now();

    switch (filter.type) {
      case DateFilterType.day:
        final today = DateTime(now.year, now.month, now.day);
        return filter.startDate!.isAtSameMomentAs(today) ||
            filter.startDate!.isAfter(today);

      case DateFilterType.month:
        final currentMonth = DateTime(now.year, now.month, 1);
        return filter.startDate!.year == currentMonth.year &&
            filter.startDate!.month == currentMonth.month;

      case DateFilterType.year:
        return filter.startDate!.year >= now.year;

      case DateFilterType.customRange:
        // Произвольный диапазон может начинаться в будущем,
        // но мы ограничиваем возможность двигать его дальше в будущее
        return filter.endDate!.isAfter(now);

      case DateFilterType.allTime:
        return true; // Всегда на границе
    }
  }

  // Форматирование периодов для отображения
  static String formatPeriod(DateFilter filter) {
    switch (filter.type) {
      case DateFilterType.day:
        // Более информативный формат для дня
        return DateFormat('d MMMM yyyy г.', 'ru_RU').format(filter.startDate!);

      case DateFilterType.month:
        // Единообразное форматирование с указанием типа
        return DateFormat('MMMM yyyy г.', 'ru_RU').format(filter.startDate!);

      case DateFilterType.year:
        // Более информативное отображение года
        return DateFormat('yyyy г.', 'ru_RU').format(filter.startDate!);

      case DateFilterType.allTime:
        return 'За все время';

      case DateFilterType.customRange:
        // Более полное форматирование диапазона
        String startStr = DateFormat(
          'd MMM yyyy',
          'ru_RU',
        ).format(filter.startDate!);
        String endStr = DateFormat(
          'd MMM yyyy',
          'ru_RU',
        ).format(filter.endDate!);

        // Если год одинаковый, не дублируем его
        if (filter.startDate!.year == filter.endDate!.year) {
          // Если месяц одинаковый, отображаем только числа
          if (filter.startDate!.month == filter.endDate!.month) {
            startStr = DateFormat('d', 'ru_RU').format(filter.startDate!);
          } else {
            startStr = DateFormat('d MMM', 'ru_RU').format(filter.startDate!);
          }
        }

        return '$startStr - $endStr';
    }
  }
}
