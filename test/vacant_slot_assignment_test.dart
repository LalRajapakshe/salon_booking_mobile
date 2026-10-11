import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_service_line.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_status.dart';
import 'package:salon_booking_mobile/features/appointments/models/employee_availability.dart';
import 'package:salon_booking_mobile/features/scheduling/api/vacant_slot_assignments.dart';
import 'package:salon_booking_mobile/features/scheduling/models/scheduling_models.dart';
import 'package:salon_booking_mobile/features/scheduling/widgets/availability_slot.dart'
    hide AvailabilitySlot;

void main() {
  final day = DateTime(2026, 10, 11);

  Appointment visit({
    required int id,
    required AppointmentStatus status,
    required List<AppointmentServiceLine> lines,
    String customerName = 'Kamal Silva',
  }) {
    return Appointment(
      appointmentId: id,
      branchId: 1,
      customerId: 3,
      appointmentDate: day,
      startTime: const TimeOfDay(hour: 0, minute: 0),
      endTime: const TimeOfDay(hour: 0, minute: 0),
      employeeId: 0,
      status: status,
      customerName: customerName,
      appointmentServices: lines,
    );
  }

  AppointmentServiceLine line({
    required int id,
    required int serviceId,
    int? durationMinutes = 90,
    String? rowVersion = 'rv',
    bool placed = false,
    bool cancelled = false,
    String serviceName = 'Color',
  }) {
    return AppointmentServiceLine(
      appointmentServiceId: id,
      appointmentId: 4,
      serviceId: serviceId,
      durationMinutes: durationMinutes,
      rowVersion: rowVersion,
      isCancelled: cancelled,
      serviceName: serviceName,
      employeeId: placed ? 3 : null,
      startTime: placed ? DateTime(2026, 10, 11, 9, 0) : null,
      endTime: placed ? DateTime(2026, 10, 11, 10, 30) : null,
    );
  }

  List<VacantSlotAssignment> match(List<Appointment> appointments, Map<int, List<AvailabilitySlot>> slots) {
    return VacantSlotAssignments.match(
      appointments: appointments,
      employeeId: 3,
      date: day,
      startMinute: 10 * 60,
      slotsByService: slots,
    );
  }

  test('a service is offered only when its full duration starts at the tapped cell', () {
    final result = match(
      [
        visit(
          id: 4,
          status: AppointmentStatus.pending,
          lines: [
            line(id: 8, serviceId: 2, serviceName: 'Color'),
            line(id: 9, serviceId: 1, durationMinutes: 30, serviceName: 'Haircut'),
          ],
        ),
      ],
      {
        2: [
          AvailabilitySlot(
            startTime: DateTime(2026, 10, 11, 10),
            endTime: DateTime(2026, 10, 11, 11, 30),
          ),
        ],
        1: [
          AvailabilitySlot(
            startTime: DateTime(2026, 10, 11, 10),
            endTime: DateTime(2026, 10, 11, 10, 30),
          ),
        ],
      },
    );

    expect(result.map((item) => item.serviceName), ['Color', 'Haircut']);
    expect(result.first.endTime, DateTime(2026, 10, 11, 11, 30));
  });

  test('a shorter gap, a placed line, and a missing skill are left out', () {
    final result = match(
      [
        visit(
          id: 4,
          status: AppointmentStatus.pending,
          lines: [
            line(id: 8, serviceId: 2),
            line(id: 10, serviceId: 1, durationMinutes: 30, placed: true, serviceName: 'Haircut'),
          ],
        ),
        visit(
          id: 5,
          status: AppointmentStatus.cancelled,
          lines: [line(id: 11, serviceId: 3, durationMinutes: 30, serviceName: 'Trim')],
        ),
      ],
      {
        2: [
          AvailabilitySlot(
            startTime: DateTime(2026, 10, 11, 10),
            endTime: DateTime(2026, 10, 11, 11),
          ),
        ],
        1: [
          AvailabilitySlot(
            startTime: DateTime(2026, 10, 11, 10),
            endTime: DateTime(2026, 10, 11, 10, 30),
          ),
        ],
      },
    );

    expect(result, isEmpty);
  });

  testWidgets('selecting a pending service assigns that service', (tester) async {
    VacantSlotAssignment? assigned;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showOpenSlotDialog(
                    context: context,
                    staff: const SchedulingStaff(staffId: '3', name: 'Tharaka Ashantha', role: 'Stylist'),
                    date: day,
                    startMinute: 10 * 60,
                    loadAssignments: () async {
                      return [
                        VacantSlotAssignment(
                          appointmentId: 4,
                          appointmentServiceId: 8,
                          customerName: 'Kamal Silva',
                          serviceName: 'Color',
                          durationMinutes: 90,
                          rowVersion: 'rv',
                          startTime: DateTime(2026, 10, 11, 10),
                          endTime: DateTime(2026, 10, 11, 11, 30),
                        ),
                      ];
                    },
                    onAssign: (assignment) async {
                      assigned = assignment;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Open time slot'), findsOneWidget);
    expect(find.text('Use this slot'), findsNothing);
    expect(find.textContaining('Kamal Silva · Color · 90 min'), findsOneWidget);

    await tester.tap(find.textContaining('Kamal Silva · Color · 90 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(assigned?.appointmentServiceId, 8);
    expect(assigned?.endTime, DateTime(2026, 10, 11, 11, 30));
    expect(tester.takeException(), isNull);
  });
}
