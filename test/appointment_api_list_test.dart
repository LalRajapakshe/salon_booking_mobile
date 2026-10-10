import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/appointments/data/appointment_repository.dart';
import 'package:salon_booking_mobile/features/appointments/screens/appointments_screen.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  AppointmentRepository repositoryFor(http.Client httpClient) {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    return AppointmentRepository(client: ApiClient(httpClient: httpClient));
  }

  Future<void> pumpList(WidgetTester tester, AppointmentRepository repository) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: AppointmentsScreen(repository: repository)));
    await tester.pumpAndSettle();
  }

  testWidgets('signed-in list shows an API failure and recovers on retry', (tester) async {
    var calls = 0;
    final repository = repositoryFor(MockClient((request) async {
      calls++;
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.url.path, '/api/Appointments');
      expect(request.url.queryParameters.containsKey('tenantId'), isFalse);
      expect(request.url.queryParameters.containsKey('branchId'), isFalse);
      if (calls == 1) {
        return http.Response(jsonEncode({'title': 'A branch is required.'}), 500);
      }
      return http.Response(
        jsonEncode({
          'totalPages': 1,
          'items': [
            {
              'appointmentId': 10,
              'branchId': 2,
              'customerId': 999,
              'appointmentDate': '2026-10-06',
              'status': 'Pending',
              'services': [
                {
                  'appointmentServiceId': 1,
                  'appointmentId': 10,
                  'serviceId': 777,
                  'employeeId': null,
                  'startTime': null,
                  'endTime': null,
                  'isCancelled': false,
                  'isFullyScheduled': false,
                },
              ],
            },
          ],
        }),
        200,
      );
    }));

    await pumpList(tester, repository);

    expect(find.text('A branch is required.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Customer 999'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);
    expect(find.text('Service 777'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unreachable server leaves the appointment list usable', (tester) async {
    final repository = repositoryFor(MockClient((request) async {
      throw Exception('connection refused');
    }));

    await pumpList(tester, repository);

    expect(find.text('Cannot reach the salon server.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
