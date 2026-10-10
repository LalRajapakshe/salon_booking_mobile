import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/api/availability_api_mapper.dart';
import 'package:salon_booking_mobile/features/appointments/data/availability_repository.dart';
import 'package:salon_booking_mobile/features/appointments/screens/create_appointment_screen.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  test('availability mapping keeps each stylist slot and its duration', () {
    final results = AvailabilityApiMapper.employees([
      {
        'employeeId': 4,
        'employeeName': 'Kasun Perera',
        'serviceId': 1,
        'durationMinutes': 30,
        'slots': [
          {
            'startTime': '2026-10-06T10:00:00',
            'endTime': '2026-10-06T10:30:00',
          },
        ],
      },
      {
        'employeeId': 8,
        'employeeName': 'Amali Silva',
        'serviceId': 2,
        'durationMinutes': 120,
        'slots': [
          {
            'startTime': '2026-10-06T10:30:00',
            'endTime': '2026-10-06T12:30:00',
          },
        ],
      },
    ]);

    expect(results, hasLength(2));
    expect(results.first.durationMinutes, 30);
    expect(results.first.slots.single.endTime.difference(results.first.slots.single.startTime), const Duration(minutes: 30));
    expect(results.last.employeeName, 'Amali Silva');
    expect(results.last.durationMinutes, 120);
    expect(results.last.slots.single.endTime.difference(results.last.slots.single.startTime), const Duration(minutes: 120));
  });

  test('availability request sends the service and date, not a duration', () async {
    late Uri uri;
    final repository = _repository(MockClient((request) async {
      uri = request.url;
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response('[]', 200);
    }));

    await repository.find(serviceId: 2, date: DateTime(2026, 10, 6, 18, 45));

    expect(uri.path, '/api/Availability');
    expect(uri.queryParameters['serviceId'], '2');
    expect(uri.queryParameters['date'], '2026-10-06');
    expect(uri.queryParameters.containsKey('durationMinutes'), isFalse);
    expect(uri.queryParameters.containsKey('branchId'), isFalse);
    expect(uri.queryParameters.containsKey('tenantId'), isFalse);
    expect(uri.queryParameters.containsKey('employeeId'), isFalse);
  });

  testWidgets('each service line keeps its own availability selection', (tester) async {
    final requests = <Uri>[];
    final repository = _repository(MockClient((request) async {
      requests.add(request.url);
      expect(request.url.path, '/api/Availability');
      expect(request.url.queryParameters.containsKey('durationMinutes'), isFalse);
      final serviceId = request.url.queryParameters['serviceId'];
      if (serviceId == '1') {
        return http.Response(
          jsonEncode([
            _employee(4, 'Kasun Perera', 1, 30, '10:00:00', '10:30:00'),
          ]),
          200,
        );
      }
      return http.Response(
        jsonEncode([
          _employee(8, 'Amali Silva', 2, 120, '10:30:00', '12:30:00'),
        ]),
        200,
      );
    }));

    await _openCreate(tester, repository);
    await _pickDate(tester);
    await _addService(tester, 'Hair Cut · 45 min · Rs. 2,500.00');
    await _addService(tester, 'Hair Colour · 90 min · Rs. 7,500.00');

    await tester.ensureVisible(find.text('Find Availability').first);
    await tester.tap(find.text('Find Availability').first);
    await tester.pumpAndSettle();
    expect(find.text('Kasun Perera · 30 min'), findsOneWidget);
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Find Availability').last);
    await tester.tap(find.text('Find Availability').last);
    await tester.pumpAndSettle();
    expect(find.text('Amali Silva · 120 min'), findsOneWidget);
    await tester.tap(find.text('10:30 → 12:30'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kasun Perera   10:00 → 10:30'), findsOneWidget);
    expect(find.textContaining('Amali Silva   10:30 → 12:30'), findsOneWidget);
    expect(requests.map((uri) => uri.queryParameters['serviceId']), ['1', '2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty availability result leaves the line unscheduled', (tester) async {
    final repository = _repository(MockClient((request) async {
      return http.Response(
        jsonEncode([
          _employee(4, 'Kasun Perera', 1, 30, '10:00:00', '10:30:00', slots: false),
        ]),
        200,
      );
    }));

    await _openCreate(tester, repository);
    await _pickDate(tester);
    await _addService(tester, 'Hair Cut · 45 min · Rs. 2,500.00');
    await tester.tap(find.text('Find Availability'));
    await tester.pumpAndSettle();

    expect(find.text('No available times for this service.'), findsOneWidget);
    expect(find.text('Kasun Perera · 30 min'), findsNothing);
    expect(find.text('Unscheduled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('availability failure can be retried', (tester) async {
    var calls = 0;
    final repository = _repository(MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response(jsonEncode({'title': 'A branch is required.'}), 500);
      }
      return http.Response(
        jsonEncode([
          _employee(4, 'Kasun Perera', 1, 30, '10:00:00', '10:30:00'),
        ]),
        200,
      );
    }));

    await _openCreate(tester, repository);
    await _pickDate(tester);
    await _addService(tester, 'Hair Cut · 45 min · Rs. 2,500.00');
    await tester.tap(find.text('Find Availability'));
    await tester.pumpAndSettle();

    expect(find.text('A branch is required.'), findsOneWidget);
    expect(find.text('Unscheduled'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Kasun Perera · 30 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find availability shows a loading indicator until the response arrives', (tester) async {
    final gate = Completer<void>();
    final repository = _repository(MockClient((request) async {
      await gate.future;
      return http.Response(
        jsonEncode([
          _employee(4, 'Kasun Perera', 1, 30, '10:00:00', '10:30:00'),
        ]),
        200,
      );
    }));

    await _openCreate(tester, repository);
    await _pickDate(tester);
    await _addService(tester, 'Hair Cut · 45 min · Rs. 2,500.00');
    await tester.tap(find.text('Find Availability'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('10:00 → 10:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AvailabilityRepository _repository(http.Client httpClient) {
  AuthSession.instance.save(
    accessToken: 'test-token',
    username: 'tester',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  final session = AuthSession.instance;
  return AvailabilityRepository(
    client: ApiClient(httpClient: httpClient, session: session),
    session: session,
  );
}

Map<String, dynamic> _employee(
  int employeeId,
  String name,
  int serviceId,
  int durationMinutes,
  String start,
  String end, {
  bool slots = true,
}) {
  return {
    'employeeId': employeeId,
    'employeeName': name,
    'serviceId': serviceId,
    'durationMinutes': durationMinutes,
    'slots': slots
        ? [
            {
              'startTime': '2026-10-06T$start',
              'endTime': '2026-10-06T$end',
            },
          ]
        : <Object>[],
  };
}

Future<void> _openCreate(WidgetTester tester, AvailabilityRepository repository) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: CreateAppointmentScreen(availabilityRepository: repository)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickDate(WidgetTester tester) async {
  final dateField = find.widgetWithText(TextFormField, 'Appointment Date');
  await tester.ensureVisible(dateField);
  await tester.tap(dateField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _addService(WidgetTester tester, String label) async {
  final field = find.widgetWithText(DropdownButtonFormField<int>, 'Service');
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Add'));
  await tester.tap(find.text('Add'));
  await tester.pumpAndSettle();
}
