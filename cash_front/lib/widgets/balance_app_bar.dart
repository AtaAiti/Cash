// Создайте общий виджет для всех экранов

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/widgets/date_selector.dart';
import 'package:cash_flip_app/main.dart';
import 'package:cash_flip_app/providers/currency_provider.dart';

class BalanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final DateFilter? currentFilter;
  final Function(DateFilter)? onFilterChanged;

  const BalanceAppBar({
    Key? key,
    required this.title,
    this.actions = const [],
    this.currentFilter,
    this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balance = BalanceData.calculateFromProviders(
      context,
      filter: currentFilter,
    );
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

    return AppBar(
      backgroundColor: Color(0xFF23222A),
      elevation: 0,
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
      actions: actions,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
          SizedBox(width: 12),
          Text(
            currencyProvider.formatAmount(balance.totalBalance, currencyProvider.displayCurrency),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      bottom:
          currentFilter != null && onFilterChanged != null
              ? PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: DateSelector(
                  initialFilter: currentFilter!,
                  onDateChanged: onFilterChanged!,
                ),
              )
              : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(currentFilter != null ? 100 : 56);
}
