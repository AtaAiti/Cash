import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/widgets/transaction_form_modal.dart';
import 'package:flutter/material.dart';
import 'package:cash_flip_app/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:intl/intl.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/widgets/search_transactions_modal.dart';
import 'package:cash_flip_app/widgets/transaction_details_modal.dart';
import 'package:cash_flip_app/widgets/date_selector.dart'; // Добавьте импорт
import 'package:cash_flip_app/widgets/balance_app_bar.dart';

class OperationsScreen extends StatefulWidget {
  @override
  _OperationsScreenState createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  DateFilter _currentFilter = DateFilter(
    type: DateFilterType.month,
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshTransactions();
      setState(() {}); // Принудительное обновление UI после загрузки
    });
  }

  Future<void> _refreshTransactions() async {
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
    await transactionsProvider.loadData();
  }

  Map<DateTime, List<Transaction>> _getFilteredTransactions(
    TransactionsProvider provider,
  ) {
    // Debug filter
    print(
      'DEBUG: Filter dates - start: ${_currentFilter.startDate}, end: ${_currentFilter.endDate}',
    );

    // Filter transactions based on date
    final filteredTransactions =
        provider.transactions.where((tx) {
          // Получаем только дату без времени
          final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
          final startDate = DateTime(
            _currentFilter.startDate!.year,
            _currentFilter.startDate!.month,
            _currentFilter.startDate!.day,
          );
          final endDate = DateTime(
            _currentFilter.endDate!.year,
            _currentFilter.endDate!.month,
            _currentFilter.endDate!.day,
          );

          // Debug
          print(
            'DEBUG: Checking tx date ${txDate} against filter ${startDate} - ${endDate}',
          );

          // Включаем все транзакции от начальной даты до конечной даты включительно
          return txDate.isAtSameMomentAs(startDate) ||
              (txDate.isAfter(startDate) &&
                  (txDate.isBefore(endDate) ||
                      txDate.isAtSameMomentAs(endDate)));
        }).toList();

    print(
      'DEBUG: Manually filtered ${filteredTransactions.length} transactions',
    );

    // Group by day
    final grouped = <DateTime, List<Transaction>>{};
    for (var tx in filteredTransactions) {
      // Create a date with just year, month, and day (no time)
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF23222A),
      drawer: AppDrawer(),
      appBar: BalanceAppBar(
        title: 'Все счета',
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SearchTransactionsModal(),
              );
            },
          ),
        ],
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TransactionsProvider>(
              builder: (ctx, transactionsProvider, _) {
                // Добавьте отладочный вывод
                print(
                  'DEBUG: Всего транзакций: ${transactionsProvider.transactions.length}',
                );
                for (var tx in transactionsProvider.transactions) {
                  print(
                    'DEBUG: Транзакция ${tx.id}: ${tx.amount} ${tx.currency}, категория: ${tx.category}',
                  );
                }

                final groupedTransactions = _getFilteredTransactions(
                  transactionsProvider,
                );

                // Добавим отладочный вывод для проверки группировки
                print('DEBUG: Группировка транзакций по дням:');
                print(
                  'DEBUG: Количество дней: ${groupedTransactions.keys.length}',
                );
                for (var dateKey in groupedTransactions.keys) {
                  print(
                    'DEBUG: День $dateKey: ${groupedTransactions[dateKey]?.length} транзакций',
                  );
                }

                if (groupedTransactions.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет транзакций за этот период',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }

                final sortedDates =
                    groupedTransactions.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  itemCount: sortedDates.length,
                  separatorBuilder:
                      (_, __) => Divider(color: Colors.white12, height: 0),
                  itemBuilder: (context, i) {
                    final dateKey = sortedDates[i];
                    final dayTransactions = groupedTransactions[dateKey]!;

                    // Анализируем первую транзакцию в группе для получения даты
                    final date = dayTransactions.first.date;
                    final isToday = _isToday(date);
                    final isYesterday = _isYesterday(date);

                    String displayDay = date.day.toString();
                    String displayWeekday =
                        isToday
                            ? 'СЕГОДНЯ'
                            : isYesterday
                            ? 'ВЧЕРА'
                            : DateFormat(
                              'EEEE',
                              'ru_RU',
                            ).format(date).toUpperCase();
                    String displayMonth =
                        DateFormat.MMMM(
                          'ru',
                        ).format(DateTime.now()).toUpperCase();
                    String displayYear = DateFormat.y(
                      'ru',
                    ).format(DateTime.now());
                    String formattedMonthYear = '$displayMonth $displayYear';

                    return _daySection(
                      context,
                      displayDay,
                      displayWeekday,
                      formattedMonthYear,
                      dayTransactions,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Widget _daySection(
    BuildContext context,
    String date,
    String weekday,
    String month,
    List<Transaction> transactions,
  ) {
    // Расчет суммы транзакций за день
    final totalAmount = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                date,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  Text(
                    month,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              Spacer(),
              Text(
                '${totalAmount.abs().toStringAsFixed(0)} ₽',
                style: TextStyle(
                  color:
                      totalAmount < 0 ? Colors.pinkAccent : Colors.tealAccent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...transactions
              .map((tx) => _transactionTile(tx, context: context))
              .toList(),
        ],
      ),
    );
  }

  Widget _transactionTile(Transaction tx, {required BuildContext context}) {
    // Определяем иконку и цвет в зависимости от категории
    late IconData icon;
    late Color iconColor;

    // Получаем провайдер категорий для поиска соответствующей категории
    final categoriesProvider = Provider.of<CategoriesProvider>(
      context,
      listen: false,
    );

    // Ищем категорию по имени
    String? categoryName = tx.category;
    Category? category;
    if (tx.category != null) {
      try {
        category = categoriesProvider.categories.firstWhere(
          (c) => c.name == tx.category!, // Добавляем оператор ! здесь
        );
      } catch (e) {
        category = null;
      }
    }

    if (category != null) {
      // Инициализируем icon и iconColor внутри блока if
      icon = category.icon;
      iconColor = category.color;

      // Другие переменные не используются в этом методе, их можно удалить
      // или оставить для будущего использования
      final isExpense = category.isExpense;
      final id = category.id;
      final name = category.name;
      final subcategories = category.subcategories;
    } else {
      // Значения по умолчанию, используемые если категория не найдена
      switch (tx.category) {
        case 'Продукты':
          icon = Icons.shopping_basket;
          iconColor = Colors.blueAccent;
          break;
        case 'Кафе и фастфуд':
          icon = Icons.fastfood;
          iconColor = Colors.deepPurpleAccent;
          break;
        case 'Транспорт':
          icon = Icons.directions_bus;
          iconColor = Colors.orangeAccent;
          break;
        case 'Здоровье':
          icon = Icons.volunteer_activism;
          iconColor = Colors.green;
          break;
        default:
          icon = Icons.category;
          iconColor = Colors.grey;
      }
    }

    // Формируем строку категории с подкатегорией (если есть)
    String categoryText = tx.category ?? 'Без категории';
    if (tx.subcategory != null && tx.subcategory!.isNotEmpty) {
      categoryText += ' (${tx.subcategory})';
    }

    return GestureDetector(
      onTap: () {
        // Открываем модальное окно с деталями транзакции
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TransactionDetailsModal(transaction: tx),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryText,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.white38, size: 16),
                      SizedBox(width: 4),
                      Text(
                        tx.account,
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Text(
                      tx.note!,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Text(
              '${tx.amount.abs()} ₽',
              style: TextStyle(
                color: tx.amount < 0 ? Colors.pinkAccent : Colors.tealAccent,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
