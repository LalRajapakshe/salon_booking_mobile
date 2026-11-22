import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/models/allocation_recommendation.dart';
import 'package:salon_booking_mobile/features/appointments/screens/allocation_screen.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_service_line.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_status.dart';
import 'package:salon_booking_mobile/features/appointments/models/cancellation_notice.dart';
import 'package:salon_booking_mobile/features/appointments/widgets/cancellation_queue_button.dart';
import 'package:salon_booking_mobile/features/appointments/widgets/cancellation_request_mark.dart';
import 'package:salon_booking_mobile/features/scheduling/api/scheduling_board_mapper.dart';
import 'package:salon_booking_mobile/features/scheduling/models/scheduling_models.dart';
import 'package:salon_booking_mobile/features/scheduling/widgets/appointment_schedule_card.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  test('a pending request is marked on the schedule and a staff cancel is not', () {
    final day = DateTime(2026, 11, 23);
    final mapped = SchedulingBoardMapper.map([
      _appointment(10, 'Requested'),
      _appointment(11, 'None'),
    ], day);

    expect(mapped.appointments.singleWhere((item) => item.reference == '10').cancellationRequested, isTrue);
    expect(mapped.appointments.singleWhere((item) => item.reference == '11').cancellationRequested, isFalse);
    expect(mapped.appointments.singleWhere((item) => item.reference == '10').toBlocks().single.cancellationRequested, isTrue);
  });

  testWidgets('the schedule card shows the request label without replacing the visit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppointmentScheduleCard(
          block: SchedulingBlock(
            blockId: '10',
            staffId: '3',
            date: DateTime(2026, 11, 23),
            kind: ScheduleBlockKind.booked,
            startMinute: 600,
            endMinute: 630,
            title: 'Ada Lovelace',
            subtitle: 'Cut',
            cancellationRequested: true,
          ),
          dimmed: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Cancellation Request'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.byType(CancellationRequestMark), findsOneWidget);
  });

  testWidgets('the queue lists a pending request and drops it after approval', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'manager',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'appointments.read', 'appointments.manage'},
    );
    final repository = _QueueRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [CancellationQueueButton(repository: repository)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('1 notifications'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Cancellation Request'), findsOneWidget);
    expect(find.text('0 new bookings · 1 cancellation request'), findsOneWidget);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('Appointment #41'), findsOneWidget);
    expect(find.text('Approve cancellation'), findsOneWidget);
    await tester.tap(find.text('Approve cancellation'));
    await tester.pumpAndSettle();

    expect(find.text('No notifications are waiting.'), findsOneWidget);
    expect(repository.approvals, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  testWidgets('a new booking stays distinct and asks before a different time is saved', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'manager',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'appointments.read', 'appointments.manage'},
    );
    final repository = _AllocationRepository();
    await tester.pumpWidget(MaterialApp(home: AllocationScreen(repository: repository, appointmentId: 41)));
    await tester.pumpAndSettle();

    expect(find.text('Customer\'s request'), findsOneWidget);
    expect(find.text('Recommended allocations'), findsOneWidget);
    expect(find.text('Best match'), findsOneWidget);
    expect(find.textContaining('Exact requested time'), findsOneWidget);
    await tester.tap(find.text('Alternative 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm allocation'));
    await tester.pumpAndSettle();
    expect(find.text('Requested time is available'), findsOneWidget);
    await tester.tap(find.text('Keep requested time'));
    await tester.pumpAndSettle();
    expect(repository.applied, 0);

    await tester.tap(find.text('Confirm allocation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use the other time'));
    await tester.pumpAndSettle();
    expect(repository.applied, 1);
  });

  testWidgets('a reader can open the request but cannot decide it', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'reader',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'appointments.read'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [CancellationQueueButton(repository: _QueueRepository())],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();

    expect(find.text('Appointment #41'), findsOneWidget);
    expect(find.text('Approve cancellation'), findsNothing);
    expect(find.text('Decline cancellation'), findsNothing);
  });
}

Appointment _appointment(int id, String cancellation) {
  final start = DateTime(2026, 11, 23, 10);
  return Appointment(
    appointmentId: id,
    branchId: 1,
    customerId: 4,
    appointmentDate: DateTime(2026, 11, 23),
    startTime: const TimeOfDay(hour: 10, minute: 0),
    endTime: const TimeOfDay(hour: 10, minute: 30),
    employeeId: 3,
    status: AppointmentStatus.pending,
    cancellationRequest: cancellation,
    customerName: 'Ada Lovelace',
    appointmentServices: [
      AppointmentServiceLine(
        appointmentServiceId: id,
        appointmentId: id,
        serviceId: 15,
        employeeId: 3,
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        serviceName: 'Cut',
      ),
    ],
  );
}

class _AllocationRepository extends AppointmentRepository {
  int applied = 0;

  @override
  Future<AllocationRecommendation> recommendAllocation(int appointmentId) async {
    AllocationOption option(int rank, bool exact, String reason) {
      return AllocationOption(
        rank: rank,
        exactMatch: exact,
        usesPreferredStylist: exact,
        minuteDifference: exact ? 0 : 30,
        dayDifference: 0,
        reason: reason,
        lines: [
          AllocationLine(
            appointmentServiceId: 1,
            serviceName: 'Cut',
            durationMinutes: 30,
            employeeId: 3,
            stylistName: 'Grace',
            startTime: DateTime(2026, 11, 23, exact ? 10 : 10, exact ? 0 : 30),
            endTime: DateTime(2026, 11, 23, exact ? 10 : 11, exact ? 30 : 0),
            rowVersion: 'v1',
          ),
        ],
      );
    }

    return AllocationRecommendation(
      appointmentId: appointmentId,
      requestedDate: DateTime(2026, 11, 23),
      requestedTime: DateTime(2026, 11, 23, 10),
      preferredStylistName: 'Grace',
      serviceNames: const ['Cut'],
      options: [
        option(1, true, 'Exact requested time with the preferred stylist.'),
        option(2, false, 'Closest available time on the requested date.'),
      ],
    );
  }

  @override
  Future<void> applyAllocation({
    required int appointmentId,
    required AllocationOption option,
  }) async {
    applied++;
  }
}

class _QueueRepository extends AppointmentRepository {
  int approvals = 0;
  bool pending = true;

  @override
  Future<List<CancellationNotice>> listCancellationRequests() async {
    if (!pending) return const [];
    return [
      CancellationNotice(
        notificationType: 'CancellationRequest',
        appointmentId: 41,
        customerName: 'Ada Lovelace',
        serviceNames: const ['Cut'],
        serviceName: 'Cut',
        appointmentDate: DateTime(2026, 11, 23),
        appointmentTime: DateTime(2026, 11, 23, 10),
        branchId: 1,
        branchName: 'Negombo',
        requestedAt: DateTime(2026, 11, 22, 9),
        requestState: 'Requested',
      ),
    ];
  }

  @override
  Future<Appointment> approveCancellation({required int appointmentId}) async {
    approvals++;
    pending = false;
    return _appointment(appointmentId, 'Approved');
  }
}
