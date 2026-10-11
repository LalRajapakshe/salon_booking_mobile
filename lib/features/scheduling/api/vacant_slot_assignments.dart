import '../../appointments/models/appointment.dart';
import '../../appointments/models/appointment_service_line.dart';
import '../../appointments/models/appointment_status.dart';
import '../../appointments/models/employee_availability.dart';

/// One unplaced service that can start on this employee at the tapped cell.
class VacantSlotAssignment {
  final int appointmentId;
  final int appointmentServiceId;
  final String customerName;
  final String serviceName;
  final int durationMinutes;
  final String rowVersion;
  final DateTime startTime;
  final DateTime endTime;

  const VacantSlotAssignment({
    required this.appointmentId,
    required this.appointmentServiceId,
    required this.customerName,
    required this.serviceName,
    required this.durationMinutes,
    required this.rowVersion,
    required this.startTime,
    required this.endTime,
  });
}

class VacantSlotAssignments {
  const VacantSlotAssignments._();

  /// Keeps unplaced services whose saved duration fits a real free slot
  /// that starts at [startMinute] for this employee.
  static List<VacantSlotAssignment> match({
    required List<Appointment> appointments,
    required int employeeId,
    required DateTime date,
    required int startMinute,
    required Map<int, List<AvailabilitySlot>> slotsByService,
    Map<int, String> customerNames = const {},
    Map<int, String> serviceNames = const {},
  }) {
    if (employeeId <= 0) return const [];
    final matches = <VacantSlotAssignment>[];
    for (final appointment in appointments) {
      if (!_open(appointment.status)) continue;
      for (final line in appointment.appointmentServices) {
        final assignment = _line(
          appointment,
          line,
          date,
          startMinute,
          slotsByService[line.serviceId] ?? const [],
          customerNames,
          serviceNames,
        );
        if (assignment != null) matches.add(assignment);
      }
    }
    return matches;
  }

  static bool _open(AppointmentStatus status) {
    return status != AppointmentStatus.cancelled &&
        status != AppointmentStatus.completed &&
        status != AppointmentStatus.noShow;
  }

  static VacantSlotAssignment? _line(
    Appointment appointment,
    AppointmentServiceLine line,
    DateTime date,
    int startMinute,
    List<AvailabilitySlot> slots,
    Map<int, String> customerNames,
    Map<int, String> serviceNames,
  ) {
    if (line.isCancelled || line.appointmentServiceId <= 0) return null;
    if (line.rowVersion == null || line.rowVersion!.isEmpty) return null;
    if (_placed(line)) return null;
    final duration = line.durationMinutes;
    if (duration == null || duration <= 0) return null;

    for (final slot in slots) {
      final span = slot.endTime.difference(slot.startTime).inMinutes;
      if (span != duration) continue;
      if (!_sameStart(slot.startTime, date, startMinute)) continue;
      final customer = appointment.customerName ??
          customerNames[appointment.customerId] ??
          'Customer ${appointment.customerId}';
      final service = line.serviceName ??
          serviceNames[line.serviceId] ??
          'Service ${line.serviceId}';
      return VacantSlotAssignment(
        appointmentId: appointment.appointmentId,
        appointmentServiceId: line.appointmentServiceId,
        customerName: customer,
        serviceName: service,
        durationMinutes: duration,
        rowVersion: line.rowVersion!,
        startTime: slot.startTime,
        endTime: slot.endTime,
      );
    }
    return null;
  }

  static bool _placed(AppointmentServiceLine line) {
    final employeeId = line.employeeId;
    return line.startTime != null &&
        line.endTime != null &&
        employeeId != null &&
        employeeId > 0;
  }

  static bool _sameStart(DateTime start, DateTime date, int startMinute) {
    return start.year == date.year &&
        start.month == date.month &&
        start.day == date.day &&
        start.hour * 60 + start.minute == startMinute;
  }
}
