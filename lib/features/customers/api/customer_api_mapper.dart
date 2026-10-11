import '../../../core/api/api_exception.dart';
import '../models/customer_model.dart';

class CustomerApiMapper {
  const CustomerApiMapper._();

  static List<Customer> page(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) customer(item),
    ];
  }

  static int totalPages(Map<String, dynamic> json) {
    final value = json['totalPages'];
    if (value is num && value > 0) return value.toInt();
    return 1;
  }

  static Customer customer(Map<String, dynamic> json) {
    final created = _date(json['createdDate']);
    if (created == null) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return Customer(
      id: _int(json['customerId']),
      customerCode: json['customerCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      mobileNumber: json['mobileNo'] as String? ?? '',
      email: _text(json['email']),
      gender: _text(json['gender']),
      dateOfBirth: _date(json['dateOfBirth']),
      notes: _text(json['remarks']),
      photoPath: _text(json['photoPath']),
      isActive: json['isActive'] == true,
      createdDate: created,
    );
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
