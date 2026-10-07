import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = '₹', bool compact = false}) {
    if (compact && amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (compact && amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)} L';
    } else if (compact && amount >= 10000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }

    // Standard Indian number format if symbol is ₹
    try {
      final formatter = symbol == '₹'
          ? NumberFormat.currency(locale: 'en_IN', symbol: symbol, decimalDigits: amount % 1 == 0 ? 0 : 2)
          : NumberFormat.currency(symbol: symbol, decimalDigits: amount % 1 == 0 ? 0 : 2);
      return formatter.format(amount);
    } catch (_) {
      return '$symbol${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
    }
  }

  static String formatPercent(double percent, {bool includeSign = true}) {
    final sign = includeSign && percent > 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
}
