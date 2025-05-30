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
      // Если это данные транзакции и содержат дату в виде строки, преобразуем
      if (endpoint.contains('transactions') &&
          data is Map<String, dynamic> &&
          data.containsKey('date')) {
        if (data['date'] is String) {
          data['date'] = DateTime.parse(data['date']).millisecondsSinceEpoch;
        }
      }

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
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;

      final data = jsonDecode(response.body);
      // Проверяем, какой тип данных вернулся
      if (data is List &&
          response.request != null &&
          response.request!.url.path.contains('/accounts')) {
        return data
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
                    json['colorValue'] ?? 0xFF2196F3, // По умолчанию синий
              },
            )
            .toList();
      }
      return data; // Возвращаем данные как есть для других API
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
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
      final data = await get('accounts');
      return data ?? [];
    } catch (e) {
      print('Get accounts error: $e');
      return [];
    }
  }

  Future<dynamic> createAccount(Map<String, dynamic> accountData) async {
    try {
      return await post('accounts', accountData);
    } catch (e) {
      print('Create account error: $e');
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
      final data = await get('categories');
      return data ?? [];
    } catch (e) {
      print('Get categories error: $e');
      return [];
    }
  }

  Future<dynamic> createCategory(Map<String, dynamic> categoryData) async {
    try {
      print('Category data being sent: $categoryData'); // Добавить логирование
      final result = await post('categories', categoryData);
      print('Server response: $result'); // Добавить логирование
      return result;
    } catch (e) {
      print('Create category error: $e');
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
      final data = await get('transactions');
      return data ?? [];
    } catch (e) {
      print('Get transactions error: $e');
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
      print('DEBUG: Creating a data transaction: $transactionData');

      // Проверка наличия всех необходимых полей
      if (!transactionData.containsKey('accountId')) {
        print('mistake: Account Id is missing in the transaction data');
        return null;
      }

      // Проверка и преобразование ID счета
      final accountId = int.tryParse(transactionData['accountId'].toString());
      if (accountId == null) {
        print(
          'mistake: Incorrect Account ID format: ${transactionData['accountId']}',
        );
        throw Exception("Incorrect Account ID format");
      }

      // Заменяем строковый ID на числовой
      final serverData = {...transactionData};
      serverData['accountId'] = accountId;

      print('DEBUG: Sending data to the server: $serverData');
      final result = await post('transactions', serverData);
      print('DEBUG: Server response: $result');

      return result;
    } catch (e) {
      print('mistake: [createTransaction] $e');
      return null;
    }
  }

  // Вспомогательный метод для получения ID категории по имени
  int? getCategoryIdByName(String categoryName) {
    // Этот метод должен вернуть ID категории по имени
    // Можно реализовать кэширование категорий или запрос к серверу
    print('DEBUG: [getCategoryIdByName] Search for a category ID: $categoryName');
    return null; // Заглушка - нужно реализовать
  }
}
