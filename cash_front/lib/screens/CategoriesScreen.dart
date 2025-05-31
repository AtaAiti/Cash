// Обновление AppBar для добавления навигации на EditCategoriesScreen и удаление кнопки добавления

import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/widgets/balance_app_bar.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/widgets/app_drawer.dart';
import 'package:cash_flip_app/widgets/transaction_form_modal.dart';
import 'package:cash_flip_app/screens/EditCategoriesScreen.dart'; // Добавлен импорт
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/providers/currency_provider.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _showExpenses = true;

  DateFilter _currentFilter = DateFilter(
    type: DateFilterType.month,
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final targetCurrency = currencyProvider.displayCurrency;

    // Получаем общие суммы по категориям
    final expenseTotals = transactionsProvider.getFilteredCategoryTotals(
      onlyExpenses: true,
      filter: _currentFilter,
    );
    final incomeTotals = transactionsProvider.getFilteredCategoryTotals(
      onlyExpenses: false,
      filter: _currentFilter,
    );

    // Общие суммы расходов и доходов
    final totalExpenses = expenseTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final totalIncome = incomeTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    return Scaffold(
      backgroundColor: Color(0xFF23222A),
      drawer: AppDrawer(),
      appBar: BalanceAppBar(
        title: 'Все счета',
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditCategoriesScreen()),
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
      body: _buildCategoriesList(
        transactionsProvider: transactionsProvider,
        currencyProvider: currencyProvider,
        targetCurrency: targetCurrency,
        totalExpenses: totalExpenses,
        totalIncome: totalIncome,
      ),
    );
  }

  Widget _buildCategoriesList({
    required TransactionsProvider transactionsProvider,
    required CurrencyProvider currencyProvider,
    required String targetCurrency,
    required double totalExpenses,
    required double totalIncome,
  }) {
    return Consumer<CategoriesProvider>(
      builder: (context, categoriesProvider, _) {
        // Правильная фильтрация категорий по типу
        final categories =
            _showExpenses
                ? categoriesProvider.categories
                    .where((c) => c.isExpense)
                    .toList()
                : categoriesProvider.categories
                    .where((c) => !c.isExpense)
                    .toList();

        print(
          'DEBUG: CategoriesScreen - Building UI with ${categories.length} ${_showExpenses ? "expense" : "income"} categories',
        );
        print(
          'DEBUG: CategoriesScreen - Total categories in provider: ${categoriesProvider.categories.length}',
        );
        print(
          'DEBUG: CategoriesScreen - Categories data: ${categories.map((c) => c.name).toList()}',
        );

        // Если идет загрузка, показываем индикатор загрузки
        if (categoriesProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Если список категорий пуст, показываем информативное сообщение
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'У вас пока нет категорий',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Нажмите + чтобы добавить новую категорию',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Верхние категории (первые 4)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children:
                      categories
                          .take(4)
                          .map(
                            (cat) => _catCircle(
                              context,
                              cat.name,
                              cat.icon,
                              cat.color,
                              '0 ₽',
                            ),
                          )
                          .toList(),
                ),
              ),
              // Центральный блок с круговой диаграммой и категориями по бокам
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левые категории
                    Expanded(
                      child: Column(
                        children:
                            categories.length > 4
                                ? categories
                                    .skip(4)
                                    .take(2)
                                    .map(
                                      (cat) => Column(
                                        children: [
                                          _catCircle(
                                            context,
                                            cat.name,
                                            cat.icon,
                                            cat.color,
                                            '0 ₽',
                                            small: true,
                                          ),
                                          SizedBox(height: 12),
                                        ],
                                      ),
                                    )
                                    .toList()
                                : [SizedBox()],
                      ),
                    ),
                    // Круговая диаграмма
                    GestureDetector(
                      onTap: _toggleCategoriesView,
                      child: Container(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 18,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _showExpenses ? Color(0xFF4FC3F7) : Colors.teal,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _showExpenses ? 'Расходы' : 'Доходы',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _showExpenses
                                      ? currencyProvider.formatAmount(
                                        totalExpenses,
                                        targetCurrency,
                                      )
                                      : currencyProvider.formatAmount(
                                        totalIncome,
                                        targetCurrency,
                                      ),
                                  style: TextStyle(
                                    color:
                                        _showExpenses
                                            ? Colors.pinkAccent
                                            : Colors.tealAccent,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _showExpenses
                                      ? currencyProvider.formatAmount(
                                        totalIncome,
                                        targetCurrency,
                                      )
                                      : currencyProvider.formatAmount(
                                        totalExpenses,
                                        targetCurrency,
                                      ),
                                  style: TextStyle(
                                    color:
                                        _showExpenses
                                            ? Colors.tealAccent
                                            : Colors.pinkAccent,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Правые категории
                    Expanded(
                      child: Column(
                        children:
                            categories.length > 6
                                ? categories
                                    .skip(6)
                                    .take(2)
                                    .map(
                                      (cat) => Column(
                                        children: [
                                          _catCircle(
                                            context,
                                            cat.name,
                                            cat.icon,
                                            cat.color,
                                            '0 ₽',
                                            small: true,
                                          ),
                                          SizedBox(height: 12),
                                        ],
                                      ),
                                    )
                                    .toList()
                                : [SizedBox()],
                      ),
                    ),
                  ],
                ),
              ),
              // Нижние категории
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children:
                      categories.length > 8
                          ? categories
                              .skip(8)
                              .take(4)
                              .map(
                                (cat) => _catCircle(
                                  context,
                                  cat.name,
                                  cat.icon,
                                  cat.color,
                                  '0 ₽',
                                ),
                              )
                              .toList()
                          : [],
                ),
              ),
              // Еще одна категория если осталась
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    categories.length > 12
                        ? _catCircle(
                          context,
                          categories[12].name,
                          categories[12].icon,
                          categories[12].color,
                          '0 ₽',
                        )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _toggleCategoriesView() {
    setState(() {
      _showExpenses = !_showExpenses;
    });
  }

  // Остальные методы без изменений
  Widget _catCircle(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String amount, {
    bool small = false,
  }) {
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final targetCurrency = currencyProvider.displayCurrency;

    // Получаем сумму для данной категории
    final categoryTotals =
        _showExpenses
            ? transactionsProvider.getFilteredCategoryTotals(
              onlyExpenses: true,
              filter: _currentFilter,
            )
            : transactionsProvider.getFilteredCategoryTotals(
              onlyExpenses: false,
              filter: _currentFilter,
            );

    final categoryAmount = categoryTotals[label] ?? 0.0;

    // Форматируем сумму с помощью currencyProvider
    final formattedAmount = currencyProvider.formatAmount(
      categoryAmount,
      targetCurrency,
    );

    return GestureDetector(
      onTap: () {
        _showTransactionModal(context, label, icon, color);
      },
      child: Column(
        children: [
          Container(
            width: small ? 48 : 64,
            height: small ? 48 : 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: small ? 26 : 32),
          ),
          SizedBox(height: 2),
          Text(
            formattedAmount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: small ? 13 : 15,
            ),
          ),
        ],
      ),
    );
  }

  // Модифицируем метод _showTransactionModal для поддержки подкатегорий

  void _showTransactionModal(
    BuildContext context,
    String categoryName,
    IconData icon,
    Color color,
  ) {
    // Определяем, является ли категория расходной или доходной
    bool isExpenseCategory = _showExpenses;

    // Находим категорию в провайдере для получения подкатегорий
    final categoriesProvider = Provider.of<CategoriesProvider>(
      context,
      listen: false,
    );

    List<String> subcategories = [];
    try {
      // Ищем категорию по имени
      final matchingCategories =
          categoriesProvider.categories
              .where((c) => c.name == categoryName)
              .toList();

      // Если категория найдена, получаем её подкатегории - используем ! безопасно
      if (matchingCategories.isNotEmpty) {
        subcategories = matchingCategories.first.subcategories;
      }
    } catch (e) {
      // В случае ошибки используем пустой список
      print('Ошибка при поиске категории: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TransactionFormModal(
            categoryName: categoryName,
            categoryIcon: icon,
            categoryColor: color,
            isExpenseCategory: isExpenseCategory,
            subcategories: subcategories, // Передаем подкатегории
            onSave: (transactionData) {
              // Код без изменений
            },
          ),
    );
  }
}
