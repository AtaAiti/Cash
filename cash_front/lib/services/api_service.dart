import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Базовый URL для API
  final String baseUrl = 'http://10.0.2.2:8080/api';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Получение сохраненного JWT токена
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Сохранение JWT токена
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Удаление JWT токена при выходе
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // Добавление заголовков авторизации
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    print('Using token: $token'); // Отладочное сообщение

    if (token == null) {
      return {'Content-Type': 'application/json'};
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Общий метод выполнения GET запросов
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await getHeaders();
      print('GET request to $endpoint with headers: $headers');

      final response = await http
          .get(Uri.parse('$baseUrl/$endpoint'), headers: headers)
          .timeout(Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Общий метод выполнения POST запросов
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      // Проверяем colorValue, если он есть
      if (data is Map<String, dynamic> && data.containsKey('colorValue')) {
        if (data['colorValue'] is int && data['colorValue'] > 2147483647) {
          data['colorValue'] = 2147483647;
        }
      }

      final headers = await getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Общий метод выполнения PUT запросов
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final headers = await getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/$endpoint'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Общий метод выполнения DELETE запросов
  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/$endpoint'), headers: headers)
          .timeout(Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Обработка ответа сервера
  dynamic _handleResponse(http.Response response) {
    print(
      'DEBUG: API - Processing response with status code: ${response.statusCode}',
    );
    print('DEBUG: API - Response URL: ${response.request?.url}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('DEBUG: API - Response body is empty');
        return null;
      }

      try {
        final data = jsonDecode(response.body);
        print('DEBUG: API - Successfully decoded JSON data: $data');

        if (data is List) {
          print(
            'DEBUG: API - Response contains a list with ${data.length} items',
          );
        } else if (data is Map) {
          print(
            'DEBUG: API - Response contains a map with keys: ${data.keys.toList()}',
          );
        }

        // Проверяем, какой тип данных вернулся
        if (data is List &&
            response.request != null &&
            response.request!.url.path.contains('/accounts')) {
          final transformed =
              data
                  .map(
                    (json) => {
                      'id': json['id'].toString(), // Преобразуем Long в String
                      'name': json['name'],
                      'accountType': json['accountType'],
                      'balance': json['balance'],
                      'currency': json['currency'],
                      'isMain': json['isMain'],
                      'iconCode': json['iconCode'] ?? 0, // По умолчанию 0
                      'colorValue':
                          json['colorValue'] ??
                          0xFF2196F3, // По умолчанию синий
                    },
                  )
                  .toList();
          print('DEBUG: API - Transformed accounts data: $transformed');
          return transformed;
        }
        return data; // Возвращаем данные как есть для других API
      } catch (e) {
        print('ERROR: API - JSON decode error: $e');
        print('ERROR: API - Raw response body: ${response.body}');
        throw Exception('Failed to parse response: $e');
      }
    } else if (response.statusCode == 401) {
      print('ERROR: API - Unauthorized request (401)');
      throw Exception('Unauthorized');
    } else {
      print('ERROR: API - Server error with status: ${response.statusCode}');
      print('ERROR: API - Response body: ${response.body}');
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // Обработка ошибок запросов
  dynamic _handleError(dynamic error) {
    if (error is TimeoutException) {
      throw Exception('Connection timeout');
    } else if (error is SocketException) {
      throw Exception('No internet connection');
    } else {
      throw error;
    }
  }

  // МЕТОДЫ АУТЕНТИФИКАЦИИ

  Future<String?> login(String email, String password) async {
    try {
      final data = await post('auth/login', {
        'email': email,
        'password': password,
      });

      if (data != null && data['token'] != null) {
        final token = data['token'];
        await saveToken(token);
        return token;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final data = await post('auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (data != null && data['token'] != null) {
        final token = data['token'];
        await saveToken(token);
        return token;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // МЕТОДЫ ДЛЯ СЧЕТОВ

  Future<List<dynamic>> getAccounts() async {
    try {
      print('DEBUG: API - Requesting accounts from server');
      final headers = await getHeaders();
      print('DEBUG: API - Headers for accounts request: $headers');

      final response = await http
          .get(Uri.parse('$baseUrl/accounts'), headers: headers)
          .timeout(Duration(seconds: 10));

      print(
        'DEBUG: API - Accounts response status code: ${response.statusCode}',
      );
      print('DEBUG: API - Accounts response body: ${response.body}');

      final data = _handleResponse(response);
      print('DEBUG: API - Parsed accounts data: $data');
      return data ?? [];
    } catch (e) {
      print('ERROR: API - Get accounts error: $e');
      return [];
    }
  }

  Future<dynamic> createAccount(Map<String, dynamic> accountData) async {
    try {
      print('DEBUG: API - Creating account with data: $accountData');

      // Проверка наличия необходимых полей
      if (!accountData.containsKey('name') ||
          !accountData.containsKey('accountType')) {
        print('ERROR: API - Missing required fields for account creation');
        return null;
      }

      // Преобразование данных для сервера (преобразование типов и т.д.)
      final serverData = {
        'name': accountData['name'],
        'accountType': accountData['accountType'],
        'balance': accountData['balance'],
        'currency': accountData['currency'],
        'isMain': accountData['isMain'] ?? false,
        'iconCode': accountData['iconCode'] ?? 0,
        'colorValue': accountData['colorValue'] ?? 0xFF2196F3,
      };

      // Отправка запроса
      final result = await post('accounts', serverData);
      print('DEBUG: API - Server response for account creation: $result');

      return result;
    } catch (e) {
      print('ERROR: API - Create account error: $e');
      return null;
    }
  }

  Future<dynamic> updateAccount(
    String accountId,
    Map<String, dynamic> accountData,
  ) async {
    try {
      print('DEBUG: [updateAccount] Обновление счета с ID: $accountId');
      print('DEBUG: [updateAccount] Исходные данные: $accountData');

      // Проверка и преобразование ID счета
      final accountIdParsed = int.tryParse(accountId);
      if (accountIdParsed == null) {
        throw Exception("Неверный формат ID счета");
      }

      // Создаем копию данных для преобразования
      final Map<String, dynamic> serverData = {};

      // Копируем необходимые поля
      serverData['name'] = accountData['name'];
      serverData['balance'] = accountData['balance'];
      serverData['accountType'] = accountData['accountType'];
      serverData['currency'] = accountData['currency'];
      serverData['isMain'] = accountData['isMain'];

      // Обрабатываем iconCode и colorValue
      if (accountData.containsKey('iconCode')) {
        final iconCode = accountData['iconCode'];
        if (iconCode is int && iconCode > 2147483647) {
          serverData['iconCode'] =
              2147483647; // Максимальное значение для Java Integer
        } else {
          serverData['iconCode'] = iconCode;
        }
      }

      if (accountData.containsKey('colorValue')) {
        final colorValue = accountData['colorValue'];
        if (colorValue is int && colorValue > 2147483647) {
          serverData['colorValue'] =
              2147483647; // Максимальное значение для Java Integer
        } else {
          serverData['colorValue'] = colorValue;
        }
      }

      print('DEBUG: [updateAccount] Преобразованные данные: $serverData');
      // Используем числовой ID для запроса к API
      return await put('accounts/$accountIdParsed', serverData);
    } catch (e) {
      print('Update account error: $e');
      return null;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await delete('accounts/$accountId');
      return true;
    } catch (e) {
      print('Delete account error: $e');
      return false;
    }
  }

  // МЕТОДЫ ДЛЯ КАТЕГОРИЙ

  Future<List<dynamic>> getCategories() async {
    try {
      print('DEBUG: API - Requesting categories from server');
      final headers = await getHeaders();
      print('DEBUG: API - Headers for categories request: $headers');

      final response = await http
          .get(Uri.parse('$baseUrl/categories'), headers: headers)
          .timeout(Duration(seconds: 10));

      print(
        'DEBUG: API - Categories response status code: ${response.statusCode}',
      );
      print('DEBUG: API - Categories response body: ${response.body}');

      final data = _handleResponse(response);
      print('DEBUG: API - Parsed categories data: $data');
      return data ?? [];
    } catch (e) {
      print('ERROR: API - Get categories error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createCategory(
    Map<String, dynamic> categoryData,
  ) async {
    try {
      print('DEBUG: Создание категории на сервере: $categoryData');

      // Преобразуем поля для соответствия ожиданиям сервера
      final serverData = {
        'name': categoryData['name'],
        'expense': categoryData['isExpense'], // isExpense -> expense
        'colorValue': categoryData['color'], // color -> colorValue
        'iconCode': categoryData['icon'], // icon -> iconCode
      };

      print('DEBUG: Отправка данных категории: $serverData');
      final result = await post('categories', serverData);
      print('DEBUG: Ответ сервера при создании категории: $result');

      // Предупреждение о проблеме с ID
      if (result != null && result['id'] == null) {
        print(
          'ПРЕДУПРЕЖДЕНИЕ: Сервер вернул категорию с null ID - проблема на стороне сервера',
        );
      }

      return result;
    } catch (e) {
      print('ERROR: Ошибка при создании категории: $e');
      return null;
    }
  }

  Future<dynamic> updateCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      return await put('categories/$categoryId', categoryData);
    } catch (e) {
      print('Update category error: $e');
      return null;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await delete('categories/$categoryId');
      return true;
    } catch (e) {
      print('Delete category error: $e');
      return false;
    }
  }

  // МЕТОДЫ ДЛЯ ТРАНЗАКЦИЙ

  Future<List<dynamic>> getTransactions() async {
    try {
      print('DEBUG: API - Requesting transactions from server');
      final headers = await getHeaders();
      print('DEBUG: API - Headers for transactions request: $headers');

      final response = await http
          .get(Uri.parse('$baseUrl/transactions'), headers: headers)
          .timeout(Duration(seconds: 10));

      print(
        'DEBUG: API - Transactions response status code: ${response.statusCode}',
      );
      print('DEBUG: API - Transactions response body: ${response.body}');

      if (response.statusCode == 403) {
        // Проверка возможных причин ошибки 403
        try {
          final errorBody = jsonDecode(response.body);
          print('DEBUG: API - Transactions error details: $errorBody');
        } catch (e) {
          print(
            'DEBUG: API - Could not parse error response: ${response.body}',
          );
        }

        // Проверка токена на действительность
        final token = await getToken();
        if (token != null) {
          final tokenParts = token.split('.');
          if (tokenParts.length == 3) {
            try {
              final payload = base64Url.decode(
                base64Url.normalize(tokenParts[1]),
              );
              final payloadMap = jsonDecode(utf8.decode(payload));
              final expiry = payloadMap['exp'];
              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              print(
                'DEBUG: API - Token expiry: $expiry, current time: $now, is expired: ${expiry < now}',
              );
            } catch (e) {
              print('DEBUG: API - Error checking token: $e');
            }
          }
        }

        throw Exception('Нет доступа к транзакциям (403)');
      }

      final data = _handleResponse(response);
      return data ?? [];
    } catch (e) {
      print('ERROR: API - Get transactions error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final formattedStart = start.toIso8601String();
    final formattedEnd = end.toIso8601String();
    try {
      final data = await get(
        'transactions/range?start=$formattedStart&end=$formattedEnd',
      );
      return data ?? [];
    } catch (e) {
      print('Get transactions by date range error: $e');
      return [];
    }
  }

  Future<dynamic> updateTransaction(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      return await put('transactions/$transactionId', transactionData);
    } catch (e) {
      print('Update transaction error: $e');
      return null;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await delete('transactions/$transactionId');
      return true;
    } catch (e) {
      print('Delete transaction error: $e');
      return false;
    }
  }

  Future<dynamic> createTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      print('DEBUG: Создание транзакции: $transactionData');

      // Проверка наличия всех необходимых полей
      if (!transactionData.containsKey('accountId')) {
        print('ERROR: Отсутствует ID счета в данных транзакции');
        return null;
      }

      // Проверка и преобразование ID счета
      final accountId = int.tryParse(transactionData['accountId'].toString());
      if (accountId == null) {
        print(
          'ERROR: Некорректный формат ID счета: ${transactionData['accountId']}',
        );
        throw Exception("Incorrect Account ID format");
      }

      // Заменяем строковый ID на числовой
      final serverData = {...transactionData};
      serverData['accountId'] = accountId;

      // Сохраняем категорию локально, так как сервер не может хранить категории
      if (serverData.containsKey('category') &&
          serverData['category'] != null &&
          serverData['category'].toString().isNotEmpty) {
        final categoryName = serverData['category'];
        print(
          'DEBUG: Транзакция с категорией "$categoryName", но сохраняем без привязки к категории',
        );

        // Удаляем поле category и categoryId, так как сервер не может их обработать
        serverData.remove('category');
        serverData.remove('categoryId');

        // Добавляем информацию о категории в описание для отладки
        if (!serverData.containsKey('description') ||
            serverData['description'] == null ||
            serverData['description'].toString().isEmpty) {
          serverData['description'] = "Категория: $categoryName";
        }
      }

      // Преобразуем DateTime в строку ISO 8601
      if (serverData.containsKey('date') && serverData['date'] is DateTime) {
        serverData['date'] = serverData['date'].toIso8601String();
      }

      print('DEBUG: Отправка данных на сервер: $serverData');
      final result = await post('transactions', serverData);
      print('DEBUG: Ответ сервера: $result');

      return result;
    } catch (e) {
      print('ERROR: [createTransaction] $e');
      return null;
    }
  }

  // Добавьте этот метод для получения ID категории по имени
  Future<int?> getCategoryIdByName(String categoryName) async {
    try {
      final categories = await getCategories();
      print(
        'DEBUG: Ищем категорию "$categoryName" среди ${categories.length} категорий',
      );

      for (var category in categories) {
        print('DEBUG: Сравниваем с категорией: ${category['name']}');
        if (category['name'] == categoryName) {
          final categoryId = category['id'];
          print('DEBUG: Найдена категория с ID $categoryId');
          return categoryId is int
              ? categoryId
              : int.tryParse(categoryId.toString());
        }
      }
      return null;
    } catch (e) {
      print('ERROR: Ошибка при поиске ID категории: $e');
      return null;
    }
  }

  Future<List<dynamic>> recoverAccountsFromTransactions() async {
    try {
      print('DEBUG: Восстановление счетов из транзакций...');
      final result = await post('accounts/recover-from-transactions', {});
      print('DEBUG: Восстановлено счетов: ${result.length}');
      return result;
    } catch (e) {
      print('ERROR: Ошибка при восстановлении счетов: $e');
      return [];
    }
  }

  Future<List<dynamic>> syncBalances() async {
    try {
      print('DEBUG: Запрос синхронизации балансов с сервером...');
      final response = await post('accounts/sync-balances', {});
      print(
        'DEBUG: Получено ${response?.length ?? 0} счетов с обновленными балансами',
      );
      return response ?? [];
    } catch (e) {
      print('ERROR: Ошибка при синхронизации балансов: $e');
      return [];
    }
  }
}
