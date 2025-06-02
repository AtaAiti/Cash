import 'package:flutter/material.dart';
import 'package:cash_flip_app/widgets/app_drawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/widgets/date_selector.dart'; // Добавьте импорт
import 'package:cash_flip_app/widgets/balance_app_bar.dart';
import 'package:cash_flip_app/providers/currency_provider.dart';
import 'package:flutter/scheduler.dart';

class OverviewScreen extends StatefulWidget {
  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _showExpensesView = true;

  DateFilter _currentFilter = DateFilter(
    type: DateFilterType.month,
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  @override
  void initState() {
    super.initState();

    // Изменить фильтр на предыдущий месяц, так как транзакции за май
    final now = DateTime.now();
    final lastMonth =
        now.month == 1
            ? DateTime(now.year - 1, 12)
            : DateTime(now.year, now.month - 1);

    _currentFilter = DateFilter(
      type: DateFilterType.month,
      startDate: DateTime(lastMonth.year, lastMonth.month, 1),
      endDate: DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Принудительно обновляем данные при открытии экрана
      await Provider.of<TransactionsProvider>(
        context,
        listen: false,
      ).loadData();
      await Provider.of<CategoriesProvider>(context, listen: false).loadData();
      setState(() {}); // Обновляем UI после загрузки
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final targetDisplayCurrency = currencyProvider.displayCurrency; // Получаем целевую валюту

    // Получаем все транзакции с применением фильтра по дате
    final filteredTransactions = transactionsProvider.getFilteredTransactions(
      _currentFilter,
    );

    // Добавляем отладочную информацию
    print('DEBUG: Обзор - найдено ${filteredTransactions.length} транзакций');

    // Разделяем на расходы и доходы используя isExpense категории, а не только знак суммы
    final expenseTransactions =
        filteredTransactions.where((tx) {
          if (tx.categoryId == null) {
            // Если категория не указана, определяем по знаку суммы
            return tx.amount < 0;
          }

          // Ищем категорию
          Category? category;
          try {
            category = categoriesProvider.categories.firstWhere(
              (c) => c.id == tx.categoryId.toString(),
            );

            // Если категория найдена, используем её флаг isExpense
            if (category != null) {
              return category.isExpense;
            }
          } catch (e) {
            print('DEBUG: Ошибка поиска категории: $e');
          }

          // По умолчанию, используем знак суммы
          return tx.amount < 0;
        }).toList();

    final incomeTransactions =
        filteredTransactions.where((tx) {
          if (tx.categoryId == null) {
            return tx.amount > 0;
          }

          // Для income транзакций:
          Category? category;
          try {
            category = categoriesProvider.categories.firstWhere(
              (c) => c.id == tx.categoryId.toString(),
            );

            if (category != null) {
              return !category.isExpense;
            }
          } catch (e) {
            print('DEBUG: Ошибка поиска категории: $e');
          }

          return tx.amount > 0;
        }).toList();

    print(
      'DEBUG: Обзор - найдено ${expenseTransactions.length} транзакций расходов',
    );
    print(
      'DEBUG: Обзор - найдено ${incomeTransactions.length} транзакций доходов',
    );

    // Группировка по категориям с улучшенной обработкой
    final expenseByCategory = <String, double>{};
    for (var tx in expenseTransactions) {
      String categoryName = tx.category ?? 'Без категории';
      double amount = tx.amount.abs(); // Всегда используем положительное значение

      // Конвертируем сумму транзакции в targetDisplayCurrency
      double convertedAmount;
      if (currencyProvider.normalizeSymbol(tx.currency) == targetDisplayCurrency) {
        convertedAmount = amount;
      } else {
        convertedAmount = currencyProvider.convert(
          amount,
          tx.currency,
          targetDisplayCurrency,
        );
      }

      expenseByCategory[categoryName] =
          (expenseByCategory[categoryName] ?? 0) + convertedAmount;
    }

    final incomeByCategory = <String, double>{};
    for (var tx in incomeTransactions) {
      String categoryName = tx.category ?? 'Без категории';
      // Для доходов мы обычно используем оригинальный знак, но для конвертации суммы нужен abs,
      // а затем, если это доход, он будет добавлен как есть.
      // Здесь логика должна быть аккуратной: конвертируем abs, а потом решаем, прибавлять или вычитать.
      // Но так как мы уже отфильтровали incomeTransactions, то amount > 0.
      double amount = tx.amount.abs(); // tx.amount здесь всегда > 0

      // Конвертируем сумму транзакции в targetDisplayCurrency
      double convertedAmount;
      if (currencyProvider.normalizeSymbol(tx.currency) == targetDisplayCurrency) {
        convertedAmount = amount;
      } else {
        convertedAmount = currencyProvider.convert(
          amount,
          tx.currency,
          targetDisplayCurrency,
        );
      }

      incomeByCategory[categoryName] =
          (incomeByCategory[categoryName] ?? 0) + convertedAmount;
    }

    // Отладочная информация о категориях
    print(
      'DEBUG: Обзор - категории расходов: ${expenseByCategory.keys.join(", ")}',
    );
    print(
      'DEBUG: Обзор - категории доходов: ${incomeByCategory.keys.join(", ")}',
    );

    // Сортировка по сумме
    final sortedExpense =
        expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final sortedIncome =
        incomeByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Общие суммы
    final totalExpenses = expenseTransactions.fold<double>(
      0,
      (sum, tx) {
        double amount = tx.amount.abs();
        double convertedAmount;
        if (currencyProvider.normalizeSymbol(tx.currency) == targetDisplayCurrency) {
          convertedAmount = amount;
        } else {
          convertedAmount = currencyProvider.convert(
            amount,
            tx.currency,
            targetDisplayCurrency,
          );
        }
        return sum + convertedAmount;
      },
    );
    final totalIncome = incomeTransactions.fold<double>(
      0,
      (sum, tx) {
        // tx.amount здесь всегда > 0
        double amount = tx.amount;
        double convertedAmount;
        if (currencyProvider.normalizeSymbol(tx.currency) == targetDisplayCurrency) {
          convertedAmount = amount;
        } else {
          convertedAmount = currencyProvider.convert(
            amount,
            tx.currency,
            targetDisplayCurrency,
          );
        }
        return sum + convertedAmount;
      },
    );

    return Scaffold(
      backgroundColor: Color(0xFF23222A),
      drawer: AppDrawer(),
      appBar: BalanceAppBar(
        title: 'Все счета',
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showExpensesView = true;
                      });
                    },
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            _showExpensesView
                                ? Color(0xFF2A2935)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Расходы',
                        style: TextStyle(
                          color:
                              _showExpensesView ? Colors.white : Colors.white54,
                          fontWeight:
                              _showExpensesView
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showExpensesView = false;
                      });
                    },
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            !_showExpensesView
                                ? Color(0xFF2A2935)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Доходы',
                        style: TextStyle(
                          color:
                              !_showExpensesView
                                  ? Colors.white
                                  : Colors.white54,
                          fontWeight:
                              !_showExpensesView
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Add the chart visualization here
          Container(
            height: 200,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child:
                _showExpensesView
                    ? _buildPieChart(
                      sortedExpense,
                      totalExpenses,
                      categoriesProvider,
                      isExpense: true,
                    )
                    : _buildPieChart(
                      sortedIncome,
                      totalIncome,
                      categoriesProvider,
                      isExpense: false,
                    ),
          ),
          Expanded(
            child:
                _showExpensesView
                    ? _buildCategoryList(
                      sortedExpense,
                      categoriesProvider,
                      totalExpenses,
                      isExpense: true,
                    )
                    : _buildCategoryList(
                      sortedIncome,
                      categoriesProvider,
                      totalIncome,
                      isExpense: false,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    List<MapEntry<String, double>> sorted,
    CategoriesProvider categoriesProvider,
    double total, {
    required bool isExpense,
  }) {
    // Получаем CurrencyProvider для форматирования сумм
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final targetDisplayCurrency = currencyProvider.displayCurrency;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (sorted.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                isExpense ? 'Нет расходов' : 'Нет доходов',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ),
        if (sorted.isNotEmpty)
          ...sorted.map((entry) {
            Category? category;
            try {
              category = categoriesProvider.categories.firstWhere(
                (c) => c.name == entry.key,
              );
            } catch (e) {
              // Категория не найдена, category остается null
              print('DEBUG: Категория не найдена: ${entry.key}');
            }
            final percent = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (category?.color ?? Colors.grey)
                        .withOpacity(0.2),
                    child: Icon(
                      category?.icon ?? Icons.category,
                      color: category?.color ?? Colors.grey,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category?.color ??
                                (isExpense
                                    ? Colors.pinkAccent
                                    : Colors.tealAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        // Используем formatAmount для отображения суммы
                        currencyProvider.formatAmount(entry.value, targetDisplayCurrency),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  // Замените вашу функцию _buildPieChart на эту:
  Widget _buildPieChart(
    List<MapEntry<String, double>> data,
    double total,
    CategoriesProvider categoriesProvider, {
    required bool isExpense,
  }) {
    // Отладочная информация
    print('DEBUG: Построение диаграммы - ${isExpense ? "расходы" : "доходы"}');
    print('DEBUG: Количество категорий для диаграммы: ${data.length}');
    print('DEBUG: Общая сумма: $total');

    if (data.isEmpty) {
      return Center(
        child: Text(
          isExpense ? 'Нет данных о расходах' : 'Нет данных о доходах',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Берем топ-5 категорий, остальные объединяем в "Другое"
    final chartData = <ChartSampleData>[];

    // Обработка топ-5 категорий
    for (int i = 0; i < data.length && i < 5; i++) {
      final entry = data[i];
      Category? category;

      try {
        category = categoriesProvider.categories.firstWhere(
          (c) => c.name == entry.key,
        );
      } catch (e) {
        // Category not found, category remains null
        print('DEBUG: Ошибка поиска категории для диаграммы: $e');
      }

      chartData.add(
        ChartSampleData(
          x: entry.key,
          y: entry.value,
          color:
              category?.color ??
              (isExpense ? Colors.pinkAccent : Colors.tealAccent),
        ),
      );
    }

    // Объединение остальных категорий в "Другое" если их больше 5
    if (data.length > 5) {
      final otherValue = data
          .skip(5)
          .fold<double>(0, (sum, entry) => sum + entry.value);

      if (otherValue > 0) {
        chartData.add(
          ChartSampleData(x: 'Другое', y: otherValue, color: Colors.grey),
        );
      }
    }

    print('DEBUG: Построено ${chartData.length} элементов для диаграммы');

    return SfCircularChart(
      margin: EdgeInsets.zero,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(color: Colors.white70, fontSize: 12),
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: point.y ₽',
        textStyle: TextStyle(color: Colors.white),
        color: Color(0xFF393848),
      ),
      series: <CircularSeries<ChartSampleData, String>>[
        DoughnutSeries<ChartSampleData, String>(
          dataSource: chartData,
          xValueMapper: (ChartSampleData data, _) => data.x,
          yValueMapper: (ChartSampleData data, _) => data.y,
          pointColorMapper: (ChartSampleData data, _) => data.color,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// Add this class for chart data
class ChartSampleData {
  final String x;
  final double y;
  final Color color;

  ChartSampleData({required this.x, required this.y, required this.color});
}
