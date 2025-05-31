import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/providers/currency_provider.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';

// Добавляем поддержку передачи подкатегорий:

class TransactionFormModal extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final bool isExpenseCategory;
  final List<String> subcategories; // Добавляем этот параметр
  final Function(Map<String, dynamic>) onSave;

  const TransactionFormModal({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.isExpenseCategory,
    this.subcategories = const [], // По умолчанию пустой список
    required this.onSave,
  }) : super(key: key);

  @override
  _TransactionFormModalState createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends State<TransactionFormModal> {
  // Значения по умолчанию
  String _accountId = '1'; // ID основного счета по умолчанию
  String _accountName = 'Карта';
  IconData _accountIcon = Icons.credit_card;
  Color _accountColor = Color(0xFFBFC6FF);

  String _amount = '0';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  late bool
  _isExpense; // Теперь зависит от категории, а не от выбора пользователя
  String _selectedSubcategory = '';
  List<String> _subcategories = [];
  String _selectedCurrency = '₽'; // Автоматически обновляется при выборе счета

  // Добавляем состояние для текущей операции
  String? _currentOperation;
  String? _firstOperand;

  @override
  void initState() {
    super.initState();
    // Устанавливаем тип транзакции на основе категории
    _isExpense = widget.isExpenseCategory;

    // Используем переданные подкатегории вместо хардкода
    _subcategories =
        widget.subcategories.isNotEmpty
            ? widget.subcategories
            : _generateDefaultSubcategories(); // Создаем подкатегории по умолчанию если не переданы

    if (_subcategories.isNotEmpty) {
      _selectedSubcategory = _subcategories[0];
    }

    // Устанавливаем основной счет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountsProvider = Provider.of<AccountsProvider>(
        context,
        listen: false,
      );
      final mainAccount = accountsProvider.getMainAccount();
      if (mainAccount != null) {
        setState(() {
          _accountId = mainAccount.id;
          _accountName = mainAccount.name;
          _accountIcon = mainAccount.icon;
          _accountColor = mainAccount.color;
          _selectedCurrency = mainAccount.currency;
        });
      }
    });
  }

  // Метод для генерации подкатегорий по умолчанию (если не были переданы)
  List<String> _generateDefaultSubcategories() {
    // Заполняем подкатегории в зависимости от категории - старый код
    switch (widget.categoryName) {
      case 'Кафе и фастфуд':
        return ['Фастфуд', 'Кафе', 'Ресторан'];
      case 'Продукты':
        return ['Продукты для дома', 'Перекус'];
      case 'Транспорт':
        return ['Такси', 'Электричка', 'Маршрутка', 'Автобус'];
      case 'Здоровье':
        return ['Лекарства', 'Приём врача'];
      default:
        return ['Основная'];
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_amount == '0') {
        _amount = digit;
      } else {
        _amount += digit;
      }
    });
  }

  void _appendDecimalPoint() {
    setState(() {
      if (!_amount.contains(',')) {
        _amount += ',';
      }
    });
  }

  void _deleteLastDigit() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _clearAmount() {
    setState(() {
      _amount = '0';
      _currentOperation = null;
      _firstOperand = null;
    });
  }

  // Метод для математических операций
  void _setOperation(String operation) {
    if (_currentOperation != null) {
      // Если операция уже была установлена, выполняем текущую операцию
      _performOperation();
    }

    setState(() {
      _firstOperand = _amount;
      _currentOperation = operation;
      _amount = '0';
    });
  }

  void _performOperation() {
    if (_firstOperand == null || _currentOperation == null) return;

    double firstValue =
        double.tryParse(_firstOperand!.replaceAll(',', '.')) ?? 0;
    double secondValue = double.tryParse(_amount.replaceAll(',', '.')) ?? 0;
    double result = 0;

    switch (_currentOperation) {
      case '+':
        result = firstValue + secondValue;
        break;
      case '-':
        result = firstValue - secondValue;
        break;
      case '×':
        result = firstValue * secondValue;
        break;
      case '÷':
        if (secondValue != 0) {
          result = firstValue / secondValue;
        } else {
          // Деление на ноль
          setState(() {
            _amount = 'Ошибка';
          });
          return;
        }
        break;
    }

    // Форматируем результат
    String resultStr = result.toString();
    if (resultStr.endsWith('.0')) {
      resultStr = resultStr.substring(0, resultStr.length - 2);
    }
    resultStr = resultStr.replaceAll('.', ',');

    setState(() {
      _amount = resultStr;
      _currentOperation = null;
      _firstOperand = null;
    });
  }

  // Отображаем диалог выбора счета
  void _showAccountSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Color(0xFF23222A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Выберите счёт',
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

              // Список счетов
              Expanded(
                child: Consumer<AccountsProvider>(
                  builder: (context, accountsProvider, _) {
                    final accounts = accountsProvider.accounts;
                    return ListView.builder(
                      itemCount: accounts.length,
                      itemBuilder: (ctx, i) {
                        final account = accounts[i];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: account.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              account.icon,
                              color: account.color,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${account.balance} ${account.currency}',
                            style: TextStyle(
                              color:
                                  account.balance >= 0
                                      ? Colors.tealAccent
                                      : Colors.pinkAccent,
                            ),
                          ),
                          trailing:
                              _accountId == account.id
                                  ? Icon(
                                    Icons.check_circle,
                                    color: account.color,
                                  )
                                  : null,
                          onTap: () {
                            setState(() {
                              _accountId = account.id;
                              _accountName = account.name;
                              _accountIcon = account.icon;
                              _accountColor = account.color;
                              _selectedCurrency =
                                  account
                                      .currency; // Устанавливается валюта счета
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Добавьте новый метод для выбора валюты
  void _showCurrencySelectionDialog() {
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

  Future<void> _submitTransaction() async {
    // Если есть незавершенная операция, выполняем её
    if (_currentOperation != null && _firstOperand != null) {
      _performOperation();
    }

    // Преобразуем сумму из строки в число
    double amount = double.tryParse(_amount.replaceAll(',', '.')) ?? 0;

    // Добавляем знак минус для расходов
    if (_isExpense) {
      amount = -amount;
    }

    // Получаем провайдеры и выводим отладочную информацию
    final accountsProvider = Provider.of<AccountsProvider>(
      context,
      listen: false,
    );
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );

    print('DEBUG: Available accounts: ${accountsProvider.accounts.length}');
    print('DEBUG: ID selected account: $_accountId');
    print(
      'DEBUG: List of account IDs: ${accountsProvider.accounts.map((a) => a.id).toList()}',
    );

    // Проверка наличия счета перед firstWhere
    if (!accountsProvider.accounts.any((acc) => acc.id == _accountId)) {
      print('ERROR: Invoice with ID $_accountId not found');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The account was not found. Please select a different account.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Получаем выбранный счет
    final selectedAccount = accountsProvider.accounts.firstWhere(
      (acc) => acc.id == _accountId,
    );

    print(
      'DEBUG: Selected account: ${selectedAccount.name}, currency: ${selectedAccount.currency}',
    );

    // Если валюта транзакции отличается от валюты счета, конвертируем
    double finalAmount = amount;
    if (_selectedCurrency != selectedAccount.currency) {
      // Конвертируем из валюты транзакции в валюту счета
      finalAmount = currencyProvider.convert(
        amount.abs(),
        _selectedCurrency,
        selectedAccount.currency,
      );

      // Возвращаем знак (для расходов - отрицательный)
      if (_isExpense) finalAmount = -finalAmount;
    }

    // Формируем объект транзакции с итоговой суммой
    final transaction = {
      'category': widget.categoryName,
      'subcategory': _selectedSubcategory,
      'amount': finalAmount, // Используем конвертированную сумму
      'accountId': _accountId,
      'account': _accountName,
      'currency':
          selectedAccount.currency, // Валюта всегда совпадает с валютой счета
      'date': _selectedDate,
      'note': _note,
    };

    // Синхронизируем категории перед созданием транзакции
    final categoriesProvider = Provider.of<CategoriesProvider>(
      context, 
      listen: false
    );
    await categoriesProvider.syncCategoriesToServer();

    // Добавляем транзакцию с обновлением баланса счета
    await transactionsProvider.addTransaction(transaction, accountsProvider);

    // Принудительно запрашиваем список транзакций с сервера
    await transactionsProvider.loadData();

    // Закрываем модальное окно
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Определяем цвет на основе типа транзакции
    final Color transactionColor =
        _isExpense ? Colors.pinkAccent : Colors.tealAccent;
    final Color backgroundTint =
        _isExpense
            ? widget.categoryColor.withOpacity(0.2)
            : Colors.teal.withOpacity(0.2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Color(0xFF23222A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок с информацией о типе транзакции
          Container(
            color: backgroundTint,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: transactionColor,
                ),
                SizedBox(width: 8),
                Text(
                  _isExpense ? 'Расход' : 'Доход',
                  style: TextStyle(
                    color: transactionColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Информация о счете и категории
          Container(
            padding: EdgeInsets.all(16),
            color: backgroundTint,
            child: Column(
              children: [
                // Строка с счётом
                Row(
                  children: [
                    Text(
                      'Со счёта',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showAccountSelectionDialog,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _accountColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  _accountIcon,
                                  color: _accountColor,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _accountName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Строка с категорией
                Row(
                  children: [
                    Text(
                      'На категорию',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: widget.categoryColor.withOpacity(
                                0.2,
                              ),
                              child: Icon(
                                widget.categoryIcon,
                                color: widget.categoryColor,
                                size: 20,
                              ),
                              radius: 14,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.categoryName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Подкатегории (если есть)
          if (_subcategories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children:
                    _subcategories
                        .map(
                          (subcat) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(subcat),
                              selected: _selectedSubcategory == subcat,
                              selectedColor: widget.categoryColor,
                              backgroundColor: Colors.grey[800],
                              labelStyle: TextStyle(
                                color:
                                    _selectedSubcategory == subcat
                                        ? Colors.black
                                        : Colors.white70,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSubcategory = subcat;
                                  });
                                }
                              },
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),

          // Поле для суммы
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExpense ? 'Расход' : 'Доход',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                if (_currentOperation != null)
                  Text(
                    ' ($_firstOperand $_currentOperation ?)',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _amount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: transactionColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: _showCurrencySelectionDialog,
                  child: Row(
                    children: [
                      Text(
                        _selectedCurrency,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: transactionColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: transactionColor),
                    ],
                  ),
                ),
                if (_selectedCurrency != _getCurrencyFromAccount())
                  Tooltip(
                    message:
                        'Будет конвертировано в ${_getCurrencyFromAccount()}',
                    child: Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.currency_exchange,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Добавьте под контейнером с суммой информационное сообщение о конвертации

          // После Container с суммой и валютой, добавьте:
          Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, _) {
              // Показываем только если валюты различаются
              if (_selectedCurrency != _getCurrencyFromAccount()) {
                double amount =
                    double.tryParse(_amount.replaceAll(',', '.')) ?? 0;
                double convertedAmount = currencyProvider.convert(
                  amount,
                  _selectedCurrency,
                  _getCurrencyFromAccount(),
                );

                return Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Будет записано: ${convertedAmount.toStringAsFixed(2)} ${_getCurrencyFromAccount()}',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          // Поле для заметок
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Заметки...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[850],
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                _note = value;
              },
            ),
          ),

          // Клавиатура с добавленными операциями (+, =)
          Expanded(
            child: Container(
              color: Colors.black12,
              child: Column(
                children: [
                  _buildKeyboardRow(['7', '8', '9', 'backspace']),
                  _buildKeyboardRow(['4', '5', '6', 'calendar']),
                  _buildKeyboardRow(['1', '2', '3', '×']),
                  _buildKeyboardRow(['0', ',', '+', '-']),
                  _buildKeyboardRow(['C', '÷', '=', 'save']),
                ],
              ),
            ),
          ),

          // Текущая дата
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Текущая дата: ${DateFormat('d MMM y').format(_selectedDate)} г.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Expanded(
      child: Row(
        children:
            keys.map((key) {
              // Специальные кнопки
              if (key == 'backspace') {
                return Expanded(
                  child: InkWell(
                    onTap: _deleteLastDigit,
                    child: Container(
                      height: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(0xFF292834),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.backspace, color: Colors.white70),
                    ),
                  ),
                );
              } else if (key == 'calendar') {
                return Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                    ),
                  ),
                );
              } else if (key == 'save') {
                return Expanded(
                  child: InkWell(
                    onTap: _submitTransaction,
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isExpense ? widget.categoryColor : Colors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                  ),
                );
              } else if (key == 'C') {
                return Expanded(
                  child: InkWell(
                    onTap: _clearAmount,
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'C',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (key == '+' ||
                  key == '-' ||
                  key == '×' ||
                  key == '÷' ||
                  key == '=') {
                // Кнопки математических операций
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (key == '=') {
                        _performOperation();
                      } else {
                        _setOperation(key);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            _currentOperation == key
                                ? (_isExpense
                                    ? widget.categoryColor
                                    : Colors.teal)
                                : Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            color:
                                _currentOperation == key
                                    ? Colors.white
                                    : Colors.white70,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // Обычные цифровые кнопки
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (key == ',') {
                        _appendDecimalPoint();
                      } else {
                        _appendDigit(key);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }).toList(),
      ),
    );
  }

  // Добавьте этот вспомогательный метод в класс _TransactionFormModalState

  String _getCurrencyFromAccount() {
    final accountsProvider = Provider.of<AccountsProvider>(
      context,
      listen: false,
    );

    try {
      final account = accountsProvider.accounts.firstWhere(
        (acc) => acc.id == _accountId,
      );
      return account.currency;
    } catch (e) {
      return '₽'; // По умолчанию рубли
    }
  }
}
