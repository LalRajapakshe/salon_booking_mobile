/// Presentation-only scheduling types for the staff board.
///
/// These are not Appointment or AppointmentService fields. The existing
/// domain keeps employee and time on the appointment header. This board
/// uses its own mock data so a service can be shown on a different
/// employee and time without changing those models.
enum ScheduleBlockKind { booked, onBreak, leave, offDuty }

enum StaffDayState { open, busy, leave, offDuty }

class SchedulingStaff {
  final String staffId;
  final String name;
  final String role;

  const SchedulingStaff({
    required this.staffId,
    required this.name,
    required this.role,
  });

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class SchedulingServiceSegment {
  final String serviceName;
  final int durationMinutes;
  final String staffId;
  final int startMinute;
  final int endMinute;
  final bool conflict;

  const SchedulingServiceSegment({
    required this.serviceName,
    required this.durationMinutes,
    required this.staffId,
    required this.startMinute,
    required this.endMinute,
    this.conflict = false,
  });
}

class SchedulingAppointment {
  final String reference;
  final String customerName;
  final DateTime date;
  final String status;
  final List<SchedulingServiceSegment> services;

  const SchedulingAppointment({
    required this.reference,
    required this.customerName,
    required this.date,
    required this.status,
    required this.services,
  });

  int get startMinute =>
      services.map((item) => item.startMinute).reduce((a, b) => a < b ? a : b);

  int get endMinute =>
      services.map((item) => item.endMinute).reduce((a, b) => a > b ? a : b);

  List<SchedulingBlock> toBlocks() {
    return [
      for (final segment in services)
        SchedulingBlock(
          blockId: '$reference-${segment.staffId}-${segment.startMinute}',
          staffId: segment.staffId,
          date: date,
          kind: ScheduleBlockKind.booked,
          startMinute: segment.startMinute,
          endMinute: segment.endMinute,
          appointmentReference: reference,
          title: customerName,
          subtitle: segment.serviceName,
          status: status,
          conflict: segment.conflict,
        ),
    ];
  }
}

class SchedulingBlock {
  final String blockId;
  final String staffId;
  final DateTime date;
  final ScheduleBlockKind kind;
  final int startMinute;
  final int endMinute;
  final String? appointmentReference;
  final String title;
  final String subtitle;
  final String? status;
  final bool conflict;

  const SchedulingBlock({
    required this.blockId,
    required this.staffId,
    required this.date,
    required this.kind,
    required this.startMinute,
    required this.endMinute,
    this.appointmentReference,
    required this.title,
    required this.subtitle,
    this.status,
    this.conflict = false,
  });

  bool coversMinute(int minute) {
    return minute >= startMinute && minute < endMinute;
  }
}

class StaffDaySummary {
  final String label;
  final StaffDayState state;

  const StaffDaySummary(this.label, this.state);
}

class SuggestedService {
  final String name;
  final int durationMinutes;

  const SuggestedService({required this.name, required this.durationMinutes});
}

class SuggestedAssignment {
  final String serviceName;
  final String staffName;
  final int startMinute;
  final int endMinute;

  const SuggestedAssignment({
    required this.serviceName,
    required this.staffName,
    required this.startMinute,
    required this.endMinute,
  });
}

class SuggestedSchedule {
  final String windowLabel;
  final List<SuggestedAssignment> assignments;

  const SuggestedSchedule({
    required this.windowLabel,
    required this.assignments,
  });
}

class AvailabilitySuggestion {
  final String customerName;
  final List<SuggestedService> services;
  final List<SuggestedSchedule> options;

  const AvailabilitySuggestion({
    required this.customerName,
    required this.services,
    required this.options,
  });
}

const int scheduleDayStartMinute = 9 * 60;
const int scheduleDayEndMinute = 18 * 60;
const int scheduleSlotMinutes = 30;

int get scheduleSlotCount =>
    (scheduleDayEndMinute - scheduleDayStartMinute) ~/ scheduleSlotMinutes;

bool isSameScheduleDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatScheduleTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String formatScheduleRange(int startMinute, int endMinute) {
  return '${formatScheduleTime(startMinute)} – ${formatScheduleTime(endMinute)}';
}

String formatScheduleDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
