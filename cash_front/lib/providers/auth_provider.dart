import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cash_flip_app/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  String? _userEmail;
  String? _userName;
  final ApiService _apiService = ApiService();

  AuthProvider() {
    _checkLoginStatus();
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();

    if (token != null && token.isNotEmpty) {
      _token = token;

      // Проверяем валидность токена
      final isValid = await isTokenValid();
      if (!isValid) {
        await logout(); // Если токен невалиден, выходим
        return;
      }

      _isLoggedIn = true;

      // Загружаем информацию о пользователе
      try {
        final userData = await _apiService.get('users/me');
        if (userData != null) {
          _userEmail = userData['email'];
          _userName = userData['name'];
        }
      } catch (e) {
        print('Error loading user data: $e');
      }

      notifyListeners();
    }
  }

  Future<void> loadUserFromToken() async {
    final token = await _apiService.getToken();

    if (token != null && token.isNotEmpty) {
      _token = token;

      // Проверяем валидность токена
      final isValid = await isTokenValid();
      if (!isValid) {
        await logout(); // Если токен невалиден, выходим
        return;
      }

      _isLoggedIn = true;

      // Загружаем информацию о пользователе
      try {
        final userData = await _apiService.get('users/me');
        if (userData != null) {
          _userEmail = userData['email'];
          _userName = userData['name'];
        }
      } catch (e) {
        print('Error loading user data: $e');
      }

      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final token = await _apiService.login(email, password);

      if (token != null) {
        _token = token;
        _isLoggedIn = true;
        _userEmail = email;

        // Важно: явно устанавливаем значение по умолчанию перед асинхронным запросом
        _userName = "Загрузка...";

        // Первое уведомление с временными данными
        notifyListeners();

        try {
          final userData = await _apiService.get('users/me');
          if (userData != null && userData['name'] != null) {
            _userName = userData['name'];
            print("Имя пользователя установлено: $_userName");
          } else {
            _userName = email.split('@')[0]; // Запасной вариант - имя из email
            print("Имя пользователя по умолчанию: $_userName");
          }
        } catch (e) {
          print('Error loading user data: $e');
          _userName = email.split('@')[0]; // Запасной вариант при ошибке
        }

        // ОЧИСТКА ДАННЫХ ПРЕДЫДУЩЕГО ПОЛЬЗОВАТЕЛЯ
        await _clearUserSpecificData();

        // Обязательное второе уведомление ПОСЛЕ загрузки имени
        print(
          "Вызываем notifyListeners с окончательными данными: $_userName, $_userEmail",
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    // Изменил void на Future<bool>
    try {
      final token = await _apiService.register(name, email, password);

      if (token != null) {
        _token = token;
        _isLoggedIn = true;
        _userEmail = email;
        _userName = name;

        // ОЧИСТКА ДАННЫХ ПРЕДЫДУЩЕГО ПОЛЬЗОВАТЕЛЯ
        await _clearUserSpecificData();

        notifyListeners();
        return true; // Успешная регистрация
      }
      return false; // Регистрация не удалась (токен не получен)
    } catch (e) {
      print('Registration error: $e');
      return false; // Ошибка при регистрации
    }
  }

  Future<void> logout() async {
    await _apiService.deleteToken(); // Удаляем токен из ApiService

    _token = null;
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    // await _clearTokenFromPrefs(); // Убедитесь, что токен также удаляется из SharedPreferences, если вы его там храните отдельно

    // Очищаем данные вышедшего пользователя
    await _clearUserSpecificData();

    notifyListeners();
  }

  Future<void> _clearUserSpecificData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accounts_data');
    await prefs.remove('transactions_data');
    await prefs.remove('categories_data');
    await prefs.remove(
      'account_balance_history',
    ); // Добавлено на основе AccountsProvider

    // Важно: Также нужно сбросить состояние в памяти у других провайдеров.
    // Это можно сделать, если AuthProvider имеет доступ к другим провайдерам
    // или если другие провайдеры слушают изменения в AuthProvider (например, isLoggedIn).
    // На данный момент, очистка SharedPreferences - это первый шаг.
    // Провайдеры данных, при следующей загрузке, не найдут локальных данных и запросят их с сервера.
    print('AuthProvider: User specific data cleared from SharedPreferences.');
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) return false;

      // Попробуйте выполнить тестовый запрос
      await _apiService.get('users/me');
      return true;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Метод для обновления токена:
  Future<bool> refreshToken() async {
    // Реализовать логику обновления токена через API
    // Если на бэкенде есть endpoint для обновления токена
    return false;
  }
}
