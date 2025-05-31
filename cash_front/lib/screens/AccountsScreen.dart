import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Добавляем этот импорт
import 'package:cash_flip_app/providers/accounts_provider.dart'; // Добавляем этот импорт
import 'package:cash_flip_app/widgets/app_drawer.dart';
import 'package:cash_flip_app/widgets/account_form_modal.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';
import 'package:cash_flip_app/widgets/date_selector.dart'; // Добавьте импорт
import 'package:cash_flip_app/providers/currency_provider.dart';
import 'package:cash_flip_app/widgets/currency_selection_modal.dart';

// Изменяем на StatefulWidget для хранения состояния текущей вкладки
class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

// Модифицируем для поддержки фильтрации по датам
class _AccountsScreenState extends State<AccountsScreen> {
  bool _showAccounts = true;
  DateFilter _currentFilter = DateFilter(
    type: DateFilterType.month,
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsProvider>(
      builder: (context, accountsProvider, _) {
        return LoadingOverlay(
          isLoading: accountsProvider.isLoading,
          child: Scaffold(
            backgroundColor: Color(0xFF23222A),
            drawer: AppDrawer(),
            appBar: AppBar(
              backgroundColor: Color(0xFF23222A),
              elevation: 0,
              centerTitle: true,
              title: Consumer2<AccountsProvider, CurrencyProvider>(
                builder: (context, accountsProvider, currencyProvider, _) {
                  // Calculate total balance in base currency (₽)
                  double totalBalanceInRub = 0;
                  final targetCurrency = currencyProvider.displayCurrency;

                  try {
                    // Безопасный перебор счетов
                    for (var account in accountsProvider.accounts) {
                      if (account.currency != null &&
                          account.currency.isNotEmpty) {
                        // Добавляем проверку на null
                        totalBalanceInRub += currencyProvider.convert(
                          account.balance,
                          account.currency,
                          '₽',
                        );
                      } else {
                        // Если валюта не указана, просто добавляем баланс
                        totalBalanceInRub += account.balance;
                      }
                    }

                    // Безопасная конвертация в целевую валюту
                    final formattedBalance = currencyProvider.formatAmount(
                      totalBalanceInRub,
                      targetCurrency ?? '₽',
                    );

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Все счета',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                            Text(
                              formattedBalance,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } catch (e) {
                    print('ERROR: Currency conversion error: $e');
                    // Возвращаем запасной вариант интерфейса
                    return Text(
                      'Баланс недоступен',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    );
                  }
                },
              ),
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white, size: 28),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => AccountFormModal(
                            initialType: 'Обычный',
                            onSave: (accountData) {
                              setState(() {
                                // Здесь можно добавить обновление необходимых данных
                                // или просто оставить пустым для перестроения виджета
                              });
                            },
                          ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showAccounts = true;
                            });
                          },
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  _showAccounts
                                      ? Color(0xFF2A2935)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Счета',
                              style: TextStyle(
                                color:
                                    _showAccounts
                                        ? Colors.white
                                        : Colors.white54,
                                fontWeight:
                                    _showAccounts
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showAccounts = false;
                            });
                          },
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  !_showAccounts
                                      ? Color(0xFF2A2935)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Мои финансы',
                              style: TextStyle(
                                color:
                                    !_showAccounts
                                        ? Colors.white
                                        : Colors.white54,
                                fontWeight:
                                    !_showAccounts
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DateSelector(
                  initialFilter: _currentFilter,
                  onDateChanged: (filter) {
                    setState(() {
                      _currentFilter = filter;
                    });
                  },
                ),
                Expanded(
                  child:
                      _showAccounts
                          ? _buildAccountsContent()
                          : _buildFinancesContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Модифицируем метод _buildAccountsContent для использования фильтрации по дате
  Widget _buildAccountsContent() {
    return Consumer<AccountsProvider>(
      builder: (context, accountsProvider, _) {
        print(
          'DEBUG: _buildAccountsContent called with ${accountsProvider.accounts.length} accounts',
        );

        // Проверим форматирование каждого счета
        final currencyProvider = Provider.of<CurrencyProvider>(
          context,
          listen: false,
        );
        for (var account in accountsProvider.accounts) {
          final normalizedCurrency = currencyProvider.normalizeSymbol(
            account.currency,
          );
          print(
            'DEBUG: Account ${account.id} (${account.name}): currency=${account.currency} → normalized=$normalizedCurrency',
          );

          // Проверка конвертации
          final converted = currencyProvider.convert(
            account.balance,
            account.currency,
            '₽',
          );
          print(
            'DEBUG: Conversion test: ${account.balance} ${account.currency} = $converted ₽',
          );
        }

        final accounts = accountsProvider.accounts;

        // Если идет загрузка, показываем индикатор загрузки
        if (accountsProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        print(
          'DEBUG: AccountsScreen - Building UI with ${accounts.length} accounts',
        );
        print(
          'DEBUG: AccountsScreen - Account IDs: ${accounts.map((a) => a.id).toList()}',
        );
        print(
          'DEBUG: AccountsScreen - Is provider loading: ${accountsProvider.isLoading}',
        );
        print(
          'DEBUG: AccountsScreen - Provider error: ${accountsProvider.error}',
        );

        // Если список счетов пуст, показываем информативное сообщение
        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'У вас пока нет счетов',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Нажмите + чтобы добавить новый счёт',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final endDate = _currentFilter.endDate ?? DateTime.now();

        // Используем FutureBuilder для асинхронного получения балансов на дату
        return FutureBuilder<Map<String, double>>(
          future: _getAccountBalancesAtDate(
            accounts,
            endDate,
            accountsProvider,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final balances = snapshot.data ?? {};

            // Логика фильтрации счетов по типу
            final regularAccounts =
                accounts
                    .where(
                      (acc) =>
                          acc.accountType == 'обычный' ||
                          acc.accountType == 'credit_card' ||
                          acc.accountType == 'cash',
                    )
                    .toList();

            final savingsAccounts =
                accounts
                    .where(
                      (acc) =>
                          acc.accountType == 'накопительный' ||
                          acc.accountType == 'savings',
                    )
                    .toList();

            // Вычисление общих сумм с использованием исторических данных
            double regularTotal = 0;
            double savingsTotal = 0;

            for (var acc in regularAccounts) {
              regularTotal += balances[acc.id] ?? acc.balance;
            }

            for (var acc in savingsAccounts) {
              savingsTotal += balances[acc.id] ?? acc.balance;
            }

            // Остальной код построения интерфейса остается тем же
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Счета',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyProvider.formatAmount(
                          regularTotal,
                          currencyProvider.displayCurrency,
                        ),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                ...regularAccounts
                    .map(
                      (account) => _buildDismissibleAccount(
                        context,
                        account,
                        accountsProvider,
                      ),
                    )
                    .toList(),
                if (savingsAccounts.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Сбережения',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyProvider.formatAmount(
                            savingsTotal,
                            currencyProvider.displayCurrency,
                          ),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ...savingsAccounts
                    .map(
                      (account) => _buildDismissibleAccount(
                        context,
                        account,
                        accountsProvider,
                      ),
                    )
                    .toList(),
                SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  // Новый метод для асинхронного получения балансов на указанную дату
  Future<Map<String, double>> _getAccountBalancesAtDate(
    List<Account> accounts,
    DateTime date,
    AccountsProvider accountsProvider,
  ) async {
    Map<String, double> result = {};

    try {
      // Если выбрано "все время" или текущий месяц - используем текущие балансы
      if (_currentFilter.type == DateFilterType.allTime ||
          (_currentFilter.type == DateFilterType.month &&
              _currentFilter.startDate!.year == DateTime.now().year &&
              _currentFilter.startDate!.month == DateTime.now().month)) {
        for (var acc in accounts) {
          result[acc.id] = acc.balance;
        }
        return result;
      }

      // Иначе получаем исторические балансы на нужную дату
      for (var acc in accounts) {
        try {
          final historicBalance = await accountsProvider
              .getAccountBalanceAtDate(acc.id, date);
          result[acc.id] = historicBalance;
        } catch (e) {
          print('Ошибка при получении исторического баланса для ${acc.id}: $e');
          // Используем текущий баланс в случае ошибки и продолжаем выполнение
          result[acc.id] = acc.balance;
        }
      }
    } catch (e) {
      print('Ошибка обработки исторических балансов: $e');
      // Заполняем результат текущими балансами в случае общей ошибки
      for (var acc in accounts) {
        result[acc.id] = acc.balance;
      }
    }

    return result;
  }

  Widget _buildFinancesContent() {
    return Consumer<AccountsProvider>(
      builder: (context, accountsProvider, _) {
        final accounts = accountsProvider.accounts;
        final currencyProvider = Provider.of<CurrencyProvider>(
          context,
        ); // Добавьте эту строку
        final Map<String, List<Account>> accountsByCurrency = {};

        for (var account in accounts) {
          if (!accountsByCurrency.containsKey(account.currency)) {
            accountsByCurrency[account.currency] = [];
          }
          accountsByCurrency[account.currency]!.add(account);
        }
        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Мои финансы',
                    style: TextStyle(
                      color: Color(0xFFBFC6FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2935),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildTableRow(
                          currency: "Валюта",
                          assets: Text(
                            "Активы",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          assetsColor: Colors.white,
                          debt: Text(
                            "Долги",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          debtColor: Colors.white,
                          isOdd: true,
                        ),
                        ...accountsByCurrency.entries.map((entry) {
                          final assets = entry.value
                              .where((acc) => acc.balance > 0)
                              .fold<double>(0, (sum, acc) => sum + acc.balance);
                          final debts = entry.value
                              .where((acc) => acc.balance < 0)
                              .fold<double>(
                                0,
                                (sum, acc) => sum + acc.balance.abs(),
                              );
                          final isOdd =
                              accountsByCurrency.keys.toList().indexOf(
                                    entry.key,
                                  ) %
                                  2 !=
                              0;
                          return _buildTableRow(
                            currency: entry.key,
                            assets: Text(
                              currencyProvider.formatAmount(assets, entry.key),
                              style: TextStyle(
                                color:
                                    assets > 0
                                        ? Colors.tealAccent
                                        : Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            assetsColor:
                                assets > 0 ? Colors.tealAccent : Colors.white54,
                            debt: Text(
                              currencyProvider.formatAmount(debts, entry.key),
                              style: TextStyle(
                                color:
                                    debts > 0
                                        ? Colors.pinkAccent
                                        : Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            debtColor:
                                debts > 0 ? Colors.pinkAccent : Colors.white54,
                            isOdd: isOdd,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableRow({
    required String currency,
    required Widget assets, // Изменено с String на Widget
    required Color assetsColor,
    required Widget debt, // Изменено с String на Widget
    required Color debtColor,
    required bool isOdd,
  }) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 60,
          alignment: Alignment.center,
          color: isOdd ? Colors.black26 : Colors.transparent,
          child: Text(
            currency,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 60,
            alignment: Alignment.center,
            color: isOdd ? Colors.black26 : Colors.transparent,
            child: assets, // Теперь используем assets напрямую как виджет
          ),
        ),
        Expanded(
          child: Container(
            height: 60,
            alignment: Alignment.center,
            color: isOdd ? Colors.black26 : Colors.transparent,
            child: debt, // Теперь используем debt напрямую как виджет
          ),
        ),
      ],
    );
  }

  void _showNewAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => AccountFormModal(
            initialType: 'Обычный',
            onSave: (accountData) {
              // Логика сохранения нового счета
            },
          ),
    );
  }

  void _showCurrencySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: Color(0xFF23222A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CurrencySelectionModal(
              onCurrencyChanged: (newCurrency) {
                // Здесь можно добавить логику, которая должна выполняться сразу после выбора валюты
                setState(() {
                  // Принудительное обновление UI
                });
              },
            ),
          ),
    );
  }

  Widget _buildDismissibleAccount(
    BuildContext context,
    Account account,
    AccountsProvider provider,
  ) {
    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (account.isMain) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Нельзя удалить основной счёт'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }

        // Проверяем наличие связанных транзакций
        final transactionsProvider = Provider.of<TransactionsProvider>(
          context,
          listen: false,
        );
        final linkedTransactions =
            transactionsProvider.transactions
                .where((tx) => tx.accountId == account.id)
                .toList();

        if (linkedTransactions.isNotEmpty) {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Color(0xFF2A2935),
                title: Text(
                  'Внимание: счёт содержит транзакции',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Счёт "${account.name}" содержит ${linkedTransactions.length} транзакций. '
                  'При удалении счёта все его транзакции также будут удалены.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Удаляем сначала транзакции, а затем счёт
                      for (var tx in linkedTransactions) {
                        transactionsProvider.deleteTransaction(tx.id, provider);
                      }
                      provider.deleteAccount(account.id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Счёт и все его транзакции удалены'),
                          backgroundColor: Colors.red,
                        ),
                      );

                      Navigator.of(context).pop(true);
                    },
                    child: Text(
                      'Удалить всё',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        }

        // Стандартное подтверждение для счетов без транзакций
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF2A2935),
              title: Text(
                'Удалить счёт',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Вы действительно хотите удалить счёт "${account.name}"?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Отмена', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Удалить', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // Сохраняем копию транзакций перед удалением
        final transactionsProvider = Provider.of<TransactionsProvider>(
          context,
          listen: false,
        );
        final linkedTransactions =
            transactionsProvider.transactions
                .where((tx) => tx.accountId == account.id)
                .toList();

        // Удаляем счет и его транзакции
        provider.deleteAccount(account.id);

        // Удаляем транзакции только если их не удалили на этапе confirmDismiss
        // Проверяем, существуют ли еще транзакции этого счета
        final remainingTransactions =
            transactionsProvider.transactions
                .where((tx) => tx.accountId == account.id)
                .toList();

        if (remainingTransactions.isNotEmpty) {
          for (var tx in remainingTransactions) {
            transactionsProvider.deleteTransaction(tx.id, provider);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Счёт "${account.name}" удалён'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () {
                // Восстанавливаем счет
                provider.addAccount(account);

                // Восстанавливаем транзакции
                for (var tx in linkedTransactions) {
                  transactionsProvider.addTransaction(tx.toJson(), provider);
                }
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: _accountTile(
        icon: account.icon,
        iconColor: account.color,
        title: account.name,
        amount: '${account.balance.toStringAsFixed(2)} ${account.currency}',
        amountColor:
            account.balance >= 0 ? Colors.tealAccent : Colors.pinkAccent,
        isMain: account.isMain,
        account: account,
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount, // Оставляем параметр для обратной совместимости
    required Color amountColor,
    bool isMain = false,
    Account? account,
  }) {
    // Получаем CurrencyProvider
    final currencyProvider =
        account != null
            ? Provider.of<CurrencyProvider>(context, listen: false)
            : null;

    // Форматируем сумму, если возможно
    final formattedAmount =
        (account != null && currencyProvider != null)
            ? currencyProvider.formatAmount(account.balance, account.currency)
            : amount;

    return InkWell(
      onTap:
          account != null
              ? () => _showEditAccountModal(context, account)
              : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                if (isMain)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.star, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedAmount, // Используем отформатированную сумму
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    double amount, {
    bool isExpense = false,
  }) {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final formattedAmount = currencyProvider.formatAmount(
      amount,
      currencyProvider.displayCurrency,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
          Text(
            formattedAmount,
            style: TextStyle(
              color: isExpense ? Colors.pinkAccent : Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAccountModal(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AccountFormModal(
            initialType:
                account.accountType.startsWith('накопительный') ||
                        account.accountType == 'savings'
                    ? 'Накопительный'
                    : 'Обычный',
            accountToEdit: account,
            onSave: (accountData) {
              setState(() {}); // Обновляем UI после редактирования
            },
          ),
    );
  }
}
