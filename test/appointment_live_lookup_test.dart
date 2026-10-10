import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/screens/appointments_screen.dart';
import 'package:salon_booking_mobile/features/appointments/screens/create_appointment_screen.dart';
import 'package:salon_booking_mobile/features/customers/data/customer_repository.dart';
import 'package:salon_booking_mobile/features/services/data/service_repository.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  late List<http.Request> requests;

  ApiClient clientFor(AuthSession session) {
    return ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode(_body(request)), 200);
      }),
      session: session,
    );
  }

  void signIn() {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  testWidgets('signed-in list uses stored customer and service names', (tester) async {
    requests = [];
    signIn();
    final session = AuthSession.instance;
    final client = clientFor(session);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AppointmentsScreen(
          repository: AppointmentRepository(client: client, session: session),
          customers: CustomerRepository(client: client, session: session),
          services: ServiceRepository(client: client, session: session),
          liveLookups: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nimal Perera'), findsOneWidget);
    expect(find.text('Beard Trim'), findsOneWidget);
    expect(find.text('Amanda Silva'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create saves the stored customer and service', (tester) async {
    requests = [];
    signIn();
    final session = AuthSession.instance;
    final client = clientFor(session);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final createScreen = CreateAppointmentScreen(
      repository: AppointmentRepository(client: client, session: session),
      customers: CustomerRepository(client: client, session: session),
      services: ServiceRepository(client: client, session: session),
      liveLookups: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => createScreen),
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

    await _choose<int>(tester, 'Customer', 'Nimal Perera (CUS000008)');
    final dateField = find.widgetWithText(TextFormField, 'Appointment Date');
    await tester.ensureVisible(dateField);
    await tester.tap(dateField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await _choose<int>(tester, 'Service', 'Beard Trim · 20 min · Rs. 800.00');
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Duration: 20 min'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final posts = requests.where((request) => request.method == 'POST').toList();
    final create = jsonDecode(posts[0].body) as Map<String, dynamic>;
    final line = jsonDecode(posts[1].body) as Map<String, dynamic>;
    expect(posts[0].url.path, '/api/Appointments');
    expect(create['customerId'], 8);
    expect(create.containsKey('tenantId'), isFalse);
    expect(create.containsKey('branchId'), isFalse);
    expect(posts[1].url.path, '/api/Appointments/15/services');
    expect(line['serviceId'], 4);
    expect(line.containsKey('tenantId'), isFalse);
    expect(find.text('Nimal Perera was saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _choose<T>(WidgetTester tester, String label, String option) async {
  final field = find.widgetWithText(DropdownButtonFormField<T>, label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Object _body(http.Request request) {
  if (request.url.path == '/api/Customers') {
    return {
      'totalPages': 1,
      'items': [
        {
          'customerId': 8,
          'customerCode': 'CUS000008',
          'firstName': 'Nimal',
          'lastName': 'Perera',
          'mobileNo': '0771234567',
          'isActive': true,
          'createdDate': '2026-10-09T10:00:00',
          'tenantId': 1,
          'branchId': 1,
        },
      ],
    };
  }
  if (request.url.path == '/api/ServiceCategories') {
    return {
      'totalPages': 1,
      'items': [
        {'serviceCategoryId': 1, 'categoryName': 'Hair'},
      ],
    };
  }
  if (request.url.path == '/api/Services' && request.method == 'GET') {
    return {
      'totalPages': 1,
      'items': [
        {
          'serviceId': 4,
          'serviceCode': 'SER000004',
          'serviceName': 'Beard Trim',
          'description': '',
          'durationMinutes': 20,
          'price': 800,
          'serviceCategoryId': 1,
          'isActive': true,
          'createdDate': '2026-10-09T10:00:00',
          'branchId': 1,
          'tenantId': 1,
        },
      ],
    };
  }
  if (request.url.path == '/api/Appointments' && request.method == 'GET') {
    return {
      'totalPages': 1,
      'items': [
        {
          'appointmentId': 15,
          'branchId': 1,
          'customerId': 8,
          'appointmentDate': '2026-10-10',
          'status': 'Pending',
          'schedulingState': 'Unscheduled',
          'services': [
            {
              'appointmentServiceId': 3,
              'appointmentId': 15,
              'serviceId': 4,
              'employeeId': null,
              'startTime': null,
              'endTime': null,
              'durationMinutes': 20,
              'unitPrice': 800,
              'sequence': 1,
              'isCancelled': false,
              'isFullyScheduled': false,
              'rowVersion': 'AQID',
            },
          ],
          'statusHistory': <Object>[],
        },
      ],
    };
  }
  if (request.method == 'POST' && request.url.path == '/api/Appointments') {
    return {
      'appointmentId': 15,
      'branchId': 1,
      'customerId': 8,
      'appointmentDate': '2026-10-10',
      'status': 'Pending',
      'schedulingState': 'Unscheduled',
      'services': <Object>[],
      'statusHistory': <Object>[],
    };
  }
  return {
    'appointmentServiceId': 3,
    'appointmentId': 15,
    'branchId': 1,
    'serviceId': 4,
    'durationMinutes': 20,
    'unitPrice': 800,
    'sequence': 1,
    'isCancelled': false,
    'isFullyScheduled': false,
    'rowVersion': 'AQID',
    'scheduleHistory': <Object>[],
  };
}
