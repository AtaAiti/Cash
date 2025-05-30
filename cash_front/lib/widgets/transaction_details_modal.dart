import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:intl/intl.dart';
import 'package:cash_flip_app/providers/currency_provider.dart';

class TransactionDetailsModal extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsModal({Key? key, required this.transaction})
    : super(key: key);

  @override
  _TransactionDetailsModalState createState() =>
      _TransactionDetailsModalState();
}

class _TransactionDetailsModalState extends State<TransactionDetailsModal> {
  late TextEditingController _noteController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCategoryId;
  late String? _selectedSubcategory;
  late String _selectedAccountId;
  late String _selectedCurrency;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.transaction.note ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction.amount.abs().toStringAsFixed(2),
    );
    _selectedDate = widget.transaction.date;
    _selectedCategoryId = '';
    _selectedSubcategory = widget.transaction.subcategory;
    _selectedAccountId = widget.transaction.accountId;
    _selectedCurrency =
        widget.transaction.currency; // Инициализируем валюту транзакции
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Инициализируем категорию после доступа к провайдеру
    final categoriesProvider = Provider.of<CategoriesProvider>(
      context,
      listen: false,
    );
    try {
      final category = categoriesProvider.categories.firstWhere(
        (c) => c.name == widget.transaction.category,
      );
      _selectedCategoryId = category.id;
    } catch (e) {
      // Если категория не найдена, оставляем пустой ID
      _selectedCategoryId = '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    final accountsProvider = Provider.of<AccountsProvider>(context);

    // Находим категорию
    Category? category;
    try {
      category = categoriesProvider.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
      );
    } catch (e) {
      try {
        category = categoriesProvider.categories.firstWhere(
          (c) => c.name == widget.transaction.category,
        );
        _selectedCategoryId = category.id;
      } catch (e) {
        category = null;
      }
    }

    // Находим счет
    Account? account;
    try {
      account = accountsProvider.accounts.firstWhere(
        (a) => a.id == _selectedAccountId,
      );
    } catch (e) {
      try {
        account = accountsProvider.accounts.firstWhere(
          (a) => a.id == widget.transaction.accountId,
        );
        _selectedAccountId = account.id;
      } catch (e) {
        account = null;
      }
    }

    final isExpense = widget.transaction.amount < 0;
    final typeColor = isExpense ? Colors.pinkAccent : Colors.tealAccent;

    // Получаем доступные подкатегории для выбранной категории
    List<String> availableSubcategories = [];
    if (category != null) {
      availableSubcategories = category.subcategories;
    }

    // Если выбранной подкатегории нет в списке доступных, сбрасываем выбор
    if (_selectedSubcategory != null &&
        !availableSubcategories.contains(_selectedSubcategory)) {
      _selectedSubcategory =
          availableSubcategories.isNotEmpty
              ? availableSubcategories.first
              : null;
    }

    final amountWithSign =
        isExpense
            ? '${widget.transaction.amount.toStringAsFixed(2)}'
            : '+${widget.transaction.amount.toStringAsFixed(2)}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFF23222A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок модального окна
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (category?.color ?? Colors.grey).withOpacity(0.2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Детали транзакции',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Кнопка редактирования/сохранения
                _isEditing
                    ? IconButton(
                      icon: Icon(Icons.check, color: Colors.white),
                      onPressed:
                          () => _saveChanges(
                            transactionsProvider,
                            accountsProvider,
                            categoriesProvider,
                          ),
                    )
                    : IconButton(
                      icon: Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                // Кнопка удаления
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed:
                      () => _confirmDelete(
                        context,
                        transactionsProvider,
                        accountsProvider,
                      ),
                ),
              ],
            ),
          ),

          // Основная информация
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Сумма и тип транзакции
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: (category?.color ?? Colors.grey)
                              .withOpacity(0.2),
                          child: Icon(
                            category?.icon ??
                                (isExpense
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward),
                            color: category?.color ?? typeColor,
                            size: 40,
                          ),
                        ),
                        SizedBox(height: 16),
                        _isEditing
                            ? Container(
                              width: 200,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  // Поле ввода суммы
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _amountController,
                                          style: TextStyle(
                                            color:
                                                isExpense
                                                    ? Colors.pinkAccent
                                                    : Colors.tealAccent,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: Color(0xFF2A2935),
                                            prefixIcon: Icon(
                                              isExpense
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color:
                                                  isExpense
                                                      ? Colors.pinkAccent
                                                      : Colors.tealAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      // Кнопка выбора валюты
                                      GestureDetector(
                                        onTap:
                                            () => _showCurrencySelectionDialog(
                                              context,
                                            ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _selectedCurrency,
                                              style: TextStyle(
                                                color:
                                                    isExpense
                                                        ? Colors.pinkAccent
                                                        : Colors.tealAccent,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color:
                                                  isExpense
                                                      ? Colors.pinkAccent
                                                      : Colors.tealAccent,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Отображаем сообщение о конвертации, если валюты различаются
                                  if (_selectedCurrency !=
                                      _getCurrencyFromAccount(context))
                                    Consumer<CurrencyProvider>(
                                      builder: (context, currencyProvider, _) {
                                        double amount =
                                            double.tryParse(
                                              _amountController.text.replaceAll(
                                                ',',
                                                '.',
                                              ),
                                            ) ??
                                            0;
                                        double convertedAmount =
                                            currencyProvider.convert(
                                              amount,
                                              _selectedCurrency,
                                              _getCurrencyFromAccount(context),
                                            );

                                        return Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.currency_exchange,
                                                color: Colors.white54,
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Будет записано: ${convertedAmount.toStringAsFixed(2)} ${_getCurrencyFromAccount(context)}',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            )
                            : Text(
                              amountWithSign +
                                  ' ' +
                                  widget.transaction.currency,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        SizedBox(height: 8),
                        !_isEditing
                            ? Text(
                              isExpense ? 'Расход' : 'Доход',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            )
                            : SizedBox(),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Категория с возможностью редактирования
                  _isEditing
                      ? _buildCategorySelector(categoriesProvider, isExpense)
                      : _buildDetailRow(
                        'Категория',
                        '${widget.transaction.category}${widget.transaction.subcategory != null ? ' (${widget.transaction.subcategory})' : ''}',
                        icon: category?.icon ?? Icons.category,
                        iconColor: category?.color ?? Colors.grey,
                      ),

                  // Подкатегория с возможностью редактирования
                  _isEditing &&
                          category != null &&
                          category.subcategories.isNotEmpty
                      ? _buildSubcategorySelector(category.subcategories)
                      : SizedBox(),

                  // Счет с возможностью редактирования
                  _isEditing
                      ? _buildAccountSelector(accountsProvider)
                      : _buildDetailRow(
                        'Счет',
                        widget.transaction.account,
                        icon: account?.icon ?? Icons.account_balance_wallet,
                        iconColor: account?.color ?? Colors.blue,
                      ),

                  // Дата с возможностью редактирования
                  _buildDateRow(context),

                  // Примечание с возможностью редактирования
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.note, color: Colors.grey),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Примечание',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              _isEditing
                                  ? TextField(
                                    controller: _noteController,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Добавьте примечание...',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFF2A2935),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    minLines: 2,
                                    maxLines: 5,
                                  )
                                  : Text(
                                    widget.transaction.note?.isNotEmpty == true
                                        ? widget.transaction.note!
                                        : 'Нет примечания',
                                    style: TextStyle(
                                      color:
                                          widget.transaction.note?.isNotEmpty ==
                                                  true
                                              ? Colors.white
                                              : Colors.white38,
                                      fontStyle:
                                          widget.transaction.note?.isNotEmpty ==
                                                  true
                                              ? FontStyle.normal
                                              : FontStyle.italic,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    CategoriesProvider categoriesProvider,
    bool isExpense,
  ) {
    // Получаем список категорий подходящего типа
    final availableCategories =
        isExpense
            ? categoriesProvider.expenseCategories
            : categoriesProvider.incomeCategories;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категория',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF2A2935),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
              isExpanded: true,
              dropdownColor: Color(0xFF2A2935),
              hint: Text(
                'Выберите категорию',
                style: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white54),
              items:
                  availableCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 20),
                          SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value ?? '';
                  // При смене категории сбрасываем подкатегорию
                  _selectedSubcategory = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategorySelector(List<String> subcategories) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Подкатегория',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF2A2935),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedSubcategory,
              isExpanded: true,
              dropdownColor: Color(0xFF2A2935),
              hint: Text(
                'Выберите подкатегорию (не обязательно)',
                style: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white54),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Без подкатегории'),
                ),
                ...subcategories.map((subcat) {
                  return DropdownMenuItem<String>(
                    value: subcat,
                    child: Text(subcat),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubcategory = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector(AccountsProvider accountsProvider) {
    final accounts = accountsProvider.accounts;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Счет', style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF2A2935),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedAccountId,
              isExpanded: true,
              dropdownColor: Color(0xFF2A2935),
              hint: Text(
                'Выберите счет',
                style: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white54),
              items:
                  accounts.map((account) {
                    return DropdownMenuItem<String>(
                      value: account.id,
                      child: Row(
                        children: [
                          Icon(account.icon, color: account.color, size: 20),
                          SizedBox(width: 12),
                          Text('${account.name} (${account.currency})'),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAccountId = value;

                    // Если валюта ввода была равна валюте предыдущего счета,
                    // автоматически меняем ее на валюту нового счета
                    final oldCurrency = _getCurrencyFromAccount(context);
                    if (_selectedCurrency == oldCurrency) {
                      _selectedCurrency = oldCurrency;
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today, color: Colors.deepPurple),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Дата',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              _isEditing
                  ? GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2935),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy').format(_selectedDate),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down, color: Colors.white54),
                        ],
                      ),
                    ),
                  )
                  : Text(
                    DateFormat('dd MMMM yyyy', 'ru_RU').format(_selectedDate),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 1)),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges(
    TransactionsProvider transactionsProvider,
    AccountsProvider accountsProvider,
    CategoriesProvider categoriesProvider,
  ) {
    // Проверка валидности данных
    if (_selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выберите категорию'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAccountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Выберите счет'), backgroundColor: Colors.red),
      );
      return;
    }

    double? amount;
    try {
      amount = double.parse(_amountController.text.replaceAll(',', '.'));
      if (amount <= 0) {
        throw FormatException('Amount must be positive');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введите корректную сумму'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Получаем категорию и счет
    final category = categoriesProvider.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
    );

    final account = accountsProvider.accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
    );

    // Знак суммы зависит от типа категории (расход/доход)
    final isExpense = widget.transaction.amount < 0;

    // Получаем CurrencyProvider для конвертации валют
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );

    // Применяем конвертацию, если валюта ввода отличается от валюты счета
    double finalAmount = amount;
    if (_selectedCurrency != account.currency) {
      finalAmount = currencyProvider.convert(
        amount,
        _selectedCurrency,
        account.currency,
      );
    }

    // Применяем знак (для расходов - отрицательный)
    final signedAmount = isExpense ? -finalAmount : finalAmount;

    // Определяем, менялся ли счет
    final isAccountChanged = _selectedAccountId != widget.transaction.accountId;

    // Получаем старый счет, если счет был изменен
    Account? oldAccount;
    if (isAccountChanged) {
      try {
        oldAccount = accountsProvider.accounts.firstWhere(
          (a) => a.id == widget.transaction.accountId,
        );
      } catch (e) {
        oldAccount = null;
      }
    }

    // Создаем обновленную транзакцию
    final updatedTransaction = Transaction(
      id: widget.transaction.id,
      category: category.name,
      subcategory: _selectedSubcategory,
      amount: signedAmount,
      account: account.name,
      accountId: account.id,
      currency: account.currency,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    // Особая обработка, если изменился счет
    if (isAccountChanged && oldAccount != null) {
      // 1. Возвращаем сумму на старый счет
      final updatedOldAccount = Account(
        id: oldAccount.id,
        name: oldAccount.name,
        accountType: oldAccount.accountType,
        balance:
            oldAccount.balance -
            widget.transaction.amount, // Отменяем старую транзакцию
        currency: oldAccount.currency,
        icon: oldAccount.icon,
        color: oldAccount.color,
        isMain: oldAccount.isMain,
      );

      // 2. Снимаем сумму с нового счета
      final updatedNewAccount = Account(
        id: account.id,
        name: account.name,
        accountType: account.accountType,
        balance: account.balance + signedAmount, // Добавляем новую транзакцию
        currency: account.currency,
        icon: account.icon,
        color: account.color,
        isMain: account.isMain,
      );

      // Обновляем оба счета
      accountsProvider.updateAccount(updatedOldAccount);
      accountsProvider.updateAccount(updatedNewAccount);

      // Обновляем транзакцию
      transactionsProvider.updateTransaction(
        widget.transaction,
        updatedTransaction,
        accountsProvider,
      );
    } else {
      // Если счет не менялся, обновляем только сумму (разницу)
      final amountDifference = signedAmount - widget.transaction.amount;

      // Обновляем баланс счета
      final updatedAccount = Account(
        id: account.id,
        name: account.name,
        accountType: account.accountType,
        balance: account.balance + amountDifference, // Добавляем только разницу
        currency: account.currency,
        icon: account.icon,
        color: account.color,
        isMain: account.isMain,
      );

      accountsProvider.updateAccount(updatedAccount);

      // Обновляем транзакцию
      transactionsProvider.updateTransaction(
        widget.transaction,
        updatedTransaction,
        accountsProvider,
      );
    }

    // Закрываем режим редактирования и показываем сообщение
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Транзакция обновлена'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionsProvider transactionsProvider,
    AccountsProvider accountsProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2935),
          title: Text(
            'Удалить транзакцию?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Вы действительно хотите удалить эту транзакцию? Это действие нельзя отменить.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                transactionsProvider.deleteTransaction(
                  widget.transaction.id,
                  accountsProvider,
                );
                Navigator.pop(context); // Закрываем диалог
                Navigator.pop(context); // Закрываем модальное окно

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Транзакция удалена'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _getCurrencyFromAccount(BuildContext context) {
    final accountsProvider = Provider.of<AccountsProvider>(
      context,
      listen: false,
    );
    try {
      final account = accountsProvider.accounts.firstWhere(
        (acc) => acc.id == _selectedAccountId,
      );
      return account.currency;
    } catch (e) {
      return '₽'; // По умолчанию рубли
    }
  }

  void _showCurrencySelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final availableCurrencies = {
          '₽': 'Российский рубль — ₽',
          '\$': 'Доллар США — \$',
          '€': 'Евро — €',
          '£': 'Фунт стерлингов — £',
          '¥': 'Японская йена — ¥',
        };

        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF23222A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Выберите валюту',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
              Expanded(
                child: ListView(
                  children:
                      availableCurrencies.entries.map((entry) {
                        final symbol = entry.key;
                        final name = entry.value;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing:
                              _selectedCurrency == symbol
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF5B6CF6),
                                  )
                                  : null,
                          selected: _selectedCurrency == symbol,
                          selectedTileColor: Colors.white10,
                          onTap: () {
                            setState(() {
                              _selectedCurrency = symbol;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
