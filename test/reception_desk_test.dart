import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/api/api_exception.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_status.dart';
import 'package:salon_booking_mobile/features/appointments/screens/create_appointment_screen.dart';
import 'package:salon_booking_mobile/features/customers/data/customer_repository.dart';
import 'package:salon_booking_mobile/features/customers/models/customer_model.dart';
import 'package:salon_booking_mobile/features/reception/data/reception_repository.dart';
import 'package:salon_booking_mobile/features/reception/models/reception_visit.dart';
import 'package:salon_booking_mobile/features/reception/screens/reception_desk_screen.dart';
import 'package:salon_booking_mobile/features/reception/widgets/walk_in_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDesk(WidgetTester tester, ReceptionRepository repository, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: ReceptionDeskScreen(repository: repository)));
    await tester.pumpAndSettle();
  }

  testWidgets('signed-out desk shows the sample day', (tester) async {
    await pumpDesk(tester, ReceptionRepository(), const Size(1200, 900));

    expect(find.text('Sample day from the demo catalog. Sign in for today’s appointments.'), findsOneWidget);
    expect(find.text('Sarah Perera'), findsOneWidget);
    expect(find.text('Hair Cut'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desk stays readable on a phone width', (tester) async {
    await pumpDesk(tester, ReceptionRepository(), const Size(390, 800));

    expect(find.text('Reception Desk'), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and status filter hide other visits', (tester) async {
    final repository = _FixedDesk([
      _visit(id: 1, name: 'Nimal Perera', mobile: '0771111111', status: AppointmentStatus.pending),
      _visit(id: 2, name: 'Amal Fernando', mobile: '0772222222', status: AppointmentStatus.checkedIn),
    ]);
    await pumpDesk(tester, repository, const Size(1200, 900));

    expect(find.text('Nimal Perera'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Amal');
    await tester.pump();
    expect(find.text('Nimal Perera'), findsNothing);
    expect(find.text('Amal Fernando'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Checked in'));
    await tester.pump();
    expect(find.text('Nimal Perera'), findsNothing);
    expect(find.text('Amal Fernando'), findsOneWidget);
  });

  testWidgets('empty list explains that nothing matches', (tester) async {
    await pumpDesk(tester, _FixedDesk(const []), const Size(800, 700));
    expect(find.text('No appointments match this view.'), findsOneWidget);
  });

  testWidgets('a failed load shows the error and a retry', (tester) async {
    await pumpDesk(tester, _FailingDesk(), const Size(800, 700));
    expect(find.text('The appointment list could not be loaded.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a pending appointment can be confirmed once', (tester) async {
    final repository = _SlowConfirm();
    await pumpDesk(tester, repository, const Size(500, 900));

    await tester.ensureVisible(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('It does not check the customer in.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm appointment'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirming'));
    await tester.pump();
    expect(repository.calls, 1);

    repository.finish();
    await tester.pump();
    await tester.pump();
    expect(find.text('Nimal Perera is confirmed.'), findsOneWidget);
  });

  testWidgets('a confirmed appointment has no confirm action', (tester) async {
    await pumpDesk(
      tester,
      _FixedDesk([
        _visit(id: 6, name: 'Kasun Silva', mobile: '0773333333', status: AppointmentStatus.confirmed),
      ]),
      const Size(500, 900),
    );

    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Check in'), findsOneWidget);
  });

  testWidgets('check-in asks for confirmation and does not repeat the request', (tester) async {
    final repository = _SlowCheckIn();
    await pumpDesk(tester, repository, const Size(500, 900));

    await tester.ensureVisible(find.text('Check in'));
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only the checked-in status is saved.'), findsOneWidget);

    await tester.tap(find.text('Check in customer').last);
    await tester.pump();
    await tester.tap(find.text('Checking in').last);
    await tester.pump();
    expect(repository.calls, 1);

    repository.finish();
    await tester.pump();
    await tester.pump();
    expect(find.text('Nimal Perera is checked in.'), findsOneWidget);
  });

  testWidgets('a failed check-in stays on the confirmation', (tester) async {
    final repository = _FixedDesk([
      _visit(id: 4, name: 'Kasun Silva', mobile: '0773333333', status: AppointmentStatus.confirmed),
    ], checkInError: const ApiException('The appointment already has that status.'));
    await pumpDesk(tester, repository, const Size(500, 900));

    await tester.ensureVisible(find.text('Check in'));
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check in customer').last);
    await tester.pumpAndSettle();

    expect(find.text('The appointment already has that status.'), findsOneWidget);
    expect(find.text('Check in customer'), findsWidgets);
  });

  testWidgets('an unexpected check-in failure stays on the confirmation', (tester) async {
    final repository = _FixedDesk([
      _visit(id: 4, name: 'Kasun Silva', mobile: '0773333333', status: AppointmentStatus.confirmed),
    ], checkInError: StateError('socket closed'));
    await pumpDesk(tester, repository, const Size(500, 900));

    await tester.ensureVisible(find.text('Check in'));
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check in customer').last);
    await tester.pumpAndSettle();

    expect(find.text('The customer could not be checked in.'), findsOneWidget);
    expect(find.text('Checking in'), findsNothing);
    expect(find.text('Kasun Silva is checked in.'), findsNothing);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Check in customer'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('checked-in visits have no second check-in action', (tester) async {
    await pumpDesk(
      tester,
      _FixedDesk([
        _visit(id: 5, name: 'Amal Fernando', mobile: '0772222222', status: AppointmentStatus.checkedIn),
      ]),
      const Size(1200, 900),
    );

    expect(find.text('View'), findsOneWidget);
    expect(find.text('Check in'), findsNothing);
  });

  testWidgets('walk-in search selects an existing customer', (tester) async {
    final customers = _FakeCustomers([
      _customer(id: 8, first: 'Samanthi', last: 'Silva', mobile: '0771234567'),
      _customer(id: 9, first: 'Dilani', last: 'Fernando', mobile: '0710000000'),
    ]);
    final pending = await _openWalkIn(tester, customers);

    await tester.enterText(find.widgetWithText(TextField, 'Search name or mobile'), '077123');
    await tester.pump();
    expect(find.text('Dilani Fernando'), findsNothing);
    await tester.tap(find.text('Samanthi Silva'));
    await tester.pump();
    await tester.tap(find.text('Create appointment'));
    await tester.pumpAndSettle();

    final choice = await pending.future;
    expect(choice?.customerId, 8);
    expect(choice?.customerName, 'Samanthi Silva');
    expect(customers.creates, 0);
  });

  testWidgets('new customer form validates before saving', (tester) async {
    final customers = _FakeCustomers(const []);
    await _openWalkIn(tester, customers);

    await tester.tap(find.text('New customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save customer'));
    await tester.pump();

    expect(find.text('First name is required'), findsOneWidget);
    expect(customers.creates, 0);
  });

  testWidgets('saving a new customer does not open an appointment', (tester) async {
    final customers = _FakeCustomers(const []);
    await _openWalkIn(tester, customers);

    await tester.tap(find.text('New customer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Nimal');
    await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'Perera');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile number'), '0771234567');
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();

    expect(customers.creates, 1);
    expect(find.text('Nimal Perera was saved. Create an appointment only if you want one.'), findsOneWidget);
    expect(find.byType(CreateAppointmentScreen), findsNothing);
  });

  testWidgets('appointment form accepts a prefilled customer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: CreateAppointmentScreen(initialCustomerId: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sarah Perera (CUS-002)'), findsOneWidget);
  });
}

Future<Completer<WalkInChoice?>> _openWalkIn(WidgetTester tester, CustomerRepository customers) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final result = Completer<WalkInChoice?>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.complete(await showWalkInDialog(context: context, customers: customers));
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

ReceptionVisit _visit({
  required int id,
  required String name,
  required String mobile,
  required AppointmentStatus status,
}) {
  return ReceptionVisit(
    appointmentId: id,
    customerId: id,
    customerName: name,
    mobile: mobile,
    date: DateTime(2026, 10, 11),
    start: const TimeOfDay(hour: 9, minute: 0),
    services: 'Haircut (30m)',
    employee: 'Amal',
    status: status,
  );
}

Customer _customer({
  required int id,
  required String first,
  required String last,
  required String mobile,
}) {
  return Customer(
    id: id,
    customerCode: 'CUS-$id',
    firstName: first,
    lastName: last,
    mobileNumber: mobile,
    createdDate: DateTime(2026, 10, 11),
  );
}

class _FixedDesk extends ReceptionRepository {
  _FixedDesk(this.visits, {this.checkInError});

  final List<ReceptionVisit> visits;
  final Object? checkInError;

  @override
  Future<ReceptionDay> load({DateTime? date}) async {
    return ReceptionDay(date: DateTime(2026, 10, 11), visits: visits);
  }

  @override
  Future<void> checkIn(int appointmentId) async {
    final error = checkInError;
    if (error != null) throw error;
  }
}

class _FailingDesk extends ReceptionRepository {
  @override
  Future<ReceptionDay> load({DateTime? date}) async {
    throw const ApiException('The appointment list could not be loaded.');
  }
}

class _SlowConfirm extends ReceptionRepository {
  final Completer<void> _done = Completer<void>();
  int calls = 0;

  @override
  Future<ReceptionDay> load({DateTime? date}) async {
    return ReceptionDay(
      date: DateTime(2026, 10, 11),
      visits: [
        _visit(id: 3, name: 'Nimal Perera', mobile: '0771111111', status: AppointmentStatus.pending),
      ],
    );
  }

  @override
  Future<void> confirm(int appointmentId) {
    calls++;
    return _done.future;
  }

  void finish() {
    if (!_done.isCompleted) _done.complete();
  }
}

class _SlowCheckIn extends ReceptionRepository {
  final Completer<void> _done = Completer<void>();
  int calls = 0;

  @override
  Future<ReceptionDay> load({DateTime? date}) async {
    return ReceptionDay(
      date: DateTime(2026, 10, 11),
      visits: [
        _visit(id: 3, name: 'Nimal Perera', mobile: '0771111111', status: AppointmentStatus.pending),
      ],
    );
  }

  @override
  Future<void> checkIn(int appointmentId) {
    calls++;
    return _done.future;
  }

  void finish() {
    if (!_done.isCompleted) _done.complete();
  }
}

class _FakeCustomers extends CustomerRepository {
  _FakeCustomers(this.items);

  final List<Customer> items;
  int creates = 0;

  @override
  bool get isApiBacked => true;

  @override
  Future<List<Customer>> list() async => items;

  @override
  Future<Customer> create({
    required String firstName,
    required String lastName,
    required String mobileNo,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? remarks,
  }) async {
    creates++;
    return _customer(id: 40, first: firstName.trim(), last: lastName.trim(), mobile: mobileNo.trim());
  }
}
