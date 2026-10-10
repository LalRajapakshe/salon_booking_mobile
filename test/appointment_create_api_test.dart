import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_status.dart';
import 'package:salon_booking_mobile/features/appointments/screens/appointments_screen.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  AppointmentRepository repositoryFor(http.Client httpClient) {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final session = AuthSession.instance;
    return AppointmentRepository(
      client: ApiClient(httpClient: httpClient, session: session),
      session: session,
    );
  }

  Map<String, dynamic> appointmentBody(int id) => {
        'appointmentId': id,
        'branchId': 1,
        'customerId': 1,
        'appointmentDate': '2026-10-06',
        'status': 'Pending',
        'schedulingState': 'Unscheduled',
        'needsScheduling': true,
        'services': <Object>[],
        'statusHistory': <Object>[],
      };

  Map<String, dynamic> serviceBody(int lineId, int serviceId) => {
        'appointmentServiceId': lineId,
        'appointmentId': 42,
        'branchId': 1,
        'serviceId': serviceId,
        'durationMinutes': 45,
        'unitPrice': 2500,
        'sequence': lineId,
        'isCancelled': false,
        'isFullyScheduled': false,
        'rowVersion': 'AQID',
        'scheduleHistory': <Object>[],
      };

  test('create and addService send only the backend fields', () async {
    final requests = <http.Request>[];
    final repository = repositoryFor(MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/Appointments') {
        return http.Response(jsonEncode(appointmentBody(42)), 200);
      }
      return http.Response(jsonEncode(serviceBody(7, 2)), 200);
    }));

    await repository.create(
      customerId: 4,
      appointmentDate: DateTime(2026, 10, 6, 15, 45),
      status: AppointmentStatus.confirmed,
      notes: '  Window seat  ',
    );
    await repository.addService(appointmentId: 42, serviceId: 2, notes: '   ');

    final create = jsonDecode(requests[0].body) as Map<String, dynamic>;
    expect(requests[0].method, 'POST');
    expect(requests[0].url.path, '/api/Appointments');
    expect(requests[0].headers['Authorization'], 'Bearer test-token');
    expect(create['customerId'], 4);
    expect(create['appointmentDate'], '2026-10-06');
    expect(create['status'], 'Confirmed');
    expect(create['notes'], 'Window seat');
    expect(create.containsKey('branchId'), isFalse);
    expect(create.containsKey('tenantId'), isFalse);
    expect(create.containsKey('employeeId'), isFalse);
    expect(create.containsKey('startTime'), isFalse);
    expect(create.containsKey('endTime'), isFalse);

    final line = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(requests[1].url.path, '/api/Appointments/42/services');
    expect(line, {'serviceId': 2});
  });

  test('the local scheduled status is omitted so the server can default it', () async {
    late Map<String, dynamic> create;
    final repository = repositoryFor(MockClient((request) async {
      create = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(appointmentBody(5)), 200);
    }));

    await repository.create(
      customerId: 1,
      appointmentDate: DateTime(2026, 10, 6),
      status: AppointmentStatus.scheduled,
    );

    expect(create.containsKey('status'), isFalse);
  });

  testWidgets('save creates the appointment and each service line', (tester) async {
    final creates = <Map<String, dynamic>>[];
    final lines = <Map<String, dynamic>>[];
    final repository = repositoryFor(MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'items': <Object>[], 'totalPages': 1}), 200);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (request.url.path == '/api/Appointments') {
        creates.add(body);
        return http.Response(jsonEncode(appointmentBody(42)), 200);
      }
      lines.add(body);
      return http.Response(jsonEncode(serviceBody(lines.length, body['serviceId'] as int)), 200);
    }));

    await _openCreate(tester, repository);
    await _fillBooking(tester, services: const [
      'Hair Cut · 45 min · Rs. 2,500.00',
      'Hair Colour · 90 min · Rs. 7,500.00',
    ]);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(creates, hasLength(1));
    expect(creates.single['customerId'], 1);
    expect(creates.single.containsKey('branchId'), isFalse);
    expect(creates.single.containsKey('employeeId'), isFalse);
    expect(creates.single.containsKey('startTime'), isFalse);
    expect(creates.single.containsKey('endTime'), isFalse);
    expect(creates.single.containsKey('status'), isFalse);
    expect(lines, [
      {'serviceId': 1},
      {'serviceId': 2},
    ]);
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
    expect(find.text('Schedule and review salon appointments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an appointment create failure stays on the form', (tester) async {
    var posts = 0;
    final repository = repositoryFor(MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'items': <Object>[], 'totalPages': 1}), 200);
      }
      posts++;
      return http.Response(jsonEncode({'title': 'Customer was not found.'}), 400);
    }));

    await _openCreate(tester, repository);
    await _fillBooking(tester);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(posts, 1);
    expect(find.text('Customer was not found.'), findsOneWidget);
    expect(find.text('Create Appointment'), findsWidgets);
    expect(find.textContaining('was saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a service-line failure can be retried without a second appointment', (tester) async {
    var appointmentPosts = 0;
    var servicePosts = 0;
    final repository = repositoryFor(MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'items': <Object>[], 'totalPages': 1}), 200);
      }
      if (request.url.path == '/api/Appointments') {
        appointmentPosts++;
        return http.Response(jsonEncode(appointmentBody(42)), 200);
      }
      servicePosts++;
      if (servicePosts == 1) {
        return http.Response(jsonEncode({'title': 'Service was not found.'}), 400);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(serviceBody(7, body['serviceId'] as int)), 200);
    }));

    await _openCreate(tester, repository);
    await _fillBooking(tester);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(appointmentPosts, 1);
    expect(servicePosts, 1);
    expect(
      find.text('Service was not found. The appointment was created. Save again to add the remaining services.'),
      findsOneWidget,
    );
    expect(find.textContaining('was saved'), findsNothing);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(appointmentPosts, 1);
    expect(servicePosts, 2);
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save shows a loading state until the appointment request finishes', (tester) async {
    final gate = Completer<void>();
    final repository = repositoryFor(MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'items': <Object>[], 'totalPages': 1}), 200);
      }
      if (request.url.path == '/api/Appointments') {
        await gate.future;
        return http.Response(jsonEncode(appointmentBody(42)), 200);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(serviceBody(7, body['serviceId'] as int)), 200);
    }));

    await _openCreate(tester, repository);
    await _fillBooking(tester);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation still blocks save before any appointment request', (tester) async {
    var posts = 0;
    final repository = repositoryFor(MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode({'items': <Object>[], 'totalPages': 1}), 200);
      }
      posts++;
      return http.Response(jsonEncode({'title': 'Should not be called.'}), 500);
    }));

    await _openCreate(tester, repository);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(posts, 0);
    expect(find.text('Customer is required'), findsOneWidget);
    expect(find.text('Appointment date is required'), findsOneWidget);
    expect(find.text('Service is required'), findsOneWidget);
    expect(find.text('Branch is required'), findsNothing);
    expect(find.text('Employee is required'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openCreate(WidgetTester tester, AppointmentRepository repository) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: AppointmentsScreen(repository: repository)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Appointment'));
  await tester.pumpAndSettle();
}

Future<void> _fillBooking(
  WidgetTester tester, {
  List<String> services = const ['Hair Colour · 90 min · Rs. 7,500.00'],
}) async {
  await _choose<int>(tester, 'Customer', 'Amanda Silva (CUS-001)');

  final dateField = find.widgetWithText(TextFormField, 'Appointment Date');
  await tester.ensureVisible(dateField);
  await tester.tap(dateField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  for (final service in services) {
    await _choose<int>(tester, 'Service', service);
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
  }
}

Future<void> _choose<T>(WidgetTester tester, String label, String option) async {
  await _chooseAt<T>(tester, label, 0, option);
}

Future<void> _chooseAt<T>(WidgetTester tester, String label, int index, String option) async {
  final field = find.widgetWithText(DropdownButtonFormField<T>, label).at(index);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(option).last);
  await tester.pumpAndSettle();
}
