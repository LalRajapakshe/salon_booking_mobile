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

  AppointmentRepository repository({required bool canManage}) {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: canManage ? {'appointments.manage'} : {},
    );
    return AppointmentRepository(
      client: ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(jsonEncode(_page()), 200);
        }),
      ),
    );
  }

  Future<void> pumpList(WidgetTester tester, AppointmentRepository repository) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: AppointmentsScreen(repository: repository)));
    await tester.pumpAndSettle();
  }

  testWidgets('the row shows a cancellation request and managers can decide it', (tester) async {
    await pumpList(tester, repository(canManage: true));

    expect(find.text('Cancellation requested'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Approve cancellation'), findsOneWidget);
    expect(find.text('Decline cancellation'), findsOneWidget);
  });

  testWidgets('users without appointments.manage do not see the decision actions', (tester) async {
    await pumpList(tester, repository(canManage: false));

    expect(find.text('Cancellation requested'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Approve cancellation'), findsNothing);
    expect(find.text('Decline cancellation'), findsNothing);
    expect(find.text('View'), findsOneWidget);
  });
}

Map<String, Object?> _page() {
  return {
    'totalPages': 1,
    'items': [
      {
        'appointmentId': 10,
        'branchId': 2,
        'customerId': 4,
        'appointmentDate': '2026-12-01',
        'status': 'Pending',
        'cancellationRequest': 'Requested',
        'services': [
          {
            'appointmentServiceId': 1,
            'appointmentId': 10,
            'serviceId': 15,
            'employeeId': null,
            'startTime': null,
            'endTime': null,
            'isCancelled': false,
            'isFullyScheduled': false,
          },
        ],
      },
    ],
  };
}
