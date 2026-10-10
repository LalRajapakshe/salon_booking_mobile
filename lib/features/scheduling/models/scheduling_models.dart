/// Presentation types for the staff board.
///
/// A signed-in board maps each scheduled appointment service line into
/// these types. Employee and time belong to the line. Signed-out and
/// widget tests keep the local demo data.
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
  final String? staffName;
  final int? appointmentId;
  final int? appointmentServiceId;
  final int? serviceId;
  final int? employeeId;
  final String? rowVersion;
  final bool durationMismatch;

  const SchedulingServiceSegment({
    required this.serviceName,
    required this.durationMinutes,
    required this.staffId,
    required this.startMinute,
    required this.endMinute,
    this.conflict = false,
    this.staffName,
    this.appointmentId,
    this.appointmentServiceId,
    this.serviceId,
    this.employeeId,
    this.rowVersion,
    this.durationMismatch = false,
  });
}

class UnscheduledVisit {
  final String reference;
  final String customerName;
  final String status;
  final String servicesLabel;

  const UnscheduledVisit({
    required this.reference,
    required this.customerName,
    required this.status,
    required this.servicesLabel,
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
          blockId: segment.appointmentServiceId == null
              ? '$reference-${segment.staffId}-${segment.startMinute}'
              : '$reference-${segment.appointmentServiceId}',
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
          notice: segment.durationMismatch
              ? 'Duration ${segment.durationMinutes} min does not match this time.'
              : null,
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
  final String? notice;

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
    this.notice,
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
