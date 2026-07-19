import 'package:intl/intl.dart';

import 'app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(num? amount) {
    if (amount == null) {
      return '0.00';
    }

    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: AppConstants.currencyDecimalPlaces,
    ).format(amount).trim();
  }

  static String formatWithSymbol(num? amount) {
    return '${AppConstants.currencySymbol} ${format(amount)}';
  }

  static String formatWithoutSymbol(num? amount) {
    return format(amount);
  }
}