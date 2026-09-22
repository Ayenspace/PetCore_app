import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppCurrency { kes, usd }

class CurrencyProvider extends ChangeNotifier {
  static const _currencyKey = 'app_currency';
  AppCurrency _currency = AppCurrency.kes;

  CurrencyProvider() {
    _loadCurrency();
  }

  AppCurrency get currency => _currency;
  bool get isKes => _currency == AppCurrency.kes;

  String get symbol => _currency == AppCurrency.kes ? 'KSh' : '\$';

  String format(double amount) {
    if (_currency == AppCurrency.kes) {
      return 'KSh ${amount.toStringAsFixed(0)}';
    } else {
      // Approximate conversion: 1 USD = 130 KES
      return '\$ ${(amount / 130).toStringAsFixed(2)}';
    }
  }

  void setCurrency(AppCurrency currency) {
    _currency = currency;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_currencyKey, currency.name),
    );
    notifyListeners();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_currencyKey);
    if (saved == null) return;

    final currency = AppCurrency.values.where((item) => item.name == saved);
    if (currency.isEmpty) return;
    _currency = currency.first;
    notifyListeners();
  }
}
