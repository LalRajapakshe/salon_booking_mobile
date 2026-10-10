import '../../../core/api/api_exception.dart';
import '../models/employee_availability.dart';

class AvailabilityApiMapper {
  const AvailabilityApiMapper._();

  static List<EmployeeAvailability> employees(List<dynamic> items) {
    return [for (final item in items) employee(item)];
  }

  static EmployeeAvailability employee(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const ApiException('The server returned an unexpected response.');
    }
    final employeeId = _int(json['employeeId']);
    final serviceId = _int(json['serviceId']);
    if (employeeId <= 0 || serviceId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    final slotsJson = json['slots'];
    if (slotsJson is! List) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return EmployeeAvailability(
      employeeId: employeeId,
      employeeName: json['employeeName'] as String? ?? '',
      serviceId: serviceId,
      durationMinutes: _int(json['durationMinutes']),
      slots: [for (final slot in slotsJson) _slot(slot)],
    );
  }

  static AvailabilitySlot _slot(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const ApiException('The server returned an unexpected response.');
    }
    final start = DateTime.tryParse(json['startTime'] as String? ?? '');
    final end = DateTime.tryParse(json['endTime'] as String? ?? '');
    if (start == null || end == null) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return AvailabilitySlot(startTime: start, endTime: end);
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return 0;
  }
}
