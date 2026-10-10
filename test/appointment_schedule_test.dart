import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/data/availability_repository.dart';
import 'package:salon_booking_mobile/features/appointments/screens/appointments_screen.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  testWidgets('a selected slot schedules that service line and reloads it', (tester) async {
    final script = _Script();
    await _book(tester, script, services: const ['Hair Cut · 45 min · Rs. 2,500.00']);
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(script.appointmentPosts, 1);
    expect(script.servicePosts, 1);
    expect(script.schedulePosts, 1);
    expect(script.detailGets, 1);
    final schedule = script.schedules.single;
    expect(script.schedulePaths.single, '/api/Appointments/42/services/7/schedule');
    expect(schedule['employeeId'], 4);
    expect(schedule['rowVersion'], 'AQID');
    expect(schedule['startTime'], '${_today()}T10:00:00');
    expect(schedule['endTime'], '${_today()}T10:30:00');
    expect(schedule.containsKey('branchId'), isFalse);
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
    expect(find.textContaining('· Scheduled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service lines are scheduled independently', (tester) async {
    final script = _Script();
    await _book(
      tester,
      script,
      services: const [
        'Hair Cut · 45 min · Rs. 2,500.00',
        'Hair Colour · 90 min · Rs. 7,500.00',
      ],
    );
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Find Availability').last);
    await tester.tap(find.text('Find Availability').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10:30 → 12:00'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kasun Perera   10:00 → 10:30'), findsOneWidget);
    expect(find.textContaining('Amali Silva   10:30 → 12:00'), findsOneWidget);
    await _save(tester);

    expect(script.schedulePaths, [
      '/api/Appointments/42/services/7/schedule',
      '/api/Appointments/42/services/9/schedule',
    ]);
    expect(script.schedules[0]['employeeId'], 4);
    expect(script.schedules[0]['rowVersion'], 'AQID');
    expect(script.schedules[0]['endTime'], '${_today()}T10:30:00');
    expect(script.schedules[1]['employeeId'], 8);
    expect(script.schedules[1]['rowVersion'], 'BAUG');
    expect(script.schedules[1]['startTime'], '${_today()}T10:30:00');
    expect(script.schedules[1]['endTime'], '${_today()}T12:00:00');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a line without a slot stays unscheduled', (tester) async {
    final script = _Script(listState: 'PartiallyScheduled');
    await _book(
      tester,
      script,
      services: const [
        'Hair Cut · 45 min · Rs. 2,500.00',
        'Hair Colour · 90 min · Rs. 7,500.00',
      ],
    );
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(script.servicePosts, 2);
    expect(script.schedulePosts, 1);
    expect(script.schedules.single['employeeId'], 4);
    expect(find.textContaining('· Partial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unavailable slot stays on the form and can be retried', (tester) async {
    final script = _Script(failFirstSchedule: 409, failTitle: 'The employee is not available for that time.');
    await _book(tester, script, services: const ['Hair Cut · 45 min · Rs. 2,500.00']);
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(find.textContaining('The employee is not available for that time.'), findsOneWidget);
    expect(find.textContaining('was saved'), findsNothing);
    expect(script.appointmentPosts, 1);
    expect(script.schedulePosts, 1);

    await _save(tester);
    expect(script.appointmentPosts, 1);
    expect(script.servicePosts, 1);
    expect(script.schedulePosts, 2);
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
  });

  testWidgets('a capability rejection is shown and is not treated as scheduled', (tester) async {
    final script = _Script(
      failFirstSchedule: 400,
      failTitle: 'The employee is not able to perform this service.',
    );
    await _book(tester, script, services: const ['Hair Cut · 45 min · Rs. 2,500.00']);
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(find.textContaining('The employee is not able to perform this service.'), findsOneWidget);
    expect(find.textContaining('was saved'), findsNothing);
    expect(script.detailGets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a schedule request failure can be retried', (tester) async {
    final script = _Script(failFirstSchedule: 500, failTitle: 'The schedule could not be saved.');
    await _book(tester, script, services: const ['Hair Cut · 45 min · Rs. 2,500.00']);
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(find.textContaining('The schedule could not be saved.'), findsOneWidget);
    await _save(tester);
    expect(script.schedulePosts, 2);
    expect(script.appointmentPosts, 1);
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
  });

  testWidgets('a stale row version is reloaded before the line is retried', (tester) async {
    final script = _Script(
      failFirstSchedule: 409,
      failTitle: 'The record was changed by someone else. Reload it and try again.',
      refreshVersion: 'FRESH',
    );
    await _book(tester, script, services: const ['Hair Cut · 45 min · Rs. 2,500.00']);
    await tester.tap(find.text('10:00 → 10:30'));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(find.textContaining('changed by someone else'), findsOneWidget);
    expect(script.detailGets, 1);
    expect(script.schedules.single['rowVersion'], 'AQID');

    await _save(tester);
    expect(script.schedules[1]['rowVersion'], 'FRESH');
    expect(script.appointmentPosts, 1);
    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
  });

  testWidgets('the appointment list shows the server scheduling state', (tester) async {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final client = ApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'items': [
              _appointmentJson(schedulingState: 'PartiallyScheduled', employeeId: 4),
              _appointmentJson(schedulingState: 'Unscheduled', employeeId: null, appointmentId: 43),
            ],
            'totalPages': 1,
          }),
          200,
        );
      }),
      session: AuthSession.instance,
    );
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AppointmentsScreen(
          repository: AppointmentRepository(client: client, session: AuthSession.instance),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Employee 4 · Partial'), findsOneWidget);
    expect(find.textContaining('Unassigned · Unscheduled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Script {
  _Script({this.failFirstSchedule, this.failTitle, this.refreshVersion, this.listState = 'Scheduled'});

  final int? failFirstSchedule;
  final String? failTitle;
  final String? refreshVersion;
  final String listState;
  int appointmentPosts = 0;
  int servicePosts = 0;
  int schedulePosts = 0;
  int detailGets = 0;
  int listGets = 0;
  final schedules = <Map<String, dynamic>>[];
  final schedulePaths = <String>[];
}

Future<void> _book(WidgetTester tester, _Script script, {required List<String> services}) async {
  AuthSession.instance.save(
    accessToken: 'test-token',
    username: 'tester',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  final client = ApiClient(httpClient: MockClient((request) => _respond(script, request)), session: AuthSession.instance);
  final session = AuthSession.instance;
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: AppointmentsScreen(
        repository: AppointmentRepository(client: client, session: session),
        availabilityRepository: AvailabilityRepository(client: client, session: session),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Appointment'));
  await tester.pumpAndSettle();

  await _choose(tester, 'Customer', 'Amanda Silva (CUS-001)');
  final dateField = find.widgetWithText(TextFormField, 'Appointment Date');
  await tester.ensureVisible(dateField);
  await tester.tap(dateField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  for (final service in services) {
    await _choose(tester, 'Service', service);
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text('Find Availability').first);
  await tester.tap(find.text('Find Availability').first);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Future<http.Response> _respond(_Script script, http.Request request) async {
  final path = request.url.path;
  if (request.method == 'GET' && path == '/api/Availability') {
    final serviceId = request.url.queryParameters['serviceId'];
    if (serviceId == '2') {
      return http.Response(jsonEncode([_slot(8, 'Amali Silva', 2, 90, '10:30:00', '12:00:00')]), 200);
    }
    return http.Response(jsonEncode([_slot(4, 'Kasun Perera', 1, 30, '10:00:00', '10:30:00')]), 200);
  }
  if (request.method == 'GET' && path == '/api/Appointments/42') {
    script.detailGets++;
    return http.Response(
      jsonEncode(_appointmentJson(schedulingState: script.listState, rowVersion: script.refreshVersion ?? 'AQID')),
      200,
    );
  }
  if (request.method == 'GET' && path == '/api/Appointments') {
    script.listGets++;
    if (script.listGets == 1 || script.schedulePosts == 0) {
      return http.Response(jsonEncode({'items': <Object>[], 'totalPages': 1}), 200);
    }
    return http.Response(
      jsonEncode({
        'items': [_appointmentJson(schedulingState: script.listState)],
        'totalPages': 1,
      }),
      200,
    );
  }
  if (request.method == 'POST' && path == '/api/Appointments') {
    script.appointmentPosts++;
    return http.Response(jsonEncode(_appointmentJson()), 200);
  }
  if (request.method == 'POST' && path.endsWith('/schedule')) {
    script.schedulePosts++;
    script.schedulePaths.add(path);
    script.schedules.add(jsonDecode(request.body) as Map<String, dynamic>);
    if (script.failFirstSchedule != null && script.schedulePosts == 1) {
      return http.Response(jsonEncode({'title': script.failTitle}), script.failFirstSchedule!);
    }
    final body = script.schedules.last;
    return http.Response(jsonEncode(_lineJson(7, 1, body['rowVersion'] as String, scheduled: true)), 200);
  }
  if (request.method == 'POST' && path.endsWith('/services')) {
    script.servicePosts++;
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final serviceId = body['serviceId'] as int;
    final lineId = serviceId == 1 ? 7 : 9;
    final version = serviceId == 1 ? 'AQID' : 'BAUG';
    return http.Response(jsonEncode(_lineJson(lineId, serviceId, version)), 200);
  }
  return http.Response(jsonEncode({'title': 'Unexpected ${request.method} $path'}), 500);
}

Map<String, dynamic> _slot(
  int employeeId,
  String name,
  int serviceId,
  int durationMinutes,
  String start,
  String end,
) {
  return {
    'employeeId': employeeId,
    'employeeName': name,
    'serviceId': serviceId,
    'durationMinutes': durationMinutes,
    'slots': [
      {'startTime': '2026-10-06T$start', 'endTime': '2026-10-06T$end'},
    ],
  };
}

Map<String, dynamic> _lineJson(int lineId, int serviceId, String rowVersion, {bool scheduled = false}) {
  return {
    'appointmentServiceId': lineId,
    'appointmentId': 42,
    'serviceId': serviceId,
    'employeeId': scheduled ? 4 : null,
    'startTime': scheduled ? '${_today()}T10:00:00' : null,
    'endTime': scheduled ? '${_today()}T10:30:00' : null,
    'durationMinutes': serviceId == 2 ? 90 : 30,
    'unitPrice': 2500,
    'sequence': serviceId,
    'isCancelled': false,
    'isFullyScheduled': scheduled,
    'rowVersion': rowVersion,
    'scheduleHistory': <Object>[],
  };
}

Map<String, dynamic> _appointmentJson({
  String schedulingState = 'Unscheduled',
  String rowVersion = 'AQID',
  int? employeeId,
  int appointmentId = 42,
}) {
  return {
    'appointmentId': appointmentId,
    'branchId': 1,
    'customerId': 999,
    'appointmentDate': _today(),
    'status': 'Pending',
    'schedulingState': schedulingState,
    'services': [
      {
        'appointmentServiceId': 7,
        'appointmentId': appointmentId,
        'serviceId': 1,
        'employeeId': employeeId,
        'startTime': employeeId == null ? null : '${_today()}T10:00:00',
        'endTime': employeeId == null ? null : '${_today()}T10:30:00',
        'durationMinutes': 30,
        'unitPrice': 2500,
        'sequence': 1,
        'isCancelled': false,
        'isFullyScheduled': employeeId != null,
        'rowVersion': rowVersion,
        'scheduleHistory': <Object>[],
      },
    ],
    'statusHistory': <Object>[],
  };
}

String _today() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year.toString().padLeft(4, '0')}-${two(now.month)}-${two(now.day)}';
}

Future<void> _choose(WidgetTester tester, String label, String option) async {
  final field = find.widgetWithText(DropdownButtonFormField<int>, label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
