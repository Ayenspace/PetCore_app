import 'package:flutter/material.dart';

enum AppCurrency { kes, usd }

class CurrencyProvider extends ChangeNotifier {
  AppCurrency _currency = AppCurrency.kes;

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
    notifyListeners();
  }
}
