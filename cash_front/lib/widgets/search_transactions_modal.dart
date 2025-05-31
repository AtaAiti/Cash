import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:intl/intl.dart';

class SearchTransactionsModal extends StatefulWidget {
  @override
  _SearchTransactionsModalState createState() =>
      _SearchTransactionsModalState();
}

class _SearchTransactionsModalState extends State<SearchTransactionsModal> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  int? _selectedCategoryIndex;
  String? _selectedAccount;
  String? _selectedCurrency;
  List<Transaction> _searchResults = [];
  bool _hasSearched = false;
  CategoriesProvider? categoriesProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    categoriesProvider = Provider.of<CategoriesProvider>(
      context,
      listen: false,
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final accountsProvider = Provider.of<AccountsProvider>(context);

    // Получаем списки для фильтров
    final categories = categoriesProvider?.categories ?? [];
    final accounts = accountsProvider.accounts;
    final currencies = accounts.map((acc) => acc.currency).toSet().toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Color(0xFF23222A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок (фиксированный)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 16),
                Text(
                  'Поиск транзакций',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Остальное содержимое (прокручиваемое)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Фильтры поиска
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Поиск по описанию
                        Text(
                          'Описание',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Введите описание...',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Color(0xFF2A2935),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Поиск по категории (выпадающий список)
                        Text(
                          'Категория',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2935),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int?>(
                            value: _selectedCategoryIndex,
                            isExpanded: true,
                            dropdownColor: Color(0xFF2A2935),
                            style: TextStyle(color: Colors.white),
                            hint: Text(
                              'Выберите категорию',
                              style: TextStyle(color: Colors.white54),
                            ),
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white54,
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'Все категории',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ...List.generate(
                                categories.length,
                                (index) => DropdownMenuItem<int?>(
                                  value: index,
                                  child: Text(
                                    categories[index].name,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryIndex = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Поиск по счету
                        Text(
                          'Счет',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2935),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedAccount,
                            isExpanded: true,
                            dropdownColor: Color(0xFF2A2935),
                            style: TextStyle(color: Colors.white),
                            hint: Text(
                              'Выберите счет',
                              style: TextStyle(color: Colors.white54),
                            ),
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white54,
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Все счета',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ...accounts
                                  .map(
                                    (account) => DropdownMenuItem<String>(
                                      value: account.id,
                                      child: Text(
                                        account.name,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedAccount = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Поиск по валюте
                        Text(
                          'Валюта',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2935),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            dropdownColor: Color(0xFF2A2935),
                            style: TextStyle(color: Colors.white),
                            hint: Text(
                              'Выберите валюту',
                              style: TextStyle(color: Colors.white54),
                            ),
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white54,
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Все валюты',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ...currencies
                                  .map(
                                    (currency) => DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(
                                        currency,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Поиск по сумме
                        Text(
                          'Сумма',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minAmountController,
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'От',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Color(0xFF2A2935),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxAmountController,
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'До',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Color(0xFF2A2935),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Кнопка поиска
                        ElevatedButton(
                          onPressed: () {
                            _search(transactionsProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5B6CF6),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Найти',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Результаты поиска (если есть)
                  if (_hasSearched)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Результаты поиска (${_searchResults.length})',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _searchResults.isEmpty
                            ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Ничего не найдено',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                            : Container(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true, // Важно для адаптивной высоты
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final tx = _searchResults[index];
                                  final category =
                                      categoriesProvider?.categories.firstWhere(
                                        (c) =>
                                            c.name ==
                                            (tx.category ?? 'Без категории'),
                                        orElse:
                                            () => Category(
                                              id: '',
                                              name:
                                                  tx.category ??
                                                  'Без категории',
                                              icon: Icons.category,
                                              color: Colors.grey,
                                              isExpense: tx.amount < 0,
                                            ),
                                      ) ??
                                      Category(
                                        id: '',
                                        name: tx.category ?? 'Без категории',
                                        icon: Icons.category,
                                        color: Colors.grey,
                                        isExpense: tx.amount < 0,
                                      );

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: category.color
                                          .withOpacity(0.2),
                                      child: Icon(
                                        category.icon,
                                        color: category.color,
                                      ),
                                    ),
                                    title: Text(
                                      '${tx.category}${tx.subcategory != null ? ' (${tx.subcategory})' : ''}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.account,
                                          style: TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                        if (tx.note != null &&
                                            tx.note!.isNotEmpty)
                                          Text(
                                            tx.note!,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Text(
                                      '${tx.amount.abs()} ${tx.currency}',
                                      style: TextStyle(
                                        color:
                                            tx.amount < 0
                                                ? Colors.pinkAccent
                                                : Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () {
                                      // Опционально: действие при нажатии на транзакцию
                                    },
                                  );
                                },
                              ),
                            ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _search(TransactionsProvider transactionsProvider) {
    // Получаем значения для поиска
    final description = _descriptionController.text.toLowerCase();
    final minAmountText = _minAmountController.text;
    final maxAmountText = _maxAmountController.text;
    double? minAmount, maxAmount;

    if (minAmountText.isNotEmpty) {
      minAmount = double.tryParse(minAmountText.replaceAll(',', '.'));
    }

    if (maxAmountText.isNotEmpty) {
      maxAmount = double.tryParse(maxAmountText.replaceAll(',', '.'));
    }

    // Выполняем поиск
    final results =
        transactionsProvider.transactions.where((tx) {
          // Фильтр по описанию
          if (description.isNotEmpty &&
              (tx.note == null ||
                  !tx.note!.toLowerCase().contains(description))) {
            return false;
          }

          // Фильтр по категории
          if (_selectedCategoryIndex != null) {
            final selectedCategory =
                categoriesProvider!.categories[_selectedCategoryIndex!].name;
            if (tx.category != selectedCategory) {
              return false;
            }
          }

          // Фильтр по счету
          if (_selectedAccount != null && tx.accountId != _selectedAccount) {
            return false;
          }

          // Фильтр по валюте
          if (_selectedCurrency != null && tx.currency != _selectedCurrency) {
            return false;
          }

          // Фильтр по диапазону сумм
          final absAmount = tx.amount.abs();
          if (minAmount != null && absAmount < minAmount) {
            return false;
          }
          if (maxAmount != null && absAmount > maxAmount) {
            return false;
          }

          // Фильтр по датам (будет добавлен позже)

          return true;
        }).toList();

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }
}
