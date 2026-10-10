import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/data/availability_repository.dart';
import 'package:salon_booking_mobile/features/scheduling/models/scheduling_models.dart';
import 'package:salon_booking_mobile/features/scheduling/screens/scheduling_board_screen.dart';
import 'package:salon_booking_mobile/features/scheduling/widgets/time_slot_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(AuthSession.instance.clear);

  final today = DateTime.now();
  final todayKey = _ymd(today);
  final tomorrowKey = _ymd(DateTime(today.year, today.month, today.day + 1));

  Future<void> pumpBoard(WidgetTester tester, http.Client client) async {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final api = ApiClient(httpClient: client);
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulingBoardScreen(
          appointments: AppointmentRepository(client: api),
          availability: AvailabilityRepository(client: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder dropdown(String label) {
    return find.widgetWithText(DropdownButtonFormField<String>, label);
  }

  Future<void> choose(WidgetTester tester, String label, String option) async {
    final field = dropdown(label);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  double cardOpacity(WidgetTester tester, String tooltip) {
    return tester
        .widget<Opacity>(
          find.descendant(
            of: find.byTooltip(tooltip),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
  }

  Future<void> expectSpan(WidgetTester tester, String tooltip, int slots) async {
    final target = find.byTooltip(tooltip);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final positioned = tester.widget<Positioned>(
      find.ancestor(of: target, matching: find.byType(Positioned)).first,
    );
    expect(positioned.width, scheduleSlotWidth * slots);
  }

  testWidgets('real service lines render on their employees for the selected day', (
    tester,
  ) async {
    final requestedDates = <String>[];
    await pumpBoard(tester, MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.url.queryParameters.containsKey('branchId'), isFalse);
      expect(request.url.queryParameters.containsKey('tenantId'), isFalse);
      expect(request.url.path, '/api/Appointments');
      requestedDates.add(request.url.queryParameters['date']!);
      if (request.url.queryParameters['date'] == tomorrowKey) {
        return _page([
          _appointment(99, tomorrowKey, 99, 'Confirmed', [
            _line(90, 99, 9, 15, tomorrowKey, '10:00:00', '10:30:00', 30, 'Z'),
          ]),
        ]);
      }
      return _page([
        _appointment(42, todayKey, 7, 'Confirmed', [
          _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'AQID'),
          _line(9, 42, 2, 8, todayKey, '10:00:00', '11:00:00', 60, 'BAUG'),
          _line(11, 42, 6, null, todayKey, null, null, 45, 'CAUG'),
          _line(12, 42, 7, 4, todayKey, '12:00:00', '13:00:00', 60, 'DAUG', cancelled: true),
        ]),
        _appointment(43, todayKey, 8, 'Pending', [
          _line(13, 43, 3, 9, todayKey, '10:00:00', '11:30:00', 90, 'E'),
        ]),
        _appointment(44, todayKey, 9, 'Confirmed', [
          _line(14, 44, 4, 10, todayKey, '10:00:00', '12:00:00', 120, 'F'),
        ]),
        _appointment(45, todayKey, 10, 'Confirmed', [
          _line(15, 45, 5, 11, todayKey, '10:00:00', '11:30:00', 30, 'G'),
        ]),
        _appointment(46, tomorrowKey, 99, 'Confirmed', [
          _line(16, 46, 8, 12, tomorrowKey, '09:00:00', '09:30:00', 30, 'H'),
        ]),
      ]);
    }));

    expect(requestedDates.single, todayKey);
    expect(find.text('Customer 7'), findsWidgets);
    expect(find.text('Employee 4'), findsWidgets);
    expect(find.text('Employee 8'), findsWidgets);
    expect(find.text('Service 6'), findsNothing);
    expect(find.text('Service 7'), findsNothing);
    expect(find.text('Customer 99'), findsNothing);
    expect(find.text('Employee 12'), findsNothing);
    expect(
      find.text('Duration 30 min does not match this time.'),
      findsOneWidget,
    );

    await expectSpan(tester, 'Customer 7, Service 1', 1);
    await expectSpan(tester, 'Customer 7, Service 2', 2);
    await expectSpan(tester, 'Customer 8, Service 3', 3);
    await expectSpan(tester, 'Customer 9, Service 4', 4);
    await expectSpan(tester, 'Customer 10, Service 5', 3);
    expect(find.text(formatScheduleRange(10 * 60, 11 * 60 + 30)), findsWidgets);

    await choose(tester, 'Staff', 'Employee 8');
    expect(find.text('Employee 4'), findsNothing);
    expect(find.text('Employee 8'), findsWidgets);
    expect(find.byTooltip('Customer 7, Service 1'), findsNothing);

    await choose(tester, 'Staff', 'All');
    await choose(tester, 'Service', 'Service 2');
    expect(cardOpacity(tester, 'Customer 7, Service 1'), 0.38);
    expect(cardOpacity(tester, 'Customer 7, Service 2'), 1);

    await choose(tester, 'Service', 'All');
    await choose(tester, 'Status', 'Pending');
    expect(cardOpacity(tester, 'Customer 7, Service 1'), 0.38);
    expect(cardOpacity(tester, 'Customer 8, Service 3'), 1);

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(requestedDates.last, tomorrowKey);
    expect(find.text('Customer 99'), findsOneWidget);
    expect(find.text('Customer 7'), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(requestedDates.last, todayKey);
    expect(find.text('Customer 7'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reschedule sends the service line, slot, and row version', (
    tester,
  ) async {
    final schedules = <Map<String, dynamic>>[];
    var lists = 0;
    await pumpBoard(tester, MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'GET' && path == '/api/Appointments') {
        lists++;
        final start = lists == 1 ? '10:00:00' : '11:00:00';
        final end = lists == 1 ? '10:30:00' : '11:30:00';
        return _page([
          _appointment(42, todayKey, 7, 'Confirmed', [
            _line(7, 42, 1, 4, todayKey, start, end, 30, 'AQID'),
          ]),
        ]);
      }
      if (request.method == 'GET' && path == '/api/Availability') {
        expect(request.url.queryParameters['serviceId'], '1');
        expect(request.url.queryParameters['date'], todayKey);
        expect(request.url.queryParameters['employeeId'], '4');
        expect(request.url.queryParameters.containsKey('durationMinutes'), isFalse);
        return http.Response(
          jsonEncode([
            _availability(4, 'Kasun Perera', 1, 30, todayKey, '11:00:00', '11:30:00'),
          ]),
          200,
        );
      }
      if (request.method == 'POST' && path == '/api/Appointments/42/services/7/schedule') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        schedules.add(body);
        expect(body.containsKey('branchId'), isFalse);
        return http.Response(
          jsonEncode(
            _line(7, 42, 1, 4, todayKey, '11:00:00', '11:30:00', 30, 'NEWER'),
          ),
          200,
        );
      }
      return _unexpected(request);
    }));

    await tester.tap(find.byTooltip('Customer 7, Service 1'));
    await tester.pumpAndSettle();
    expect(find.text('30 min · Employee 4'), findsOneWidget);
    await tester.tap(find.text('Reschedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kasun Perera · 11:00 → 11:30'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(schedules, [
      {
        'employeeId': 4,
        'startTime': '${todayKey}T11:00:00',
        'endTime': '${todayKey}T11:30:00',
        'rowVersion': 'AQID',
      },
    ]);
    expect(find.text('The service was rescheduled.'), findsOneWidget);
    expect(find.text(formatScheduleRange(11 * 60, 11 * 60 + 30)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('change employee asks availability without an employee filter', (
    tester,
  ) async {
    final schedules = <Map<String, dynamic>>[];
    var lists = 0;
    await pumpBoard(tester, MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'GET' && path == '/api/Appointments') {
        lists++;
        if (lists == 1) {
          return _page([
            _appointment(42, todayKey, 7, 'Confirmed', [
              _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'AQID'),
            ]),
          ]);
        }
        return _page([
          _appointment(42, todayKey, 7, 'Confirmed', [
            _line(7, 42, 1, 8, todayKey, '10:30:00', '11:00:00', 30, 'NEWER'),
          ]),
        ]);
      }
      if (request.method == 'GET' && path == '/api/Availability') {
        expect(request.url.queryParameters.containsKey('employeeId'), isFalse);
        return http.Response(
          jsonEncode([
            _availability(8, 'Amali Silva', 1, 30, todayKey, '10:30:00', '11:00:00'),
          ]),
          200,
        );
      }
      if (request.method == 'POST' && path == '/api/Appointments/42/services/7/schedule') {
        schedules.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode(
            _line(7, 42, 1, 8, todayKey, '10:30:00', '11:00:00', 30, 'NEWER'),
          ),
          200,
        );
      }
      return _unexpected(request);
    }));

    await tester.tap(find.byTooltip('Customer 7, Service 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Employee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amali Silva · 10:30 → 11:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(schedules.single['employeeId'], 8);
    expect(schedules.single['rowVersion'], 'AQID');
    expect(find.text('Employee 8'), findsWidgets);
    expect(find.text('Employee 4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unavailable time stays on the board and shows the API error', (
    tester,
  ) async {
    final gets = <String>[];
    await pumpBoard(tester, _scheduleFailureClient(
      todayKey: todayKey,
      status: 409,
      title: 'The employee is not available for that time.',
      onGet: gets.add,
    ));

    await _saveFirstSlot(tester, 'Kasun Perera · 11:00 → 11:30');

    expect(find.text('The employee is not available for that time.'), findsOneWidget);
    expect(gets, isNot(contains('/api/Appointments/42')));
    expect(find.text(formatScheduleRange(10 * 60, 10 * 60 + 30)), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a capability rejection is shown and does not reload a row version', (
    tester,
  ) async {
    final gets = <String>[];
    await pumpBoard(tester, _scheduleFailureClient(
      todayKey: todayKey,
      status: 400,
      title: 'The employee is not able to perform this service.',
      onGet: gets.add,
    ));

    await _saveFirstSlot(tester, 'Kasun Perera · 11:00 → 11:30');

    expect(find.text('The employee is not able to perform this service.'), findsOneWidget);
    expect(gets, isNot(contains('/api/Appointments/42')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stale row version is replaced from the reloaded appointment', (
    tester,
  ) async {
    final versions = <String>[];
    await pumpBoard(tester, MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'GET' && path == '/api/Appointments') {
        return _page([
          _appointment(42, todayKey, 7, 'Confirmed', [
            _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'AQID'),
          ]),
        ]);
      }
      if (request.method == 'GET' && path == '/api/Appointments/42') {
        return http.Response(
          jsonEncode(
            _appointment(42, todayKey, 7, 'Confirmed', [
              _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'FRESH'),
            ]),
          ),
          200,
        );
      }
      if (request.method == 'GET' && path == '/api/Availability') {
        return http.Response(
          jsonEncode([
            _availability(4, 'Kasun Perera', 1, 30, todayKey, '11:00:00', '11:30:00'),
          ]),
          200,
        );
      }
      if (request.method == 'POST' && path == '/api/Appointments/42/services/7/schedule') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        versions.add(body['rowVersion'] as String);
        if (versions.length == 1) {
          return http.Response(
            jsonEncode({
              'title': 'The record was changed by someone else. Reload it and try again.',
            }),
            409,
          );
        }
        return http.Response(
          jsonEncode(
            _line(7, 42, 1, 4, todayKey, '11:00:00', '11:30:00', 30, 'NEWER'),
          ),
          200,
        );
      }
      return _unexpected(request);
    }));

    await _saveFirstSlot(tester, 'Kasun Perera · 11:00 → 11:30');
    expect(
      find.text('This booking was changed. It has been refreshed. Try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(versions, ['AQID', 'FRESH']);
    expect(find.text('The service was rescheduled.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a schedule load failure can be retried', (tester) async {
    var lists = 0;
    await pumpBoard(tester, MockClient((request) async {
      lists++;
      expect(request.url.queryParameters.containsKey('branchId'), isFalse);
      if (lists == 1) {
        return http.Response(
          jsonEncode({'title': 'A branch is required.'}),
          500,
        );
      }
      return _page([
        _appointment(42, todayKey, 7, 'Confirmed', [
          _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'AQID'),
        ]),
      ]);
    }));

    expect(find.text('A branch is required.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Customer 7'), findsOneWidget);
    expect(find.text('Employee 4'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty day and a loading day do not crash', (tester) async {
    await pumpBoard(tester, MockClient((request) async {
      return _page([
        _appointment(3, todayKey, 1, 'Pending', [
          _line(1, 3, 1, null, todayKey, null, null, 30, 'A'),
        ]),
      ]);
    }));

    expect(find.text('Customer 1 · Service 1 · Pending'), findsOneWidget);
    expect(find.text('No scheduled services for this day.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the board shows a loader until appointments arrive', (tester) async {
    final gate = Completer<http.Response>();
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final api = ApiClient(
      httpClient: MockClient((request) => gate.future),
    );
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulingBoardScreen(
          appointments: AppointmentRepository(client: api),
          availability: AvailabilityRepository(client: api),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    gate.complete(
      _page([
        _appointment(42, todayKey, 7, 'Confirmed', [
          _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'AQID'),
        ]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _saveFirstSlot(WidgetTester tester, String slot) async {
  await tester.tap(find.byTooltip('Customer 7, Service 1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reschedule'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(slot));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

http.Client _scheduleFailureClient({
  required String todayKey,
  required int status,
  required String title,
  required void Function(String path) onGet,
}) {
  return MockClient((request) async {
    final path = request.url.path;
    if (request.method == 'GET') onGet(path);
    if (request.method == 'GET' && path == '/api/Appointments') {
      return _page([
        _appointment(42, todayKey, 7, 'Confirmed', [
          _line(7, 42, 1, 4, todayKey, '10:00:00', '10:30:00', 30, 'AQID'),
        ]),
      ]);
    }
    if (request.method == 'GET' && path == '/api/Availability') {
      return http.Response(
        jsonEncode([
          _availability(4, 'Kasun Perera', 1, 30, todayKey, '11:00:00', '11:30:00'),
        ]),
        200,
      );
    }
    if (request.method == 'POST' && path == '/api/Appointments/42/services/7/schedule') {
      return http.Response(jsonEncode({'title': title}), status);
    }
    return _unexpected(request);
  });
}

http.Response _unexpected(http.Request request) {
  return http.Response(
    jsonEncode({'title': 'Unexpected ${request.method} ${request.url}'}),
    500,
  );
}

http.Response _page(List<Map<String, dynamic>> items) {
  return http.Response(
    jsonEncode({'totalPages': 1, 'items': items}),
    200,
  );
}

Map<String, dynamic> _appointment(
  int id,
  String date,
  int customerId,
  String status,
  List<Map<String, dynamic>> services,
) {
  return {
    'appointmentId': id,
    'branchId': 1,
    'customerId': customerId,
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
  String date,
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
    'startTime': start == null ? null : '${date}T$start',
    'endTime': end == null ? null : '${date}T$end',
    'durationMinutes': duration,
    'isCancelled': cancelled,
    'isFullyScheduled': employeeId != null && start != null && !cancelled,
    'rowVersion': rowVersion,
  };
}

Map<String, dynamic> _availability(
  int employeeId,
  String name,
  int serviceId,
  int duration,
  String date,
  String start,
  String end,
) {
  return {
    'employeeId': employeeId,
    'employeeName': name,
    'serviceId': serviceId,
    'durationMinutes': duration,
    'slots': [
      {'startTime': '${date}T$start', 'endTime': '${date}T$end'},
    ],
  };
}

String _ymd(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
