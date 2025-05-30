import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cash_flip_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account {
  final String id;
  final String name;
  final String accountType;
  final double balance;
  final String currency;
  final IconData icon;
  final Color color;
  final bool isMain;
  final String? description; // Добавляем это поле

  Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balance,
    required this.currency,
    required this.icon,
    required this.color,
    required this.isMain,
    this.description, // Добавляем параметр
  });

  // Конвертация в Map для API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountType': accountType,
      'balance': balance,
      'currency': currency,
      'iconCode': icon.codePoint,
      'colorValue':
          color.value > 2147483647
              ? 2147483647
              : color.value, // Ограничиваем значением int в Java
      'isMain': isMain,
      'description': description, // Добавляем это поле
    };
  }

  // Создание объекта из Map, полученного от API
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'].toString(),
      name: json['name'],
      accountType: json['accountType'],
      balance:
          (json['balance'] is int)
              ? (json['balance'] as int).toDouble()
              : double.parse(json['balance'].toString()),
      currency: json['currency'],
      icon: IconData(json['iconCode'] ?? 0xe39d, fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue'] ?? 0xFF2196F3),
      isMain: json['isMain'] ?? false,
      description: json['description'], // Добавляем это поле
    );
  }
}

class AccountsProvider with ChangeNotifier {
  List<Account> _accounts = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  // История изменения балансов (для упрощенной версии)
  Map<String, List<Map<String, dynamic>>> _accountBalanceHistory = {};

  AccountsProvider() {
    _initAccounts();
  }

  List<Account> get accounts => [..._accounts];
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initAccounts() {
    _accounts = [
      Account(
        id: '1',
        name: 'Карта',
        accountType: 'обычный',
        balance: 0.0,
        currency: '₽',
        icon: Icons.credit_card,
        color: Colors.blue,
        isMain: true,
      ),
    ];
  }

  // Загрузка счетов с сервера
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    _accounts =
        []; // <<< ВАЖНОЕ ИЗМЕНЕНИЕ: Очищаем список счетов в памяти перед загрузкой
    notifyListeners(); // Уведомляем UI, что данные очищаются/перезагружаются

