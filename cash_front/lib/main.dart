import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/providers/auth_provider.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/providers/filter_provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/screens/AccountsScreen.dart';
import 'package:cash_flip_app/screens/CategoriesScreen.dart';
import 'package:cash_flip_app/screens/LoginScreen.dart';
import 'package:cash_flip_app/screens/OperationsScreen.dart';
import 'package:cash_flip_app/screens/OverviewScreen.dart';
import 'package:cash_flip_app/widgets/app_drawer.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cash_flip_app/providers/currency_provider.dart';
import 'dart:async';
// import 'package:intl/date_symbol_data_localized.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем данные локализации для русского языка
  await initializeDateFormatting('ru_RU', null);

  final accountsProvider = AccountsProvider();
  final categoriesProvider = CategoriesProvider();
  final transactionsProvider = TransactionsProvider();

  await Future.wait([
    accountsProvider.loadData(),
    categoriesProvider.loadData(),
    transactionsProvider.loadData(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: transactionsProvider),
        ChangeNotifierProvider.value(value: accountsProvider),
        ChangeNotifierProvider.value(value: categoriesProvider),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (context) => CurrencyProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return MaterialApp(
      key: ValueKey(authProvider.isLoggedIn), // Добавляем ключ
      title: 'CashFlip',
      theme: ThemeData(
        primaryColor: Color(0xFF23222A),
        scaffoldBackgroundColor: Color(0xFF23222A),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFBFC6FF),
          secondary: Color(0xFF5B6CF6),
        ),
      ),
      home: authProvider.isLoggedIn ? MainScreen() : LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    AccountsScreen(),
    CategoriesScreen(),
    OperationsScreen(),
    OverviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Настройка периодической синхронизации
    Timer.periodic(Duration(minutes: 5), (timer) {
      _syncData();
    });
  }

  Future<void> _syncData() async {
    final accountsProvider = Provider.of<AccountsProvider>(
      context,
      listen: false,
    );
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    // Синхронизируем балансы
    await accountsProvider.syncBalancesWithServer();

    // Перезагружаем транзакции с сервера
    await transactionsProvider.loadData();
  }

  Future<void> _loadInitialData() async {
    final accountsProvider = Provider.of<AccountsProvider>(
      context,
      listen: false,
    );
    final categoriesProvider = Provider.of<CategoriesProvider>(
      context,
      listen: false,
    );
    final transactionsProvider = Provider.of<TransactionsProvider>(
      context,
      listen: false,
    );

    await accountsProvider.loadData();
    await categoriesProvider.loadData();

    // Синхронизируем локальные счета с сервером
    await accountsProvider.syncLocalAccountsWithServer();

    // Теперь загружаем транзакции
    await transactionsProvider.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Ключ заставит Flutter пересоздать Scaffold при изменении имени/email
    final drawerKey = ValueKey(
      '${authProvider.userName}-${authProvider.userEmail}',
    );

    return Scaffold(
      key: drawerKey,
      drawer: AppDrawer(), // Используйте AppDrawer вместо Drawer
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF23222A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Счета',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Категории',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Операции',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Обзор'),
        ],
      ),
    );
  }
}

// Создайте глобальный метод для получения данных о балансе

class BalanceData {
  final double totalBalance;
  final double totalExpenses;
  final double totalIncome;

  BalanceData({
    required this.totalBalance,
    required this.totalExpenses,
    required this.totalIncome,
  });

  static BalanceData calculateFromProviders(
    BuildContext context, {
    DateFilter? filter,
  }) {
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
    final targetDisplayCurrency = currencyProvider.displayCurrency;

    // Общий баланс по всем счетам в displayCurrency
    double totalBalanceInDisplayCurrency = 0;
    for (var account in accountsProvider.accounts) {
      // Конвертируем баланс каждого счета в targetDisplayCurrency
      // Если валюта счета совпадает с targetDisplayCurrency, конвертация не нужна
      if (currencyProvider.normalizeSymbol(account.currency) == targetDisplayCurrency) {
        totalBalanceInDisplayCurrency += account.balance;
      } else {
        totalBalanceInDisplayCurrency += currencyProvider.convert(
          account.balance,
          account.currency, // from
          targetDisplayCurrency, // to
        );
      }
    }

    // Фильтрованные или все транзакции
    final transactionsToProcess =
        filter != null
            ? transactionsProvider.getFilteredTransactions(filter)
            : transactionsProvider.transactions;

    // Общая сумма расходов и доходов в targetDisplayCurrency
    double convertedTotalExpenses = 0;
    double convertedTotalIncome = 0;

    for (var tx in transactionsToProcess) {
      double amountInTargetCurrency;
      // Определяем абсолютную сумму для конвертации (расходы всегда положительные для расчета)
      double absAmount = tx.amount.abs();

      if (currencyProvider.normalizeSymbol(tx.currency) == targetDisplayCurrency) {
        amountInTargetCurrency = absAmount;
      } else {
        amountInTargetCurrency = currencyProvider.convert(
          absAmount,
          tx.currency,
          targetDisplayCurrency,
        );
      }

      if (tx.amount < 0) {
        convertedTotalExpenses += amountInTargetCurrency;
      } else if (tx.amount > 0) {
        // Для доходов используем оригинальный знак, но сумма уже absAmount, поэтому просто amountInTargetCurrency
        // Фактически, amountInTargetCurrency здесь это absAmount, конвертированный.
        // Если tx.amount был положительным, то absAmount == tx.amount.
        convertedTotalIncome += amountInTargetCurrency;
      }
    }

    return BalanceData(
      totalBalance: totalBalanceInDisplayCurrency,
      totalExpenses: convertedTotalExpenses,
      totalIncome: convertedTotalIncome,
    );
  }
}
