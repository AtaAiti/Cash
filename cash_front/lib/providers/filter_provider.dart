import 'package:flutter/foundation.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';

class FilterProvider with ChangeNotifier {
  DateFilter _currentFilter = DateFilter(
    type: DateFilterType.month,
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  DateFilter get currentFilter => _currentFilter;

  void setFilter(DateFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }
}
