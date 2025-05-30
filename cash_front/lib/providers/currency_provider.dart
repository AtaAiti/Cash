import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currentCurrency = '₽';
  String _displayCurrency = '₽'; // Валюта для отображения
  Map<String, double> _conversionRates = {
    '₽': 1.0,
    '\$': 0.011, // 1 RUB = 0.011 USD
    '€': 0.010, // 1 RUB = 0.010 EUR
    '£': 0.0085, // 1 RUB = 0.0085 GBP
    '¥': 1.61, // 1 RUB = 1.61 JPY
  };
  bool _isLoading = false;

  // Добавим дополнительные данные о валютах
  final Map<String, Map<String, dynamic>> _currencyData = {
    '₽': {
      'name': 'Российский рубль',
      'code': 'RUB',
      'symbolPosition': 'after', // после числа
      'decimalPlaces': 2,
    },
    '\$': {
      'name': 'Доллар США',
      'code': 'USD',
      'symbolPosition': 'before', // перед числом
      'decimalPlaces': 2,
    },
    '€': {
      'name': 'Евро',
      'code': 'EUR',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
    },
    '£': {
      'name': 'Фунт стерлингов',
      'code': 'GBP',
      'symbolPosition': 'before',
      'decimalPlaces': 2,
    },
    '¥': {
      'name': 'Японская йена',
      'code': 'JPY',
      'symbolPosition': 'after',
      'decimalPlaces': 0,
    },
  };

  CurrencyProvider() {
    _loadSavedCurrency();
    _fetchLatestRates();
  }

  String get currentCurrency => _currentCurrency;
  String get displayCurrency => _displayCurrency;
  bool get isLoading => _isLoading;
  Map<String, double> get conversionRates => _conversionRates;
  List<String> get availableCurrencies => _currencyData.keys.toList();

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCurrency = prefs.getString('currency') ?? '₽';
    notifyListeners();
  }

  Future<void> _saveCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _currentCurrency);
  }

  Future<void> _fetchLatestRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Replace with your actual API key if you're using a real currency API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/RUB'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('rates')) {
          _conversionRates = {
            '₽': 1.0,
            '\$': data['rates']['USD'] ?? 0.011,
            '€': data['rates']['EUR'] ?? 0.010,
            '£': data['rates']['GBP'] ?? 0.0085,
            '¥': data['rates']['JPY'] ?? 1.61,
          };
        }
      }
    } catch (e) {
      print('Failed to load currency rates: $e');
      // Keep using default rates if the fetch fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeCurrency(String newCurrency) {
    if (_conversionRates.containsKey(newCurrency)) {
      _currentCurrency = newCurrency;
      _saveCurrency();
      notifyListeners();
    }
  }

  void setDisplayCurrency(String currency) {
    if (_currencyData.containsKey(currency)) {
      _displayCurrency = currency;
      notifyListeners();
    }
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    // First convert to RUB (base currency)
    double amountInRub =
        fromCurrency == '₽' ? amount : amount / _conversionRates[fromCurrency]!;

    // Then convert from RUB to target currency
    return amountInRub * _conversionRates[toCurrency]!;
  }

  // Форматирование суммы с учетом валюты
  String formatAmount(double amount, String currency) {
    if (!_currencyData.containsKey(currency)) {
      currency = _displayCurrency; // По умолчанию используем текущую валюту
    }

    final decimalPlaces = _currencyData[currency]!['decimalPlaces'] as int;
    final formattedNumber = amount.toStringAsFixed(decimalPlaces);

    switch (_currencyData[currency]!['symbolPosition']) {
      case 'before':
        return '$currency$formattedNumber';
      case 'after':
      default:
        return '$formattedNumber $currency';
    }
  }

  // Format amount with proper currency symbol
  String formatAmountWithCurrentCurrency(double amount, {String? currency}) {
    final targetCurrency = currency ?? _currentCurrency;
    final convertedAmount = convert(amount, '₽', targetCurrency);
    return '${convertedAmount.toStringAsFixed(2)} $targetCurrency';
  }
}
