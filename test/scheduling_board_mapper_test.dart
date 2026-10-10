import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/appointments/api/appointment_api_mapper.dart';
import 'package:salon_booking_mobile/features/scheduling/api/scheduling_board_mapper.dart';
import 'package:salon_booking_mobile/features/scheduling/models/scheduling_models.dart';

void main() {
  const day = '2026-10-10';
  final boardDay = DateTime(2026, 10, 10);

  test('scheduled service lines become separate board bookings', () {
    final dayView = SchedulingBoardMapper.map(
      [
        AppointmentApiMapper.appointment({
          'appointmentId': 42,
          'branchId': 1,
          'customerId': 7,
          'appointmentDate': day,
          'status': 'Confirmed',
          'services': [
            _line(7, 42, 1, 4, '${day}T10:00:00', '${day}T10:30:00', 30, 'AQID'),
            _line(9, 42, 2, 8, '${day}T10:30:00', '${day}T11:30:00', 60, 'BAUG'),
            _line(11, 42, 3, null, null, null, 45, 'CAUG'),
            _line(12, 42, 4, 4, '${day}T12:00:00', '${day}T13:00:00', 60, 'DAUG', cancelled: true),
          ],
        }),
      ],
      boardDay,
    );

    expect(dayView.staff.map((staff) => staff.staffId), ['4', '8']);
    expect(dayView.appointments, hasLength(1));
    final appointment = dayView.appointments.single;
    expect(appointment.reference, '42');
    expect(appointment.customerName, 'Customer 7');
    expect(appointment.status, 'Confirmed');
    expect(appointment.services, hasLength(2));

    final first = appointment.services.first;
    expect(first.appointmentServiceId, 7);
    expect(first.employeeId, 4);
    expect(first.staffName, 'Employee 4');
    expect(first.serviceName, 'Service 1');
    expect(first.rowVersion, 'AQID');
    expect(first.startMinute, 10 * 60);
    expect(first.endMinute - first.startMinute, 30);
    expect(first.durationMismatch, isFalse);

    final second = appointment.services.last;
    expect(second.appointmentServiceId, 9);
    expect(second.employeeId, 8);
    expect(second.endMinute - second.startMinute, 60);
    expect(second.durationMinutes, 60);
  });

  test('board blocks use the timestamp range for 30, 60, 90, and 120 minutes', () {
    final dayView = SchedulingBoardMapper.map(
      [
        AppointmentApiMapper.appointment(
          _appointment(1, day, 'Pending', [
            _line(1, 1, 1, 4, '${day}T10:00:00', '${day}T10:30:00', 30, 'A'),
            _line(2, 1, 2, 8, '${day}T11:00:00', '${day}T12:00:00', 60, 'B'),
            _line(3, 1, 3, 9, '${day}T12:00:00', '${day}T13:30:00', 90, 'C'),
            _line(4, 1, 4, 10, '${day}T14:00:00', '${day}T16:00:00', 120, 'D'),
          ]),
        ),
      ],
      boardDay,
    );

    final spans = [
      for (final segment in dayView.appointments.single.services)
        segment.endMinute - segment.startMinute,
    ];
    expect(spans, [30, 60, 90, 120]);
    expect(
      dayView.appointments.single.services.every((item) => !item.durationMismatch),
      isTrue,
    );
  });

  test('a duration that disagrees with the timestamps is reported and not corrected', () {
    final segment = SchedulingBoardMapper.map(
      [
        AppointmentApiMapper.appointment(
          _appointment(5, day, 'Confirmed', [
            _line(15, 5, 6, 11, '${day}T10:00:00', '${day}T11:30:00', 30, 'E'),
          ]),
        ),
      ],
      boardDay,
    ).appointments.single.services.single;

    expect(segment.durationMinutes, 30);
    expect(segment.startMinute, 10 * 60);
    expect(segment.endMinute, 11 * 60 + 30);
    expect(segment.durationMismatch, isTrue);
  });

  test('lines on another day are left off the selected board date', () {
    final dayView = SchedulingBoardMapper.map(
      [
        AppointmentApiMapper.appointment(
          _appointment(8, day, 'Confirmed', [
            _line(1, 8, 1, 4, '${day}T10:00:00', '${day}T10:30:00', 30, 'A'),
          ]),
        ),
        AppointmentApiMapper.appointment(
          _appointment(9, '2026-10-11', 'Confirmed', [
            _line(2, 9, 1, 8, '2026-10-11T09:00:00', '2026-10-11T09:30:00', 30, 'B'),
          ]),
        ),
        AppointmentApiMapper.appointment(
          _appointment(10, day, 'Pending', [
            _line(3, 10, 2, 9, '2026-10-11T10:00:00', '2026-10-11T11:00:00', 60, 'C'),
          ]),
        ),
      ],
      boardDay,
    );

    expect(dayView.appointments.map((item) => item.reference), ['8']);
    expect(dayView.staff.single.staffId, '4');
  });

  test('an appointment with no scheduled lines produces no booking', () {
    final dayView = SchedulingBoardMapper.map(
      [
        AppointmentApiMapper.appointment(
          _appointment(3, day, 'Pending', [
            _line(1, 3, 1, null, null, null, 30, 'A'),
            _line(
              2,
              3,
              2,
              4,
              '${day}T10:00:00',
              '${day}T10:30:00',
              30,
              'B',
              cancelled: true,
            ),
          ]),
        ),
      ],
      boardDay,
    );

    expect(dayView.appointments, isEmpty);
    expect(dayView.staff, isEmpty);
    expect(dayView.unscheduled.single.customerName, 'Customer 3');
    expect(dayView.unscheduled.single.servicesLabel, 'Service 1');
    expect(dayView.unscheduled.single.status, 'Pending');
  });

  test('saved employees stay on the board and use stored names', () {
    final dayView = SchedulingBoardMapper.map(
      [
        AppointmentApiMapper.appointment(
          _appointment(3, day, 'Pending', [
            _line(1, 3, 4, null, null, null, 30, 'A'),
          ]),
        ),
      ],
      boardDay,
      roster: const [
        SchedulingStaff(staffId: '9', name: 'Nimal Perera', role: 'Stylist'),
      ],
      customerNames: const {3: 'Kamal Silva'},
      serviceNames: const {4: 'Beard Trim'},
    );

    expect(dayView.staff.single.name, 'Nimal Perera');
    expect(dayView.appointments, isEmpty);
    expect(dayView.unscheduled.single.customerName, 'Kamal Silva');
    expect(dayView.unscheduled.single.servicesLabel, 'Beard Trim');
  });
}

Map<String, dynamic> _appointment(
  int id,
  String date,
  String status,
  List<Map<String, dynamic>> services,
) {
  return {
    'appointmentId': id,
    'branchId': 1,
    'customerId': id,
    'appointmentDate': date,
    'status': status,
    'services': services,
  };
}

Map<String, dynamic> _line(
  int id,
  int appointmentId,
  int serviceId,
  int? employeeId,
  String? start,
  String? end,
  int duration,
  String rowVersion, {
  bool cancelled = false,
}) {
  return {
    'appointmentServiceId': id,
    'appointmentId': appointmentId,
    'serviceId': serviceId,
    'employeeId': employeeId,
    'startTime': start,
    'endTime': end,
    'durationMinutes': duration,
    'isCancelled': cancelled,
    'isFullyScheduled': employeeId != null && start != null && !cancelled,
    'rowVersion': rowVersion,
  };
}
