import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/currency_provider.dart';

class CurrencySelectionModal extends StatelessWidget {
  final Function(String)? onCurrencyChanged;

  const CurrencySelectionModal({Key? key, this.onCurrencyChanged})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );

    // Перемещаем selectCurrency внутрь build
    void selectCurrency(String currency) {
      currencyProvider.setDisplayCurrency(currency);

      // Вызываем колбэк для обновления родительского виджета
      if (onCurrencyChanged != null) {
        onCurrencyChanged!(currency);
      }

      Navigator.pop(context);
    }

    final availableCurrencies = {
      '₽': 'Российский рубль — ₽',
      '\$': 'Доллар США — \$',
      '€': 'Евро — €',
      '£': 'Фунт стерлингов — £',
      '¥': 'Японская йена — ¥',
    };

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
                  'Выберите валюту отображения',
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
          if (currencyProvider.isLoading)
            Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children:
                  availableCurrencies.entries.map((entry) {
                    final symbol = entry.key;
                    final name = entry.value;
                    final isSelected =
                        currencyProvider.currentCurrency == symbol;

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
                      title: Text(name, style: TextStyle(color: Colors.white)),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: Color(0xFF5B6CF6),
                              )
                              : null,
                      selected: isSelected,
                      selectedTileColor: Colors.white10,
                      onTap: () {
                        selectCurrency(symbol);
                      },
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
