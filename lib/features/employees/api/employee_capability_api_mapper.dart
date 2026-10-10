import '../../../core/api/api_exception.dart';
import '../models/employee_capability_record.dart';

class EmployeeCapabilityApiMapper {
  const EmployeeCapabilityApiMapper._();

  static List<EmployeeCapabilityRecord> list(List<dynamic> json) {
    return [
      for (final item in json)
        if (item is Map<String, dynamic>) record(item),
    ];
  }

  static EmployeeCapabilityRecord record(Map<String, dynamic> json) {
    final id = _int(json['employeeServiceId']);
    final employeeId = _int(json['employeeId']);
    final serviceId = _int(json['serviceId']);
    if (id <= 0 || employeeId <= 0 || serviceId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return EmployeeCapabilityRecord(
      id: id,
      employeeId: employeeId,
      serviceId: serviceId,
      isActive: json['isActive'] == true,
    );
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
