import 'package:flutter/material.dart';
import 'package:cash_flip_app/widgets/app_drawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/widgets/date_selector.dart'; // Добавьте импорт
import 'package:cash_flip_app/widgets/balance_app_bar.dart';

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
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);

    final filteredTransactions = transactionsProvider.getFilteredTransactions(
      _currentFilter,
    );
    final expenseTransactions =
        filteredTransactions.where((tx) => tx.amount < 0).toList();
    final incomeTransactions =
        filteredTransactions.where((tx) => tx.amount > 0).toList();

    // Группировка по категориям
    final expenseByCategory = <String, double>{};
    for (var tx in expenseTransactions) {
      expenseByCategory[tx.category ?? 'Без категории'] =
          (expenseByCategory[tx.category ?? 'Без категории'] ?? 0) +
          tx.amount.abs();
    }
    final incomeByCategory = <String, double>{};
    for (var tx in incomeTransactions) {
      incomeByCategory[tx.category ?? 'Без категории'] =
          (incomeByCategory[tx.category ?? 'Без категории'] ?? 0) + tx.amount;
    }

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
      (sum, tx) => sum + tx.amount.abs(),
    );
    final totalIncome = incomeTransactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
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
              category = null;
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
                        '${entry.value.toStringAsFixed(2)} ₽',
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

  // Замените _buildPieChart на этот метод:
  Widget _buildPieChart(
    List<MapEntry<String, double>> data,
    double total,
    CategoriesProvider categoriesProvider, {
    required bool isExpense,
  }) {
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

    for (int i = 0; i < data.length; i++) {
      if (i < 5) {
        final entry = data[i];
        Category? category;
        try {
          category = categoriesProvider.categories.firstWhere(
            (c) => c.name == entry.key,
          );
        } catch (e) {
          category = null;
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
      } else {
        // Объединяем остальные категории в "Другое"
        final otherValue = data
            .skip(5)
            .fold<double>(0, (sum, entry) => sum + entry.value);

        if (otherValue > 0) {
          chartData.add(
            ChartSampleData(x: 'Другое', y: otherValue, color: Colors.grey),
          );
        }
        break;
      }
    }

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
            textStyle: TextStyle(color: Colors.white70, fontSize: 10),
            connectorLineSettings: ConnectorLineSettings(
              type: ConnectorType.line,
              color: Colors.white30,
            ),
            builder: (data, point, series, pointIndex, seriesIndex) {
              double percentage = (data.y / total) * 100;
              return percentage > 5
                  ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2935),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(color: data.color, fontSize: 10),
                    ),
                  )
                  : Container();
            },
          ),
          radius: '80%',
          innerRadius: '60%',
          explode: true,
          explodeOffset: '5%',
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
