import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cash_flip_app/services/api_service.dart';
import 'transactions_provider.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final List<String> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
    this.subcategories = const [],
  });

  // Конвертация в Map для API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'isExpense': isExpense,
      'subcategories': subcategories,
    };
  }

  // Создание объекта из Map, полученного от API
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'],
      icon: IconData(json['iconCode'] ?? 0xe318, fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue'] ?? 0xFF2196F3),
      isExpense: json['isExpense'] ?? true,
      subcategories: List<String>.from(json['subcategories'] ?? []),
    );
  }
}

class CategoriesProvider with ChangeNotifier {
  List<Category> _categories = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  CategoriesProvider() {
    _initCategories();
  }

  List<Category> get categories => [..._categories];
  List<Category> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();
  List<Category> get incomeCategories =>
      _categories.where((c) => !c.isExpense).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initCategories() {
    _categories = [
      Category(
        id: '1',
        name: 'Продукты',
        icon: Icons.shopping_basket,
        color: Colors.blue,
        isExpense: true,
        subcategories: ['Магазин', 'Кафе'],
      ),
      Category(
        id: '2',
        name: 'Зарплата',
        icon: Icons.attach_money,
        color: Colors.green,
        isExpense: false,
      ),
    ];
  }

  // Загрузка категорий с сервера
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    _categories = [];
    print('DEBUG: Starting to load categories data');
    notifyListeners();
    try {
      // Sever data loading
      print('DEBUG: Attempting to fetch categories from server');
      final categoriesDataFromServer = await _apiService.getCategories();
      print(
        'DEBUG: Server returned ${categoriesDataFromServer.length} categories',
      );

      if (categoriesDataFromServer.isNotEmpty) {
        _categories =
            categoriesDataFromServer
                .map<Category>((json) => Category.fromJson(json))
                .toList();
        print('DEBUG: Loaded ${_categories.length} categories from server');
        await saveData();
      } else {
        print('DEBUG: No categories returned from server, checking local data');
        await _loadLocalData();
      }
    } catch (e) {
      print('ERROR: Failed to load categories from API: $e');
      _error = 'Failed to load categories from server. Checking local data.';
      await _loadLocalData();
    } finally {
      _isLoading = false;
      print(
        'DEBUG: Categories loading complete. Categories count: ${_categories.length}',
      );
      print(
        'DEBUG: Expense categories: ${expenseCategories.length}, Income categories: ${incomeCategories.length}',
      );
      notifyListeners();
    }
  }

  // Загрузка локальных данных (этот метод теперь менее критичен при правильной работе loadData)
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('categories_data');

      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _categories =
            decoded
                .map((item) => Category.fromJson(item))
                .toList(); // Используем fromJson
      } else {
        // Если локальных данных нет, _categories не меняется (он должен был быть очищен в loadData)
      }
    } catch (e) {
      print('Error loading local categories data: $e');
      // Если и локальные данные не загрузились, оставляем предустановленные
    }
  }

  // Сохранение данных локально
  Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(
        _categories
            .map(
              (category) => {
                'id': category.id,
                'name': category.name,
                'icon': category.icon.codePoint,
                'color': category.color.value,
                'isExpense': category.isExpense,
                'subcategories': category.subcategories,
              },
            )
            .toList(),
      );

      await prefs.setString('categories_data', jsonData);
    } catch (e) {
      print('Error saving local categories data: $e');
    }
  }

  // Добавление категории
  Future<void> addCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Добавляем на сервер
      final result = await _apiService.createCategory(category.toJson());

      if (result != null) {
        // Создаем категорию из ответа сервера, но сохраняем оригинальное значение isExpense
        final newCategory = Category(
          id: result['id'].toString(),
          name: result['name'],
          icon: IconData(
            result['iconCode'] ?? 0xe318,
            fontFamily: 'MaterialIcons',
          ),
          color: Color(result['colorValue'] ?? 0xFF2196F3),
          isExpense:
              category.isExpense, // Используем значение из исходной категории
          subcategories: List<String>.from(result['subcategories'] ?? []),
        );
        _categories.add(newCategory);
      } else {
        // Если сервер вернул null, добавляем только локально
        _categories.add(category);
      }
    } catch (e) {
      print('Error adding category to API: $e');
      // При ошибке добавляем только локально
      _categories.add(category);
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  // Обновление категории
  Future<void> updateCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Обновляем на сервере
      final result = await _apiService.updateCategory(
        category.id,
        category.toJson(),
      );

      // Обновляем локально в любом случае
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
    } catch (e) {
      print('Error updating category on API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  // Удаление категории
  Future<void> deleteCategory(String id, BuildContext context) async {
    // Проверяем использование категории в транзакциях
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    // Находим имя категории
    final category = _categories.firstWhere((c) => c.id == id);

    // Проверяем, используется ли категория в транзакциях
    final isUsed = transactionsProvider.transactions.any(
      (tx) => tx.category == category.name,
    );

    if (isUsed) {
      // Показываем предупреждение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Нельзя удалить категорию, она используется в транзакциях',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Удаляем на сервере
      final success = await _apiService.deleteCategory(id);

      // Удаляем локально в любом случае
      _categories.removeWhere((c) => c.id == id);
    } catch (e) {
      print('Error deleting category from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      saveData(); // Сохраняем локально
    }
  }

  Future<void> syncCategoriesToServer() async {
    try {
      print('DEBUG: Начинаем синхронизацию категорий с сервером');

      // Получаем категории с сервера
      final serverCategories = await _apiService.getCategories();
      final serverCategoryNames =
          serverCategories
              .map<String>((cat) => cat['name'].toString())
              .toList();

      print('DEBUG: Категории на сервере: $serverCategoryNames');
      print(
        'DEBUG: Локальные категории: ${_categories.map((c) => c.name).toList()}',
      );

      // Находим категории, которых нет на сервере
      final categoriesToSync =
          _categories
              .where((localCat) => !serverCategoryNames.contains(localCat.name))
              .toList();

      print(
        'DEBUG: Нужно синхронизировать ${categoriesToSync.length} категорий',
      );

      // Массив для хранения созданных категорий и их ID
      List<Map<String, dynamic>> createdCategories = [];

      // Отправляем каждую категорию на сервер
      for (var category in categoriesToSync) {
        final categoryData = {
          'name': category.name,
          'isExpense': category.isExpense,
          'color': category.color.value,
          'icon': category.icon.codePoint,
        };

        final result = await _apiService.createCategory(categoryData);
        if (result != null && result['id'] != null) {
          createdCategories.add({'name': category.name, 'id': result['id']});
          print(
            'DEBUG: Категория ${category.name} создана с ID: ${result['id']}',
          );
        } else {
          print('ERROR: Не удалось создать категорию ${category.name}');
        }
      }

      // Повторный запрос категорий с сервера для проверки
      final updatedCategories = await _apiService.getCategories();
      print(
        'DEBUG: Обновленные категории на сервере: ${updatedCategories.map((c) => "${c['name']}:${c['id']}").toList()}',
      );

      print('DEBUG: Синхронизация категорий завершена');
    } catch (e) {
      print('ERROR: Ошибка синхронизации категорий: $e');
    }
  }
}
