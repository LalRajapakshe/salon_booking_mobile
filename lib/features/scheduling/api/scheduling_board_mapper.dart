import '../../appointments/models/appointment.dart';
import '../../appointments/models/appointment_service_line.dart';
import '../models/scheduling_models.dart';

class SchedulingBoardDay {
  final List<SchedulingStaff> staff;
  final List<SchedulingAppointment> appointments;
  final List<UnscheduledVisit> unscheduled;

  const SchedulingBoardDay({
    required this.staff,
    required this.appointments,
    this.unscheduled = const [],
  });
}

/// Maps persisted appointment service lines onto the board.
///
/// A line is a booking only when it has an employee, a start, and an end,
/// and it is not cancelled. The block uses those timestamps. A stored
/// duration that does not equal that range is kept and flagged.
class SchedulingBoardMapper {
  const SchedulingBoardMapper._();

  static SchedulingBoardDay map(
    List<Appointment> appointments,
    DateTime day, {
    List<SchedulingStaff> roster = const [],
    Map<int, String> customerNames = const {},
    Map<int, String> serviceNames = const {},
  }) {
    final mapped = <SchedulingAppointment>[];
    final unscheduled = <UnscheduledVisit>[];
    final staff = <String, SchedulingStaff>{
      for (final person in roster) person.staffId: person,
    };

    for (final appointment in appointments) {
      final segments = <SchedulingServiceSegment>[];
      final waiting = <String>[];
      for (final line in appointment.appointmentServices) {
        final segment = _segment(line, day, staff, serviceNames);
        if (segment == null) {
          if (!line.isCancelled) {
            waiting.add(serviceNames[line.serviceId] ?? 'Service ${line.serviceId}');
          }
          continue;
        }
        segments.add(segment);
        staff.putIfAbsent(
          segment.staffId,
          () => SchedulingStaff(
            staffId: segment.staffId,
            name: segment.staffName ?? segment.staffId,
            role: '',
          ),
        );
      }
      final customerName = appointment.customerName ??
          customerNames[appointment.customerId] ??
          'Customer ${appointment.customerId}';
      if (segments.isEmpty) {
        if (waiting.isNotEmpty || appointment.appointmentServices.isEmpty) {
          unscheduled.add(
            UnscheduledVisit(
              reference: appointment.appointmentId.toString(),
              customerName: customerName,
              status: appointment.status.label,
              servicesLabel: waiting.isEmpty ? 'No services' : waiting.join(', '),
            ),
          );
        }
        continue;
      }
      mapped.add(
        SchedulingAppointment(
          reference: appointment.appointmentId.toString(),
          customerName: customerName,
          date: DateTime(day.year, day.month, day.day),
          status: appointment.status.label,
          services: segments,
        ),
      );
    }

    final rows = staff.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return SchedulingBoardDay(staff: rows, appointments: mapped, unscheduled: unscheduled);
  }

  static SchedulingServiceSegment? _segment(
    AppointmentServiceLine line,
    DateTime day,
    Map<String, SchedulingStaff> staff,
    Map<int, String> serviceNames,
  ) {
    final start = line.startTime;
    final end = line.endTime;
    final employeeId = line.employeeId;
    if (line.isCancelled || start == null || end == null) return null;
    if (employeeId == null || employeeId <= 0) return null;
    if (!isSameScheduleDay(start, day)) return null;

    final startMinute = start.hour * 60 + start.minute;
    final span = _rangeMinutes(start, end);
    final endMinute = startMinute + span;
    final duration = line.durationMinutes;
    final staffId = '$employeeId';
    return SchedulingServiceSegment(
      serviceName: line.serviceName ?? serviceNames[line.serviceId] ?? 'Service ${line.serviceId}',
      durationMinutes: duration ?? span,
      staffId: staffId,
      staffName: staff[staffId]?.name ?? 'Employee $employeeId',
      startMinute: startMinute,
      endMinute: endMinute,
      appointmentId: line.appointmentId,
      appointmentServiceId: line.appointmentServiceId,
      serviceId: line.serviceId,
      employeeId: employeeId,
      rowVersion: line.rowVersion,
      durationMismatch: duration != null && duration != span,
    );
  }

  static int _rangeMinutes(DateTime start, DateTime end) {
    final startClock = DateTime(
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
    );
    final endClock = DateTime(
      end.year,
      end.month,
      end.day,
      end.hour,
      end.minute,
    );
    return endClock.difference(startClock).inMinutes;
  }
}
