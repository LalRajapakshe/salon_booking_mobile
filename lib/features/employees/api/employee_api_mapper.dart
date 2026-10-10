import '../../../core/api/api_exception.dart';
import '../models/employee_record.dart';

class EmployeeApiMapper {
  const EmployeeApiMapper._();

  static List<EmployeeRecord> page(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) employee(item),
    ];
  }

  static int totalPages(Map<String, dynamic> json) {
    final value = json['totalPages'];
    if (value is num && value > 0) return value.toInt();
    return 1;
  }

  static EmployeeRecord employee(Map<String, dynamic> json) {
    final created = _date(json['createdDate']);
    if (created == null) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return EmployeeRecord(
      id: _int(json['employeeId']),
      employeeCode: json['employeeCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      mobileNo: json['mobileNo'] as String? ?? '',
      email: _text(json['email']),
      gender: _text(json['gender']),
      dateOfBirth: _date(json['dateOfBirth']),
      address: _text(json['address']),
      hireDate: _date(json['hireDate']),
      designation: _text(json['designation']),
      salary: json['salary'] is num ? (json['salary'] as num).toDouble() : 0,
      isActive: json['isActive'] == true,
      createdDate: created,
      branchId: _int(json['branchId']),
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
