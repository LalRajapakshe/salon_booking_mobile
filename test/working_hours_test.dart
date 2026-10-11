import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/employees/data/employee_repository.dart';
import 'package:salon_booking_mobile/features/scheduling/data/staff_schedule_repository.dart';
import 'package:salon_booking_mobile/features/scheduling/widgets/working_hours_dialog.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  testWidgets('signed-out working hours asks for sign in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkingHoursDialog(date: DateTime(2026, 10, 10)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to save working hours.'), findsOneWidget);
  });

  testWidgets('saving Saturday hours posts the weekly working row', (tester) async {
    final requests = <http.Request>[];
    final saved = <Map<String, dynamic>>[
      {
        'staffScheduleId': 1,
        'employeeId': 3,
        'dayOfWeek': 2,
        'segmentType': 'Working',
        'startTime': '09:00:00',
        'endTime': '17:00:00',
        'isActive': true,
      },
    ];
    final session = _signedIn();
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          saved.add({
            'staffScheduleId': 2,
            'employeeId': body['employeeId'],
            'dayOfWeek': body['dayOfWeek'],
            'segmentType': body['segmentType'],
            'startTime': body['startTime'],
            'endTime': body['endTime'],
            'isActive': true,
          });
          return http.Response(jsonEncode(saved.last), 200);
        }
        return http.Response(jsonEncode(_body(request, saved)), 200);
      }),
      session: session,
    );

    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showWorkingHoursDialog(
                  context: context,
                  date: DateTime(2026, 10, 10),
                  employees: EmployeeRepository(client: client, session: session),
                  schedules: StaffScheduleRepository(client: client, session: session),
                ),
                child: const Text('Open hours'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open hours'));
    await tester.pumpAndSettle();

    expect(find.text('Saturday'), findsOneWidget);
    await _choose<int>(tester, 'Employee', 'Tharaka Ashantha · EMP000003');
    expect(find.text('Tuesday · Working · 09:00–17:00'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final create = requests.where((request) => request.method == 'POST').single;
    final body = jsonDecode(create.body) as Map<String, dynamic>;
    expect(create.url.path, '/api/StaffSchedules');
    expect(body['employeeId'], 3);
    expect(body['dayOfWeek'], 6);
    expect(body['segmentType'], 'Working');
    expect(body['startTime'], '09:00:00');
    expect(body['endTime'], '17:00:00');
    expect(body['isActive'], isTrue);
    expect(body.containsKey('tenantId'), isFalse);
    expect(body.containsKey('branchId'), isFalse);
    expect(find.text('Saturday hours were saved for Tharaka Ashantha.'), findsOneWidget);
    expect(find.text('Saturday · Working · 09:00–17:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AuthSession _signedIn() {
  AuthSession.instance.save(
    accessToken: 'test-token',
    username: 'tester',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  return AuthSession.instance;
}

Future<void> _choose<T>(WidgetTester tester, String label, String option) async {
  final field = find.widgetWithText(DropdownButtonFormField<T>, label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Object _body(http.Request request, List<Map<String, dynamic>> saved) {
  if (request.url.path == '/api/Employees') {
    return {
      'totalPages': 1,
      'items': [
        {
          'employeeId': 3,
          'employeeCode': 'EMP000003',
          'firstName': 'Tharaka',
          'lastName': 'Ashantha',
          'mobileNo': '0710000001',
          'designation': 'Stylist',
          'salary': 0,
          'isActive': true,
          'createdDate': '2026-10-01T00:00:00',
          'branchId': 1,
          'tenantId': 1,
        },
      ],
    };
  }
  if (request.url.path == '/api/StaffSchedules') return saved;
  return {};
}
