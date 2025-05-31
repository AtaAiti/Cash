import 'dart:convert';
import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';
import 'package:cash_flip_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final String? category; // Теперь может быть null
  final String? subcategory; // Теперь может быть null
  final double amount;
  final String account;
  final String accountId;
  final String currency;
  final DateTime date;
  final String? note;

  Transaction({
    required this.id,
    this.category, // Опциональный параметр
    this.subcategory, // Опциональный параметр
    required this.amount,
    required this.account,
    required this.accountId,
    required this.currency,
    required this.date,
    this.note,
  });

  // Конвертация в Map для API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'account': account,
      'accountId': accountId,
      'currency': currency,
      'date': date.millisecondsSinceEpoch, // Изменено с date.toIso8601String()
      'note': note,
    };
  }

  // Создание объекта из Map, полученного от API
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      category: json['category'], // Может быть null
      subcategory: json['subcategory'], // Может быть null
      amount: double.parse(json['amount'].toString()),
      account: json['account'],
      accountId: json['accountId'].toString(),
      currency: json['currency'],
      date:
          json['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['date'])
              : (json['date'] is String
                  ? DateTime.parse(json['date'])
                  : DateTime.now()),
      note: json['note'],
    );
  }
}

class TransactionsProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => [..._transactions];
  List<Transaction> get expenseTransactions =>
      _transactions.where((tx) => tx.amount < 0).toList();
  List<Transaction> get incomeTransactions =>
      _transactions.where((tx) => tx.amount > 0).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Загрузка транзакций с сервера
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Сначала пробуем загрузить с сервера
      final transactionsData = await _apiService.getTransactions();

      if (transactionsData.isNotEmpty) {
        _transactions =
            transactionsData
                .map<Transaction>((json) => Transaction.fromJson(json))
                .toList();
        // Сортируем по дате (новые сверху)
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      } else {
        // Если с сервера данных нет, используем локальные
        await _loadLocalData();
      }
    } catch (e) {
      print('Error loading transactions from API: $e');
      _error = 'Failed to load transactions from server';
      // Если ошибка API, используем локальные данные
      await _loadLocalData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Загрузка локальных данных
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('transactions_data');

      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _transactions =
            decoded
                .map(
                  (item) => Transaction(
                    id: item['id'],
                    category: item['category'],
                    subcategory: item['subcategory'],
                    amount: item['amount'],
                    account: item['account'],
                    accountId: item['accountId'],
                    currency: item['currency'],
                    date:
                        item['date'] is int
                            ? DateTime.fromMillisecondsSinceEpoch(item['date'])
                            : DateTime.parse(item['date']),
                    note: item['note'],
                  ),
                )
                .toList();

        // Сортируем по дате
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      print('Error loading local transactions data: $e');
    }
  }

  // Сохранение данных локально
  Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(
        _transactions
            .map(
              (tx) => {
                'id': tx.id,
                'category': tx.category,
                'subcategory': tx.subcategory,
                'amount': tx.amount,
                'account': tx.account,
                'accountId': tx.accountId,
                'currency': tx.currency,
                'date':
                    tx
                        .date
                        .millisecondsSinceEpoch, // Изменить с toIso8601String() на millisecondsSinceEpoch
                'note': tx.note,
              },
            )
            .toList(),
      );

      await prefs.setString('transactions_data', jsonData);
    } catch (e) {
      print('Error saving local transactions data: $e');
    }
  }

  // Добавление транзакции
  Future<void> addTransaction(
    Map<String, dynamic> transactionData,
    AccountsProvider accountsProvider,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Отправляем на сервер
      final result = await _apiService.createTransaction(transactionData);

      if (result != null) {
        // Добавляем в локальный список
        final newTransaction = Transaction.fromJson(result);
        _transactions.add(newTransaction);

        // Сортируем транзакции по дате
        _transactions.sort((a, b) => b.date.compareTo(a.date));

        // Запрашиваем обновленные данные счетов
        await accountsProvider.loadData();
      }
    } catch (e) {
      print("ERROR: Не удалось добавить транзакцию: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  // Обновление баланса счета после добавления транзакции
  void _updateAccountBalance(
    Transaction transaction,
    AccountsProvider accountsProvider,
  ) {
    print(
      'DEBUG: Updating the balance for a transaction: ${transaction.id}, account: ${transaction.accountId}',
    );

    // Проверка наличия счета
    if (!accountsProvider.accounts.any((a) => a.id == transaction.accountId)) {
      print(
        'ERROR: Invoice with ID ${transaction.accountId} not found in the list of accounts',
      );
      return;
    }

    // Находим связанный счет
    Account? account;
    try {
      account = accountsProvider.accounts.firstWhere(
        (a) => a.id == transaction.accountId,
      );
      print(
        'DEBUG: Account found: ${account.name}, current balance: ${account.balance}',
      );
    } catch (e) {
      print('ERROR: Account not found: ${transaction.accountId}, error: $e');
      return;
    }

    // Обновляем счет
    final updatedAccount = Account(
      id: account.id,
      name: account.name,
      accountType: account.accountType,
      balance: account.balance + transaction.amount,
      currency: account.currency,
      icon: account.icon,
      color: account.color,
      isMain: account.isMain,
    );

    print('DEBUG: Updated balance sheet: ${updatedAccount.balance}');
    accountsProvider.updateAccount(updatedAccount);
  }

  // Удаление транзакции
  Future<void> deleteTransaction(
    String transactionId,
    AccountsProvider accountsProvider,
  ) async {
    _isLoading = true;
    notifyListeners();

    // Находим транзакцию перед удалением
    final transaction = _transactions.firstWhere(
      (tx) => tx.id == transactionId,
    );

    try {
      // Удаляем на сервере
      final success = await _apiService.deleteTransaction(transactionId);

      // Удаляем локально в любом случае
      _transactions.removeWhere((tx) => tx.id == transactionId);

      // Обновляем баланс счета (вычитаем сумму транзакции)
      _revertAccountBalance(transaction, accountsProvider);
    } catch (e) {
      print('Error deleting transaction from API: $e');
      // При ошибке удаляем только локально
      _transactions.removeWhere((tx) => tx.id == transactionId);

      // Обновляем баланс счета (вычитаем сумму транзакции)
      _revertAccountBalance(transaction, accountsProvider);
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  // Возврат баланса счета после удаления транзакции
  void _revertAccountBalance(
    Transaction transaction,
    AccountsProvider accountsProvider,
  ) {
    // Находим связанный счет
    Account? account;
    try {
      account = accountsProvider.accounts.firstWhere(
        (a) => a.id == transaction.accountId,
      );
    } catch (e) {
      print('Account not found: ${transaction.accountId}');
      return;
    }

    // Обновляем счет (вычитаем сумму транзакции)
    final updatedAccount = Account(
      id: account.id,
      name: account.name,
      accountType: account.accountType,
      balance: account.balance - transaction.amount,
      currency: account.currency,
      icon: account.icon,
      color: account.color,
      isMain: account.isMain,
    );

    accountsProvider.updateAccount(updatedAccount);
  }

  // Обновление транзакции
  Future<void> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
    AccountsProvider accountsProvider,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Обновляем на сервере
      final result = await _apiService.updateTransaction(
        newTransaction.id,
        newTransaction.toJson(),
      );

      // Находим индекс старой транзакции
      final index = _transactions.indexWhere(
        (tx) => tx.id == oldTransaction.id,
      );

      if (index != -1) {
        // Обновляем транзакцию в списке
        _transactions[index] = newTransaction;

        // Обновляем баланс счета
        _updateAccountBalanceOnEdit(
          oldTransaction,
          newTransaction,
          accountsProvider,
        );

        // Сортируем транзакции по дате
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      print('Error updating transaction on API: $e');
      // При ошибке обновляем только локально
      final index = _transactions.indexWhere(
        (tx) => tx.id == oldTransaction.id,
      );

      if (index != -1) {
        // Обновляем транзакцию в списке
        _transactions[index] = newTransaction;

        // Обновляем баланс счета
        _updateAccountBalanceOnEdit(
          oldTransaction,
          newTransaction,
          accountsProvider,
        );

        // Сортируем транзакции по дате
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  // Обновление баланса счета при редактировании транзакции
  void _updateAccountBalanceOnEdit(
    Transaction oldTransaction,
    Transaction newTransaction,
    AccountsProvider accountsProvider,
  ) {
    // Если счет не менялся
    if (oldTransaction.accountId == newTransaction.accountId) {
      // Получаем счет
      Account? account;
      try {
        account = accountsProvider.accounts.firstWhere(
          (a) => a.id == oldTransaction.accountId,
        );
      } catch (e) {
        print('Account not found: ${oldTransaction.accountId}');
        return;
      }

      // Обновляем баланс (вычитаем старую сумму, добавляем новую)
      final updatedAccount = Account(
        id: account.id,
        name: account.name,
        accountType: account.accountType,
        balance:
            account.balance - oldTransaction.amount + newTransaction.amount,
        currency: account.currency,
        icon: account.icon,
        color: account.color,
        isMain: account.isMain,
      );

      accountsProvider.updateAccount(updatedAccount);
    } else {
      // Если счет менялся, обновляем оба счета

      // Получаем старый счет
      Account? oldAccount;
      try {
        oldAccount = accountsProvider.accounts.firstWhere(
          (a) => a.id == oldTransaction.accountId,
        );
      } catch (e) {
        print('Old account not found: ${oldTransaction.accountId}');
        return;
      }

      // Получаем новый счет
      Account? newAccount;
      try {
        newAccount = accountsProvider.accounts.firstWhere(
          (a) => a.id == newTransaction.accountId,
        );
      } catch (e) {
        print('New account not found: ${newTransaction.accountId}');
        return;
      }

      // Обновляем старый счет (вычитаем старую сумму)
      final updatedOldAccount = Account(
        id: oldAccount.id,
        name: oldAccount.name,
        accountType: oldAccount.accountType,
        balance: oldAccount.balance - oldTransaction.amount,
        currency: oldAccount.currency,
        icon: oldAccount.icon,
        color: oldAccount.color,
        isMain: oldAccount.isMain,
      );

      // Обновляем новый счет (добавляем новую сумму)
      final updatedNewAccount = Account(
        id: newAccount.id,
        name: newAccount.name,
        accountType: newAccount.accountType,
        balance: newAccount.balance + newTransaction.amount,
        currency: newAccount.currency,
        icon: newAccount.icon,
        color: newAccount.color,
        isMain: newAccount.isMain,
      );

      accountsProvider.updateAccount(updatedOldAccount);
      accountsProvider.updateAccount(updatedNewAccount);
    }
  }

  // Фильтрация транзакций по дате
  List<Transaction> getFilteredTransactions(DateFilter filter) {
    if (filter.type == DateFilterType.allTime) {
      return [..._transactions];
    }

    return _transactions.where((tx) {
      return tx.date.isAfter(filter.startDate!) &&
          tx.date.isBefore(filter.endDate!.add(Duration(seconds: 1)));
    }).toList();
  }

  // Получение транзакций по дням с фильтрацией по дате
  Map<DateTime, List<Transaction>> getFilteredTransactionsByDay(
    DateFilter filter,
  ) {
    // Add debug for filter dates
    print(
      'DEBUG: Filter dates - start: ${filter.startDate}, end: ${filter.endDate}',
    );

    // Filter transactions based on date
    final filteredTransactions =
        transactions.where((tx) {
          // Get just the date part without time for comparison
          final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
          final startDate = DateTime(
            filter.startDate!.year,
            filter.startDate!.month,
            filter.startDate!.day,
          );
          final endDate = DateTime(
            filter.endDate!.year,
            filter.endDate!.month,
            filter.endDate!.day,
          );

          // Debug each transaction date comparison
          print(
            'DEBUG: Transaction ${tx.id} date: ${tx.date} (normalized: $txDate)',
          );
          print('DEBUG: Comparing with filter: $startDate to $endDate');
          print(
            'DEBUG: Is within range: ${(txDate.isAtSameMomentAs(startDate) || txDate.isAfter(startDate)) && (txDate.isAtSameMomentAs(endDate) || txDate.isBefore(endDate))}',
          );

          // Compare just the date part, ignoring time
          return (txDate.isAtSameMomentAs(startDate) ||
                  txDate.isAfter(startDate)) &&
              (txDate.isAtSameMomentAs(endDate) || txDate.isBefore(endDate));
        }).toList();

    print(
      'DEBUG: Filtered ${filteredTransactions.length} transactions out of ${transactions.length}',
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

  // Получение общих сумм по категориям с фильтрацией
  Map<String, double> getFilteredCategoryTotals({
    bool onlyExpenses = true,
    DateFilter? filter,
  }) {
    final Map<String, double> result = {};

    final filteredTransactions =
        filter != null ? getFilteredTransactions(filter) : [..._transactions];

    final transactions =
        onlyExpenses
            ? filteredTransactions.where((tx) => tx.amount < 0)
            : filteredTransactions.where((tx) => tx.amount > 0);

    for (var tx in transactions) {
      result[tx.category ?? 'Без категории'] =
          (result[tx.category ?? 'Без категории'] ?? 0) + tx.amount.abs();
    }

    return result;
  }

  // Получение суммы по категории с фильтрацией
  double getCategoryAmount(
    String categoryName,
    DateFilter filter, {
    bool isExpense = true,
  }) {
    final transactions =
        getFilteredTransactions(filter)
            .where(
              (tx) =>
                  tx.category == categoryName &&
                  ((isExpense && tx.amount < 0) ||
                      (!isExpense && tx.amount > 0)),
            )
            .toList();

    return transactions.fold<double>(0, (sum, tx) => sum + tx.amount.abs());
  }

  // Синхронизация локальных транзакций с сервером
  Future<void> syncLocalTransactionsWithServer() async {
    if (_transactions.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Получаем транзакции с сервера для сравнения
      final serverTransactions = await _apiService.getTransactions();
      final serverTransactionIds =
          serverTransactions.map<String>((tx) => tx['id'].toString()).toList();

      // Находим локальные транзакции, которых нет на сервере
      final transactionsToSync =
          _transactions
              .where((localTx) => !serverTransactionIds.contains(localTx.id))
              .toList();

      print(
        'DEBUG: Found ${transactionsToSync.length} transactions to sync with server',
      );

      // Отправляем каждую транзакцию на сервер
      for (var transaction in transactionsToSync) {
        try {
          await _apiService.createTransaction(transaction.toJson());
        } catch (e) {
          print('ERROR: Failed to sync transaction: $e');
        }
      }

      // Перезагружаем данные с сервера
      await loadData();
    } catch (e) {
      print('ERROR: Failed to sync transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Обработка ответа сервера при создании транзакции
  Future<void> handleTransactionResponse(Map<String, dynamic>? response) async {
    if (response == null) {
      print('ERROR: Пустой ответ от сервера');
      return;
    }

    try {
      final transaction = Transaction.fromJson(response);
      // Дальнейшая обработка транзакции
      print('DEBUG: Транзакция успешно создана с ID: ${transaction.id}');
    } catch (e) {
      print('ERROR: Не удалось обработать ответ сервера: $e');
      print('DEBUG: Содержимое ответа: $response');
    }
  }
}
