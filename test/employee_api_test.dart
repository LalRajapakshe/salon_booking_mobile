import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/employees/data/employee_repository.dart';
import 'package:salon_booking_mobile/features/employees/screens/create_employee_screen.dart';
import 'package:salon_booking_mobile/features/employees/screens/employees_screen.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  EmployeeRepository repositoryFor(List<http.Request> requests) {
    AuthSession.instance.save(
      accessToken: 'test-token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final session = AuthSession.instance;
    return EmployeeRepository(
      client: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
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
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'employeeId': 9,
              'employeeCode': 'EMP000009',
              'firstName': 'Nimal',
              'lastName': 'Perera',
              'mobileNo': '0771234567',
              'designation': 'Stylist',
              'hireDate': '2026-10-10',
              'salary': 1000,
              'isActive': true,
              'createdDate': '2026-10-10T00:00:00',
              'branchId': 1,
              'tenantId': 1,
            }),
            200,
          );
        }),
        session: session,
      ),
      session: session,
    );
  }

  testWidgets('signed-out employee list asks for sign in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmployeesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to manage employees.'), findsOneWidget);
    expect(find.text('Add Employee'), findsOneWidget);
  });

  testWidgets('signed-in list and create use the employee API', (tester) async {
    final requests = <http.Request>[];
    final repository = repositoryFor(requests);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: EmployeesScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Tharaka Ashantha'), findsOneWidget);
    expect(find.text('EMP000003'), findsOneWidget);

    await tester.tap(find.text('Add Employee'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'First Name'), 'Nimal');
    await tester.enterText(find.widgetWithText(TextFormField, 'Last Name'), 'Perera');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile Number'), '0771234567');
    await tester.enterText(find.widgetWithText(TextFormField, 'Designation'), 'Stylist');
    await tester.enterText(find.widgetWithText(TextFormField, 'Salary'), '1000');

    final hireDate = find.widgetWithText(TextFormField, 'Hire Date');
    await tester.ensureVisible(hireDate);
    await tester.tap(hireDate);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final create = requests.where((request) => request.method == 'POST').single;
    final body = jsonDecode(create.body) as Map<String, dynamic>;
    expect(create.url.path, '/api/Employees');
    expect(body['firstName'], 'Nimal');
    expect(body['lastName'], 'Perera');
    expect(body['mobileNo'], '0771234567');
    expect(body['designation'], 'Stylist');
    expect(body['salary'], 1000);
    expect(body.containsKey('tenantId'), isFalse);
    expect(body.containsKey('branchId'), isFalse);
    expect(body.containsKey('employeeCode'), isFalse);
    expect(find.text('Nimal Perera was saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
