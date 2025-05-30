import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/accounts_provider.dart';

class AccountFormModal extends StatefulWidget {
  final String initialType;
  final Function(Map<String, dynamic>)? onSave;
  final Account? accountToEdit; // Добавьте это свойство

  const AccountFormModal({
    Key? key,
    required this.initialType,
    this.onSave,
    this.accountToEdit, // Добавьте параметр
  }) : super(key: key);

  @override
  _AccountFormModalState createState() => _AccountFormModalState();
}

class _AccountFormModalState extends State<AccountFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _accountType = '';
  String _currency = '₽';
  String _currencyName = 'Российский рубль — ₽';
  Color _accountColor = Colors.blue;
  IconData _accountIcon = Icons.account_balance_wallet;

  // Доступные валюты
  final Map<String, String> _availableCurrencies = {
    '₽': 'Российский рубль — ₽',
    '\$': 'Доллар США — \$',
    '€': 'Евро — €',
    '£': 'Фунт стерлингов — £',
    '¥': 'Японская йена — ¥',
  };

  // Доступные типы счетов
  final Map<String, String> _accountTypes = {
    'Обычный': 'Наличные, карта, ...',
    'Накопительный': 'Сбережения, цель, ...',
  };

  // Доступные иконки для счетов
  final List<IconData> _accountIcons = [
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.savings,
    Icons.monetization_on,
    Icons.currency_exchange,
    Icons.account_balance,
    Icons.money,
    Icons.euro,
  ];

  // Доступные цвета для счетов
  final List<Color> _accountColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _accountType = widget.initialType;

    // Если редактируем существующий счет, заполняем форму данными
    if (widget.accountToEdit != null) {
      _nameController.text = widget.accountToEdit!.name;
      _descriptionController.text = widget.accountToEdit!.description ?? '';
      _accountType =
          widget.accountToEdit!.accountType.startsWith('накопительный') ||
                  widget.accountToEdit!.accountType == 'savings'
              ? 'Накопительный'
              : 'Обычный';
      _accountIcon = widget.accountToEdit!.icon;
      _accountColor = widget.accountToEdit!.color;
      _currency = widget.accountToEdit!.currency;
    } else {
      // Настройка иконки по умолчанию в зависимости от типа
      if (_accountType == 'Накопительный') {
        _accountIcon = Icons.savings;
        _accountColor = Colors.amber;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Показать диалог выбора типа счета
  void _showAccountTypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF23222A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Выберите тип счета',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  children:
                      _accountTypes.entries.map((entry) {
                        return ListTile(
                          leading: Icon(
                            entry.key == 'Накопительный'
                                ? Icons.savings
                                : Icons.account_balance_wallet,
                            color: Colors.white,
                          ),
                          title: Text(
                            entry.key,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            entry.value,
                            style: TextStyle(color: Colors.white70),
                          ),
                          selected: _accountType == entry.key,
                          selectedTileColor: Colors.white10,
                          onTap: () {
                            setState(() {
                              _accountType = entry.key;
                              // Обновляем иконку, если меняется тип
                              if (_accountType == 'Накопительный') {
                                _accountIcon = Icons.savings;
                                _accountColor = Colors.amber;
                              } else {
                                _accountIcon = Icons.account_balance_wallet;
                                _accountColor = Colors.blue;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Показать диалог выбора валюты
  void _showCurrencyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF23222A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Выберите валюту',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  children:
                      _availableCurrencies.entries.map((entry) {
                        final symbol = entry.key;
                        final name = entry.value;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(color: Colors.white),
                          ),
                          selected: _currency == symbol,
                          selectedTileColor: Colors.white10,
                          onTap: () {
                            setState(() {
                              _currency = symbol;
                              _currencyName = name;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Показать диалог выбора цвета
  void _showColorIconDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF23222A),
          title: Text(
            'Выберите цвет и иконку',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Цвет счета', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      _accountColors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _accountColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border:
                                  _accountColor == color
                                      ? Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      )
                                      : null,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: 20),
                Text('Иконка счета', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      _accountIcons.map((icon) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _accountIcon = icon;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  _accountIcon == icon
                                      ? _accountColor
                                      : Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color:
                                  _accountIcon == icon
                                      ? Colors.white
                                      : Colors.white70,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Готово', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Color(0xFF5B6CF6)),
            ),
          ],
        );
      },
    );
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      // Создаем данные счета с уникальным ID или используем существующий ID
      final String uniqueId =
          widget.accountToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final accountData = {
        'id': uniqueId,
        'name': _nameController.text,
        'accountType': _accountType.toLowerCase(),
        'balance':
            widget.accountToEdit?.balance ??
            0.0, // Сохраняем баланс при редактировании
        'currency': _currency,
        'description': _descriptionController.text,
        'icon': _accountIcon,
        'color': _accountColor,
        'isMain': widget.accountToEdit?.isMain ?? false,
      };

      final accountsProvider = Provider.of<AccountsProvider>(
        context,
        listen: false,
      );

      if (widget.accountToEdit != null) {
        // Обновляем существующий счет
        final updatedAccount = Account(
          id: accountData['id'] as String,
          name: accountData['name'] as String,
          accountType: accountData['accountType'] as String,
          balance: accountData['balance'] as double,
          currency: accountData['currency'] as String,
          icon: accountData['icon'] as IconData,
          color: accountData['color'] as Color,
          isMain: accountData['isMain'] as bool,
          description: accountData['description'] as String, 
        );

        accountsProvider.updateAccount(updatedAccount);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Счет успешно обновлен!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Добавляем новый счет (существующая логика)
        final newAccount = Account(
          id: accountData['id'] as String,
          name: accountData['name'] as String,
          accountType: accountData['accountType'] as String,
          balance: accountData['balance'] as double,
          currency: accountData['currency'] as String,
          icon: accountData['icon'] as IconData,
          color: accountData['color'] as Color,
          isMain: accountData['isMain'] as bool,
        );

        accountsProvider.addAccount(newAccount);

        // Показываем уведомление об успешном добавлении
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Счет успешно добавлен!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Вызываем колбэк onSave, если он предоставлен
      if (widget.onSave != null) {
        widget.onSave!(accountData);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Color(0xFF23222A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Новый счёт',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: _saveAccount,
              child: Text(
                'Готово',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF5B6CF6),
                padding: EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Account Name
              Text(
                'Название',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Счёт',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5B6CF6)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название счёта';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Card Icon and Color (clickable)
              GestureDetector(
                onTap: _showColorIconDialog,
                child: Row(
                  children: [
                    Text(
                      'Внешний вид',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Spacer(),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _accountColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_accountIcon, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Account Type
              InkWell(
                onTap: _showAccountTypeDialog,
                child: _buildInfoRow(
                  icon: Icons.account_balance_wallet,
                  label: 'Тип',
                  value: _accountType,
                ),
              ),
              SizedBox(height: 24),

              // Currency
              InkWell(
                onTap: _showCurrencyDialog,
                child: _buildInfoRow(
                  icon: Icons.monetization_on,
                  label: 'Валюта счёта',
                  value: _currencyName,
                ),
              ),
              SizedBox(height: 24),

              // Description
              Text(
                'Описание',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Описание (необязательно)',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5B6CF6)),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white70, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : label,
                style: TextStyle(
                  color: value.isNotEmpty ? Colors.white : Colors.white38,
                  fontSize: 16,
                  fontWeight:
                      value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              SizedBox(height: 8),
              Divider(color: Colors.white24, height: 1),
            ],
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      ],
    );
  }
}
