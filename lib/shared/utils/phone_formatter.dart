class PhoneFormatter {
  PhoneFormatter._();

  static String format(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '';
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) {
      return phone;
    }

    return '${digits.substring(0, 3)} '
        '${digits.substring(3, 6)} '
        '${digits.substring(6)}';
  }

  static String removeFormatting(String? phone) {
    if (phone == null) {
      return '';
    }

    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static bool isValid(String? phone) {
    if (phone == null) {
      return false;
    }

    return RegExp(r'^\d{10}$').hasMatch(
      removeFormatting(phone),
    );
  }

  static String normalize(String? phone) {
    return removeFormatting(phone);
  }
}