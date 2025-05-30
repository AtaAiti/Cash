import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
// Обновим метод для открытия модального окна

// Добавим импорт в начало файла
import 'package:cash_flip_app/widgets/category_form_modal.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';

class EditCategoriesScreen extends StatefulWidget {
  @override
  State<EditCategoriesScreen> createState() => _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends State<EditCategoriesScreen> {
  bool isExpense = true;

  // Метод переключения между видами категорий
  void _toggleCategoriesView() {
    setState(() {
      isExpense = !isExpense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF23222A),
      appBar: AppBar(
        backgroundColor: Color(0xFF23222A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Изменить категории',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Consumer<CategoriesProvider>(
                builder: (context, categoriesProvider, _) {
                  final categories =
                      isExpense
                          ? categoriesProvider.expenseCategories
                          : categoriesProvider.incomeCategories;

                  // Разделим категории для разных частей экрана
                  final int totalCategories = categories.length;

                  return Column(
                    children: [
                      // Категории сверху - первые 4 или все, если их меньше 4
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children:
                              categories
                                  .take(4)
                                  .map(
                                    (cat) => _catCircle(
                                      cat.name,
                                      cat.icon,
                                      cat.color,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),

                      // Центральный блок с круговой диаграммой и категориями по бокам
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Левые категории
                            Expanded(
                              child: Column(
                                children:
                                    totalCategories > 4
                                        ? categories
                                            .skip(4)
                                            .take(2)
                                            .map(
                                              (cat) => Column(
                                                children: [
                                                  _catCircle(
                                                    cat.name,
                                                    cat.icon,
                                                    cat.color,
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
                                        isExpense
                                            ? Color(0xFF4FC3F7)
                                            : Colors.teal,
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isExpense ? 'Расходы' : 'Доходы',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          isExpense ? '0 ₽' : '0 ₽',
                                          style: TextStyle(
                                            color:
                                                isExpense
                                                    ? Colors.pinkAccent
                                                    : Colors.tealAccent,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isExpense ? '0 ₽' : '0 ₽',
                                          style: TextStyle(
                                            color:
                                                isExpense
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
                                    totalCategories > 6
                                        ? categories
                                            .skip(6)
                                            .take(2)
                                            .map(
                                              (cat) => Column(
                                                children: [
                                                  _catCircle(
                                                    cat.name,
                                                    cat.icon,
                                                    cat.color,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children:
                              totalCategories > 8
                                  ? categories
                                      .skip(8)
                                      .take(4)
                                      .map(
                                        (cat) => _catCircle(
                                          cat.name,
                                          cat.icon,
                                          cat.color,
                                        ),
                                      )
                                      .toList()
                                  : [],
                        ),
                      ),

                      // Кнопка добавления новой категории
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Отображаем еще одну категорию если осталась
                            totalCategories > 12
                                ? _catCircle(
                                  categories[12].name,
                                  categories[12].icon,
                                  categories[12].color,
                                )
                                : SizedBox.shrink(),

                            SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (context) => CategoryFormModal(
                                        isExpenseCategory: isExpense,
                                        onSave: (categoryData) {
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Категория обновлена!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                      ),
                                );
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white38,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Остальной код _catCircle не меняем

  Widget _catCircle(
    String label,
    IconData icon,
    Color color, {
    bool small = false,
  }) {
    // Получаем провайдер транзакций
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    // Создаем фильтр для текущего месяца
    final currentMonth = DateTime.now();
    final filter = DateFilter(
      type: DateFilterType.month,
      startDate: DateTime(currentMonth.year, currentMonth.month, 1),
      endDate: DateTime(currentMonth.year, currentMonth.month + 1, 0),
    );

    // Получаем сумму транзакций для категории
    final amount = transactionsProvider.getCategoryAmount(
      label,
      filter,
      isExpense: isExpense,
    );

    // Форматируем сумму
    final formattedAmount = '${amount.toStringAsFixed(0)} ₽';

    return GestureDetector(
      onTap: () {
        // Находим категорию в провайдере по её имени
        final categoriesProvider = Provider.of<CategoriesProvider>(
          context,
          listen: false,
        );
        // Общий шаблон
        Category? category;
        try {
          category = categoriesProvider.categories.firstWhere(
            (c) => c.name == label,
          );
        } catch (e) {
          category = null;
        }

        if (category != null) {
          // Безопасно используем свойства с оператором !
          final isExpense = category.isExpense;
          final id = category.id;
          final name = category.name;
          final icon = category.icon;
          final color = category.color;
          final subcategories = category.subcategories;

          // Остальной код
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder:
                (context) => CategoryFormModal(
                  isExpenseCategory: isExpense,
                  categoryId: id,
                  initialName: name,
                  initialIcon: icon,
                  initialColor: color,
                  initialSubcategories: subcategories,
                  onSave: (categoryData) {
                    setState(() {}); // <-- ВАЖНО!
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Категория обновлена!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
          );
        }
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
          SizedBox(height: 4),
          Container(
            width: small ? 60 : 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: small ? 12 : 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 2),
          Text(
            formattedAmount, // Используем реальную сумму
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
}
