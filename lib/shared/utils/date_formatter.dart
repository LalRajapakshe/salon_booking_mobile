import 'package:intl/intl.dart';

import 'app_constants.dart';

class DateFormatter {
  DateFormatter._();

  static String format(DateTime? date) {
    if (date == null) return '';

    return DateFormat(
      AppConstants.displayDateFormat,
    ).format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';

    return DateFormat(
      AppConstants.displayDateTimeFormat,
    ).format(date);
  }

  static String toApiDate(DateTime? date) {
    if (date == null) return '';

    return DateFormat(
      AppConstants.apiDateFormat,
    ).format(date);
  }

  static DateTime? fromApiDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateFormat(
      AppConstants.apiDateFormat,
    ).parse(value);
  }
}