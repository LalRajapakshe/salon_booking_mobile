import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/employees/data/employee_capability_repository.dart';
import 'package:salon_booking_mobile/features/employees/data/employee_repository.dart';
import 'package:salon_booking_mobile/features/employees/screens/assign_employee_service_screen.dart';
import 'package:salon_booking_mobile/features/employees/screens/employees_screen.dart';
import 'package:salon_booking_mobile/features/services/data/service_repository.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  testWidgets('signed-out assign service asks for sign in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AssignEmployeeServiceScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to assign services.'), findsOneWidget);
  });

  testWidgets('assign posts the selected employee and service', (tester) async {
    final requests = <http.Request>[];
    final links = <Map<String, dynamic>>[
      {
        'employeeServiceId': 1,
        'employeeId': 3,
        'serviceId': 1,
        'isActive': true,
      },
    ];
    final session = _signedIn();
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['employeeId'] == 3 && body['serviceId'] == 1) {
            return http.Response(
              jsonEncode({'title': 'This employee is already assigned to the service.'}),
              400,
            );
          }
          links.add({
            'employeeServiceId': 2,
            'employeeId': body['employeeId'],
            'serviceId': body['serviceId'],
            'isActive': true,
          });
          return http.Response(jsonEncode(links.last), 200);
        }
        return http.Response(jsonEncode(_body(request, links)), 200);
      }),
      session: session,
    );
    final employees = EmployeeRepository(client: client, session: session);
    final services = ServiceRepository(client: client, session: session);
    final capabilities = EmployeeCapabilityRepository(client: client, session: session);

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AssignEmployeeServiceScreen(
          employees: employees,
          services: services,
          capabilities: capabilities,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tharaka Ashantha'), findsOneWidget);
    expect(find.text('Haircut'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an employee and a service.'), findsOneWidget);
    expect(requests.where((request) => request.method == 'POST'), isEmpty);

    await _choose<int>(tester, 'Employee', 'Nimal Perera · EMP000009');
    await _choose<int>(tester, 'Service', 'Beard Trim');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final create = requests.where((request) => request.method == 'POST').single;
    final body = jsonDecode(create.body) as Map<String, dynamic>;
    expect(create.url.path, '/api/EmployeeCapabilities');
    expect(body['employeeId'], 9);
    expect(body['serviceId'], 4);
    expect(body.containsKey('tenantId'), isFalse);
    expect(body.containsKey('branchId'), isFalse);
    expect(body.containsKey('preferenceOrder'), isFalse);
    expect(find.text('Beard Trim was assigned to Nimal Perera.'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('employees screen opens assign service', (tester) async {
    final requests = <http.Request>[];
    final session = _signedIn();
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode(_body(request, const <Map<String, dynamic>>[])), 200);
      }),
      session: session,
    );
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeesScreen(
          repository: EmployeeRepository(client: client, session: session),
          services: ServiceRepository(client: client, session: session),
          capabilities: EmployeeCapabilityRepository(client: client, session: session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assign Service'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a saved employee and a saved service they can perform. Working hours stay separate.'), findsOneWidget);
    expect(
      requests.where((request) => request.url.path == '/api/EmployeeCapabilities'),
      isNotEmpty,
    );
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

Object _body(http.Request request, List<Map<String, dynamic>> links) {
  switch (request.url.path) {
    case '/api/Employees':
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
          {
            'employeeId': 9,
            'employeeCode': 'EMP000009',
            'firstName': 'Nimal',
            'lastName': 'Perera',
            'mobileNo': '0771234567',
            'designation': 'Stylist',
            'salary': 1000,
            'isActive': true,
            'createdDate': '2026-10-10T00:00:00',
            'branchId': 1,
            'tenantId': 1,
          },
        ],
      };
    case '/api/ServiceCategories':
      return {
        'totalPages': 1,
        'items': [
          {'serviceCategoryId': 1, 'categoryName': 'Hair'},
        ],
      };
    case '/api/Services':
      return {
        'totalPages': 1,
        'items': [
          {
            'serviceId': 1,
            'serviceCode': 'SER000001',
            'serviceName': 'Haircut',
            'durationMinutes': 30,
            'price': 1000,
            'branchId': 1,
            'serviceCategoryId': 1,
            'description': '',
            'isActive': true,
            'createdDate': '2026-10-06T00:00:00',
          },
          {
            'serviceId': 4,
            'serviceCode': 'SER000004',
            'serviceName': 'Beard Trim',
            'durationMinutes': 20,
            'price': 800,
            'branchId': 1,
            'serviceCategoryId': 1,
            'description': '',
            'isActive': true,
            'createdDate': '2026-10-10T00:00:00',
          },
        ],
      };
    case '/api/EmployeeCapabilities':
      return links;
    default:
      return {};
  }
}
