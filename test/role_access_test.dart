import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/core/auth/staff_access.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/models/cancellation_notice.dart';
import 'package:salon_booking_mobile/features/appointments/widgets/cancellation_queue_button.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  const receptionist = {
    'appointments.read',
    'appointments.manage',
    'customers.read',
    'customers.manage',
    'services.read',
    'branches.read',
    'schedules.read',
    'availability.read',
    'notifications.bookings.read',
    'notifications.cancellations.read',
    'notifications.confirmation.read',
    'appointments.lines.progress',
  };

  const stylist = {
    'appointments.own.read',
  };

  const supervisor = {
    'appointments.read',
    'schedules.read',
    'appointments.lines.progress',
  };

  test('receptionist sees the front desk and not employee or user administration', () {
    _signIn(receptionist);
    final session = AuthSession.instance;
    expect(StaffAccess.seesFrontDesk(session), isTrue);
    expect(StaffAccess.canManageAppointments(session), isTrue);
    expect(StaffAccess.seesNotificationQueue(session), isTrue);
    expect(StaffAccess.seesEmployees(session), isFalse);
    expect(StaffAccess.seesUsers(session), isFalse);
    expect(StaffAccess.seesOwnAppointments(session), isFalse);
    expect(StaffAccess.canProgressLine(session, 9), isTrue);
    expect(StaffAccess.canManageAppointments(session), isTrue);
  });

  test('stylist sees only assigned appointments', () {
    _signIn(stylist, employeeId: 9);
    final session = AuthSession.instance;
    expect(StaffAccess.seesOwnAppointments(session), isTrue);
    expect(StaffAccess.seesAppointmentBook(session), isFalse);
    expect(StaffAccess.seesNotificationQueue(session), isFalse);
    expect(StaffAccess.seesFrontDesk(session), isFalse);
    expect(StaffAccess.seesEmployees(session), isFalse);
    expect(StaffAccess.canManageAppointments(session), isFalse);
    expect(AppointmentRepository().readsOwnBookOnly, isTrue);
    expect(StaffAccess.canProgressLine(session, 9), isFalse);
    expect(StaffAccess.canProgressLine(session, 10), isFalse);
    expect(StaffAccess.canReadLineHistory(session, 9), isTrue);
    expect(StaffAccess.canReadLineHistory(session, 10), isFalse);
  });

  test('supervisor does not receive the notification queue or appointment management', () {
    _signIn(supervisor);
    final session = AuthSession.instance;
    expect(StaffAccess.seesAppointmentBook(session), isTrue);
    expect(StaffAccess.seesNotificationQueue(session), isFalse);
    expect(StaffAccess.canManageAppointments(session), isFalse);
    expect(StaffAccess.seesEmployees(session), isFalse);
    expect(StaffAccess.seesUsers(session), isFalse);
    expect(StaffAccess.canProgressLine(session, 4), isTrue);
    expect(StaffAccess.canManageAppointments(session), isFalse);
  });

  test('receptionist and supervisor together keep the union without employee administration', () {
    _signIn({...receptionist, ...supervisor});
    final session = AuthSession.instance;
    expect(StaffAccess.seesFrontDesk(session), isTrue);
    expect(StaffAccess.seesNotificationQueue(session), isTrue);
    expect(StaffAccess.canManageAppointments(session), isTrue);
    expect(StaffAccess.seesEmployees(session), isFalse);
    expect(StaffAccess.seesUsers(session), isFalse);
    expect(StaffAccess.canProgressLine(session, 4), isTrue);
  });

  testWidgets('the notification button follows the category permission', (tester) async {
    _signIn(stylist);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CancellationQueueButton(),
        ),
      ),
    );
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);

    _signIn({'notifications.bookings.read'});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CancellationQueueButton(repository: _QuietRepository()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('appointments.read alone does not open the notification queue', (tester) async {
    _signIn({'appointments.read', 'appointments.manage'});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CancellationQueueButton(),
        ),
      ),
    );
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
  });
}

void _signIn(Set<String> permissions, {int? employeeId}) {
  AuthSession.instance.save(
    accessToken: 'token',
    username: 'staff',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    employeeId: employeeId,
    permissions: permissions,
  );
}

class _QuietRepository extends AppointmentRepository {
  _QuietRepository() : super(session: AuthSession.instance);

  @override
  Future<List<CancellationNotice>> listCancellationRequests({int? branchId}) async => const [];
}
