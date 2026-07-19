import 'package:flutter/material.dart';

import 'currency_formatter.dart';
import 'date_formatter.dart';

extension DateTimeExtension on DateTime? {
  String toFormattedDate() {
    return DateFormatter.format(this);
  }

  String toFormattedDateTime() {
    return DateFormatter.formatDateTime(this);
  }

  String toApiDate() {
    return DateFormatter.toApiDate(this);
  }
}

extension DoubleExtension on double? {
  String toCurrency() {
    return CurrencyFormatter.formatWithSymbol(this);
  }
}

extension IntExtension on int? {
  String toCurrency() {
    return CurrencyFormatter.formatWithSymbol(this);
  }
}

extension StringExtension on String? {
  bool get isNullOrEmpty {
    return this == null || this!.trim().isEmpty;
  }
}

extension BuildContextExtension on BuildContext {
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop(result);
  }

  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  Future<T?> pushReplacement<T>(Widget page) {
    return Navigator.of(this).pushReplacement(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }
}