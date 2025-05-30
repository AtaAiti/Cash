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

    // Общий баланс по всем счетам
    final totalBalance = accountsProvider.accounts.fold<double>(
      0,
      (sum, account) => sum + account.balance,
    );

    // Фильтрованные или все транзакции
    final transactions =
        filter != null
            ? transactionsProvider.getFilteredTransactions(filter)
            : transactionsProvider.transactions;

    // Общая сумма расходов и доходов
    final totalExpenses = transactions
        .where((tx) => tx.amount < 0)
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());

    final totalIncome = transactions
        .where((tx) => tx.amount > 0)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return BalanceData(
      totalBalance: totalBalance,
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
    );
  }
}
