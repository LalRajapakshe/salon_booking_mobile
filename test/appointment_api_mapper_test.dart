import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/appointments/api/appointment_api_mapper.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_status.dart';

void main() {
  test('appointment page keeps line employee and time off the header', () {
    final appointments = AppointmentApiMapper.page({
      'totalPages': 1,
      'items': [
        {
          'appointmentId': 10,
          'branchId': 2,
          'customerId': 4,
          'appointmentDate': '2026-10-06',
          'status': 'Confirmed',
          'schedulingState': 'PartiallyScheduled',
          'notes': 'Window seat',
          'services': [
            {
              'appointmentServiceId': 1,
              'appointmentId': 10,
              'serviceId': 7,
              'employeeId': null,
              'startTime': null,
              'endTime': null,
              'durationMinutes': 45,
              'unitPrice': 2500,
              'sequence': 1,
              'isCancelled': false,
              'isFullyScheduled': false,
              'rowVersion': 'AQID',
            },
            {
              'appointmentServiceId': 2,
              'appointmentId': 10,
              'serviceId': 8,
              'employeeId': 3,
              'startTime': '2026-10-06T09:00:00',
              'endTime': '2026-10-06T10:30:00',
              'durationMinutes': 90,
              'unitPrice': 7500.5,
              'sequence': 2,
              'isCancelled': false,
              'isFullyScheduled': true,
              'rowVersion': 'BAUG',
            },
          ],
        },
      ],
    });

    final appointment = appointments.single;
    expect(appointment.status, AppointmentStatus.confirmed);
    expect(appointment.schedulingState, 'PartiallyScheduled');
    expect(appointment.notes, 'Window seat');
    expect(appointment.hasScheduledTime, isTrue);
    expect(appointment.employeeId, 3);
    expect(appointment.startTime.hour, 9);
    expect(appointment.endTime.hour, 10);
    expect(appointment.endTime.minute, 30);

    final unscheduled = appointment.appointmentServices.first;
    expect(unscheduled.employeeId, isNull);
    expect(unscheduled.durationMinutes, 45);
    expect(unscheduled.unitPrice, 2500);
    expect(unscheduled.rowVersion, 'AQID');
    expect(unscheduled.isFullyScheduled, isFalse);

    final scheduled = appointment.appointmentServices.last;
    expect(scheduled.employeeId, 3);
    expect(scheduled.isFullyScheduled, isTrue);
  });
}
