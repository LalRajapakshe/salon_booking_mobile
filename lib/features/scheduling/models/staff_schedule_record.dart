class StaffScheduleRecord {
  final int id;
  final int employeeId;
  final int dayOfWeek;
  final String segmentType;
  final String startTime;
  final String endTime;
  final bool isActive;

  const StaffScheduleRecord({
    required this.id,
    required this.employeeId,
    required this.dayOfWeek,
    required this.segmentType,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  String get clockRange {
    String short(String value) => value.length >= 5 ? value.substring(0, 5) : value;
    return '${short(startTime)}–${short(endTime)}';
  }
}

const List<String> staffScheduleDayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/// .NET `DayOfWeek`: Sunday is 0. Dart's `DateTime.weekday` uses Sunday as 7.
int staffScheduleDay(DateTime date) => date.weekday % 7;