    try {
      // Сначала пробуем загрузить с сервера
      final accountsDataFromServer = await _apiService.getAccounts();

      if (accountsDataFromServer.isNotEmpty) {
        _accounts =
            accountsDataFromServer
                .map<Account>((json) => Account.fromJson(json))
                .toList();
        await saveData(); // Сохраняем свежие данные с сервера в SharedPreferences
      } else {
        // Сервер не вернул счетов для этого пользователя (например, новый пользователь).
        // _accounts уже пуст после очистки в начале метода.
        // Сохраняем пустой список в SharedPreferences, чтобы очистить старые локальные данные.
        await saveData(); // Это сохранит пустой список _accounts
      }
    } catch (e) {
      print('Error loading accounts from API: $e');
      _error = 'Failed to load accounts from server. Clearing local data.';
      _accounts = []; // Очищаем счета при ошибке API
      await saveData(); // Сохраняем пустой список, чтобы очистить локальные данные при ошибке
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Загрузка локальных данных (этот метод теперь менее критичен при правильной работе loadData)
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('accounts_data');

      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _accounts =
            decoded
                .map(
                  (item) => Account(
                    // Убедитесь, что Account.fromJson используется, если он есть
                    id:
                        item['id']
                            .toString(), // Пример, если ID должен быть строкой
                    name: item['name'],
                    accountType: item['accountType'],
                    balance: (item['balance'] as num).toDouble(),
                    currency: item['currency'],
                    icon: IconData(
                      item['iconCode'] ??
                          (item['icon'] is int
                              ? item['icon']
                              : 0xe39d), // Обработка старого и нового формата
                      fontFamily: 'MaterialIcons',
                    ),
                    color: Color(
                      item['colorValue'] ??
                          (item['color'] is int ? item['color'] : 0xFF2196F3),
                    ), // Обработка старого и нового формата
                    isMain: item['isMain'] ?? false,
                    description: item['description'],
                  ),
                )
                .toList();
      } else {
        // Если локальных данных нет, _accounts не меняется (он должен был быть очищен в loadData)
      }
    } catch (e) {
      print('Error loading local accounts data: $e');
      // Если и локальные данные не загрузились, оставляем предустановленные
    }
  }

  // Сохранение данных локально и на сервере
  Future<void> saveData() async {
    try {
      // Сохраняем локально
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(
        _accounts
            .map(
              (account) => {
                'id': account.id,
                'name': account.name,
                'accountType': account.accountType,
                'balance': account.balance,
                'currency': account.currency,
                'icon': account.icon.codePoint,
                'color': account.color.value,
                'isMain': account.isMain,
                'description': account.description, // Добавляем это поле
              },
            )
            .toList(),
      );

      await prefs.setString('accounts_data', jsonData);
    } catch (e) {
      print('Error saving local accounts data: $e');
    }
  }

  // Добавление счета
  Future<void> addAccount(dynamic accountData, {BuildContext? context}) async {
    try {
      // Проверяем, является ли accountData объектом Account
      if (accountData is Account) {
        // Добавляем существующий Account объект в список
        _accounts.add(accountData);
        notifyListeners();
        saveData();
        return;
      }

      // Явное приведение к Map<String, dynamic>
      final accountMap = accountData as Map<String, dynamic>;
      final accountWithoutId = Map<String, dynamic>.from(accountMap);
      accountWithoutId.remove('id');

      // Добавляем преобразование для иконки и цвета
      accountWithoutId['iconCode'] = accountMap['icon'].codePoint;
      accountWithoutId['colorValue'] = accountMap['color'].value;

      final result = await _apiService.createAccount(accountWithoutId);

      // Используем возвращенный ID от сервера
      final newAccount = Account(
        id: result['id'].toString(),
        name: result['name'],
        accountType: result['accountType'],
        balance: result['balance'],
        currency: result['currency'],
        isMain: result['isMain'] ?? false,
        icon: IconData(result['iconCode'] ?? 0, fontFamily: 'MaterialIcons'),
        color: Color(result['colorValue'] ?? 0xFF2196F3),
        description: result['description'], // Добавляем это поле
      );

      _accounts.add(newAccount);
      notifyListeners();
      saveData();
    } catch (e) {
      print('Error adding account: $e');
      // Check if context was provided before using it
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении счета: $e')),
        );
      }
    }
  }

  // Обновление счета
  Future<void> updateAccount(Account account) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Обновляем на сервере
      final result = await _apiService.updateAccount(
        account.id,
        account.toJson(),
      );

      // Обновляем локально в любом случае
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
      }
    } catch (e) {
      print('Error updating account on API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  // Удаление счета
  Future<void> deleteAccount(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Удаляем на сервере
      final success = await _apiService.deleteAccount(id);

      // Удаляем локально в любом случае
      _accounts.removeWhere((a) => a.id == id);
    } catch (e) {
      print('Error deleting account from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  Account? getMainAccount() {
    try {
      return _accounts.firstWhere((account) => account.isMain);
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts[0] : null;
    }
  }

  // Получение баланса счета на конкретную дату
  Future<double> getAccountBalanceAtDate(
    String accountId,
    DateTime date,
  ) async {
    // Если история не инициализирована для этого счета, возвращаем текущий баланс
    if (!_accountBalanceHistory.containsKey(accountId)) {
      try {
        final account = _accounts.firstWhere((a) => a.id == accountId);
        return account.balance;
      } catch (e) {
        return 0.0;
      }
    }

    // Находим последнюю запись баланса до указанной даты
    final history = _accountBalanceHistory[accountId]!;
    final entriesBeforeDate =
        history
            .where(
              (entry) => DateTime.fromMillisecondsSinceEpoch(
                entry['timestamp'] as int,
              ).isBefore(date),
            )
            .toList();

    if (entriesBeforeDate.isEmpty) {
      return 0.0; // Если нет истории до этой даты, возвращаем 0
    }

    // Сортируем записи по времени (от новых к старым)
    entriesBeforeDate.sort(
      (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
    );

    // Возвращаем самый последний баланс до указанной даты
    return entriesBeforeDate.first['balance'] as double;
  }

  // Добавляем запись об изменении баланса в историю
  void recordBalanceChange(String accountId, double newBalance) {
    if (!_accountBalanceHistory.containsKey(accountId)) {
      _accountBalanceHistory[accountId] = [];
    }

    _accountBalanceHistory[accountId]!.add({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'balance': newBalance,
    });

    // Сохраняем историю локально
    _saveBalanceHistory();
  }

  // Сохранение истории балансов
  Future<void> _saveBalanceHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_accountBalanceHistory);
      await prefs.setString('account_balance_history', jsonData);
    } catch (e) {
      print('Error saving balance history: $e');
    }
  }

  // Загрузка истории балансов
  Future<void> _loadBalanceHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('account_balance_history');
      if (jsonData != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonData);
        _accountBalanceHistory = decoded.map((key, value) {
          return MapEntry(key, (value as List).cast<Map<String, dynamic>>());
        });
      }
    } catch (e) {
      print('Error loading balance history: $e');
    }
  }
}
