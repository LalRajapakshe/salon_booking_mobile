import '../../../core/api/api_exception.dart';
import '../models/staff_schedule_record.dart';

class StaffScheduleApiMapper {
  const StaffScheduleApiMapper._();

  static List<StaffScheduleRecord> list(List<dynamic> json) {
    return [
      for (final item in json)
        if (item is Map<String, dynamic>) record(item),
    ];
  }

  static StaffScheduleRecord record(Map<String, dynamic> json) {
    final id = _int(json['staffScheduleId']);
    final employeeId = _int(json['employeeId']);
    final day = _int(json['dayOfWeek']);
    final start = json['startTime'] as String? ?? '';
    final end = json['endTime'] as String? ?? '';
    if (id <= 0 || employeeId <= 0 || day < 0 || day > 6 || start.isEmpty || end.isEmpty) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return StaffScheduleRecord(
      id: id,
      employeeId: employeeId,
      dayOfWeek: day,
      segmentType: json['segmentType'] as String? ?? '',
      startTime: start,
      endTime: end,
      isActive: json['isActive'] == true,
    );
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? -1;
  }
}
