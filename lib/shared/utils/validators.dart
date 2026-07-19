class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final regex = RegExp(
      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!regex.hasMatch(value)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }

    final regex = RegExp(r'^\d{10}$');

    if (!regex.hasMatch(value)) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 6) {
      return 'Password must contain at least 6 characters.';
    }

    return null;
  }

  static String? minLength(
    String? value,
    int length,
  ) {
    if (value == null || value.length < length) {
      return 'Minimum $length characters required.';
    }

    return null;
  }

  static String? maxLength(
    String? value,
    int length,
  ) {
    if (value != null && value.length > length) {
      return 'Maximum $length characters allowed.';
    }

    return null;
  }

  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required.';
    }

    if (num.tryParse(value) == null) {
      return 'Enter a valid number.';
    }

    return null;
  }

  static String? decimal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required.';
    }

    if (double.tryParse(value) == null) {
      return 'Enter a valid decimal number.';
    }

    return null;
  }
}