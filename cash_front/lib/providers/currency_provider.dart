import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currentCurrency = '₽';
  String _displayCurrency = '₽'; // Валюта для отображения
  Map<String, double> _conversionRates = {
    '₽': 1.0,
    'â½': 1.0, // Добавляем закодированный рубль
    'Ñ\$': 1.0, // Еще один вариант кодирования
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
    'â½': {
      // Добавляем закодированный рубль
      'name': 'Российский рубль',
      'code': 'RUB',
      'symbolPosition': 'after',
      'decimalPlaces': 2,
    },
    'Ñ\$': {
      // Еще один вариант кодирования
      'name': 'Российский рубль',
      'code': 'RUB',
      'symbolPosition': 'after',
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

  // Перенесите метод на уровень класса, а не внутрь другого метода
  String normalizeSymbol(String symbol) {
    // Конвертируем в рубль все закодированные варианты
    if (symbol == 'â½' ||
        symbol == 'Ñ\$' ||
        symbol.contains('â') ||
        symbol.contains('½') ||
        symbol.contains('Ñ') ||
        symbol.contains('Ð') ||
        symbol.contains('Ð¾Ð±') ||
        symbol == 'РУБ' ||
        symbol == 'RUB' ||
        symbol == 'руб') {
      return '₽';
    }

    // Если валюта уже в известном формате, возвращаем её как есть
    if (_conversionRates.containsKey(symbol)) {
      return symbol;
    }

    // Для всех остальных неизвестных символов используем рубль по умолчанию
    if (!['₽', '\$', '€', '£', '¥'].contains(symbol)) {
      print(
        'DEBUG: CurrencyProvider - Unrecognized currency: "$symbol", using ₽ instead',
      );
      return '₽';
    }

    return symbol;
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    // Проверка на null или пустые значения
    if (fromCurrency == null ||
        toCurrency == null ||
        fromCurrency.isEmpty ||
        toCurrency.isEmpty) {
      print(
        'WARNING: CurrencyProvider - Null or empty currency in convert: from=$fromCurrency, to=$toCurrency',
      );
      return amount; // Возвращаем исходную сумму без конвертации
    }

    // Нормализуем входные символы используя публичный метод
    final normalizedFromCurrency = normalizeSymbol(fromCurrency);
    final normalizedToCurrency = normalizeSymbol(toCurrency);

    // Если валюты совпадают после нормализации, не конвертируем
    if (normalizedFromCurrency == normalizedToCurrency) {
      return amount;
    }

    // Получаем обменный курс
    double exchangeRate = _getExchangeRate(normalizedFromCurrency, normalizedToCurrency);

    // Выполняем конвертацию
    double result = amount * exchangeRate;

    print(
      'DEBUG: CurrencyProvider.convert: $amount $normalizedFromCurrency -> $result $normalizedToCurrency (Rate: $exchangeRate)',
    );

    return result;
  }

  // Форматирование суммы с учетом валюты
  String formatAmount(
    double amount,
    String fromCurrency, {
    String? toCurrency, // Этот параметр теперь определяет, нужно ли конвертировать
  }) {
    // Нормализуем исходную валюту
    String normalizedFrom = normalizeSymbol(fromCurrency);

    // Определяем целевую валюту для форматирования и возможной конвертации
    String targetFormatCurrency;
    double amountToFormat;

    if (toCurrency != null) {
      // Если toCurrency указан, нормализуем его
      String normalizedTo = normalizeSymbol(toCurrency);
      if (normalizedFrom == normalizedTo) {
        // Валюты совпадают, конвертация не нужна
        amountToFormat = amount;
        targetFormatCurrency = normalizedTo;
      } else {
        // Валюты разные, нужна конвертация
        amountToFormat = convert(amount, normalizedFrom, normalizedTo);
        targetFormatCurrency = normalizedTo;
      }
    } else {
      // Если toCurrency НЕ указан, форматируем в ИСХОДНОЙ валюте (fromCurrency)
      amountToFormat = amount;
      targetFormatCurrency = normalizedFrom; // Форматируем в исходной валюте
    }

    // Получаем данные для форматирования (положение символа, кол-во знаков после запятой)
    final currencyDetails = _currencyData[targetFormatCurrency] ??
        _currencyData['₽']; // По умолчанию используем данные для рубля
    final symbolPosition = currencyDetails?['symbolPosition'] ?? 'after';
    final decimalPlaces = currencyDetails?['decimalPlaces'] ?? 2;

    String formattedAmount = amountToFormat.toStringAsFixed(decimalPlaces);

    // Форматируем с учетом положения символа
    if (symbolPosition == 'before') {
      return '$targetFormatCurrency $formattedAmount';
    } else {
      return '$formattedAmount $targetFormatCurrency';
    }
  }

  double _getExchangeRate(String fromCurrency, String toCurrency) {
    // Нормализация символов валют перед использованием
    final normalizedFrom = normalizeSymbol(fromCurrency);
    final normalizedTo = normalizeSymbol(toCurrency);

    // Получаем курсы из _conversionRates. Они все относительно рубля.
    // Например, _conversionRates['\$'] - это курс USD к RUB (сколько USD за 1 RUB)
    // _conversionRates['€'] - это курс EUR к RUB (сколько EUR за 1 RUB)

    final rateFromRub = _conversionRates[normalizedFrom]; // Курс fromCurrency к RUB
    final rateToRub = _conversionRates[normalizedTo];   // Курс toCurrency к RUB

    if (rateFromRub == null || rateToRub == null) {
      print(
        'WARNING: CurrencyProvider - Missing rate for $normalizedFrom or $normalizedTo in _getExchangeRate. Using 1.0 as fallback.',
      );
      return 1.0; // Возвращаем 1.0 в случае отсутствия курса, чтобы избежать ошибок деления на ноль или null
    }

    // Если fromCurrency - это рубль, то курс к toCurrency - это просто rateToRub
    // Пример: RUB -> USD. rateFromRub = 1.0 (RUB/RUB). rateToRub = 0.011 (USD/RUB)
    // Курс RUB к USD = 0.011 / 1.0 = 0.011 (сколько USD за 1 RUB)
    if (normalizedFrom == '₽') {
      return rateToRub;
    }

    // Если toCurrency - это рубль, то курс fromCurrency к рублю - это 1.0 / rateFromRub
    // Пример: USD -> RUB. rateFromRub = 0.011 (USD/RUB). rateToRub = 1.0 (RUB/RUB)
    // Курс USD к RUB = 1.0 / 0.011 (сколько RUB за 1 USD)
    if (normalizedTo == '₽') {
      if (rateFromRub == 0) return 1.0; // Защита от деления на ноль
      return 1.0 / rateFromRub;
    }

    // Для конвертации между двумя валютами (не рублями), например USD -> EUR
    // Нужно сначала перевести fromCurrency в рубли, а затем рубли в toCurrency.
    // (amountInFromCurrency / rateFromRub) * rateToRub
    // Значит, итоговый курс fromCurrency к toCurrency будет rateToRub / rateFromRub
    // Пример: USD -> EUR. rateFromRub = 0.011 (USD/RUB). rateToRub = 0.010 (EUR/RUB)
    // Курс USD к EUR = 0.010 (EUR/RUB) / 0.011 (USD/RUB) = (EUR/USD) (сколько EUR за 1 USD)
    if (rateFromRub == 0) return 1.0; // Защита от деления на ноль
    return rateToRub / rateFromRub;
  }

  // Format amount with proper currency symbol
  String formatAmountWithCurrentCurrency(double amount, {String? currency}) {
    final targetCurrency = currency ?? _currentCurrency;
    final convertedAmount = convert(amount, '₽', targetCurrency);
    return '${convertedAmount.toStringAsFixed(2)} $targetCurrency';
  }

  void initExchangeRates() {
    // Добавляем базовые курсы, если API недоступен
    _conversionRates = {
      '₽': 1.0,
      'â½': 1.0, // Добавляем закодированный рубль
      'Ñ\$': 1.0, // Еще один вариант кодирования
      '\$': 0.011, // примерный курс рубля к доллару
      '€': 0.010, // примерный курс рубля к евро
      '£': 0.0087, // примерный курс рубля к фунту
      '¥': 1.63, // примерный курс рубля к йене
    };

    notifyListeners();

    // После этого можно пытаться загружать актуальные курсы с API
    _fetchLatestRates();
  }
}
