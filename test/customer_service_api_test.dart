import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/customers/api/customer_api_mapper.dart';
import 'package:salon_booking_mobile/features/customers/data/customer_repository.dart';
import 'package:salon_booking_mobile/features/services/api/service_api_mapper.dart';
import 'package:salon_booking_mobile/features/services/data/service_repository.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  String tokenWithBranch(String branchId) {
    String part(Object value) {
      return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    }

    return '${part({'alg': 'none'})}.${part({'BranchId': branchId})}.x';
  }

  void signIn(String token) {
    AuthSession.instance.save(
      accessToken: token,
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  test('customer page maps mobile and remarks and keeps address empty', () {
    final customers = CustomerApiMapper.page({
      'totalPages': 1,
      'items': [
        {
          'customerId': 3,
          'customerCode': 'CUS000003',
          'firstName': 'Nimal',
          'lastName': 'Perera',
          'mobileNo': '0771234567',
          'email': 'nimal@example.com',
          'gender': 'Male',
          'dateOfBirth': '1990-04-02',
          'remarks': 'Evening',
          'isActive': true,
          'createdDate': '2026-10-09T10:00:00',
          'tenantId': 1,
          'branchId': 1,
        },
      ],
    });

    final customer = customers.single;
    expect(customer.id, 3);
    expect(customer.customerCode, 'CUS000003');
    expect(customer.mobileNumber, '0771234567');
    expect(customer.notes, 'Evening');
    expect(customer.address, isNull);
    expect(customer.fullName, 'Nimal Perera');
  });

  test('customer create omits tenant, branch, code, and address', () async {
    final requests = <http.Request>[];
    signIn('test-token');
    final repository = CustomerRepository(
      client: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'customerId': 8,
              'customerCode': 'CUS000008',
              'firstName': 'Nimal',
              'lastName': 'Perera',
              'mobileNo': '0771234567',
              'remarks': 'Evening',
              'isActive': true,
              'createdDate': '2026-10-09T10:00:00',
              'tenantId': 1,
              'branchId': 1,
            }),
            200,
          );
        }),
        session: AuthSession.instance,
      ),
      session: AuthSession.instance,
    );

    final created = await repository.create(
      firstName: ' Nimal ',
      lastName: ' Perera ',
      mobileNo: '0771234567',
      email: ' ',
      gender: 'Male',
      dateOfBirth: DateTime(1990, 4, 2, 15),
      remarks: ' Evening ',
    );

    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/Customers');
    expect(body.keys, isNot(contains('tenantId')));
    expect(body.keys, isNot(contains('branchId')));
    expect(body.keys, isNot(contains('customerCode')));
    expect(body.keys, isNot(contains('address')));
    expect(body['firstName'], 'Nimal');
    expect(body['mobileNo'], '0771234567');
    expect(body['dateOfBirth'], '1990-04-02');
    expect(body['remarks'], 'Evening');
    expect(body.containsKey('email'), isFalse);
    expect(created.customerCode, 'CUS000008');
  });

  test('service create sends the token branch and omits cost', () async {
    final requests = <http.Request>[];
    signIn(tokenWithBranch('1'));
    final repository = ServiceRepository(
      client: ApiClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/ServiceCategories') {
            return http.Response(
              jsonEncode({
                'totalPages': 1,
                'items': [
                  {'serviceCategoryId': 1, 'categoryName': 'Hair'},
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'serviceId': 4,
              'serviceCode': 'SER000004',
              'serviceName': 'Beard Trim',
              'description': 'Short trim',
              'durationMinutes': 20,
              'price': 800,
              'cost': 0,
              'commissionPercentage': 0,
              'serviceCategoryId': 1,
              'isActive': true,
              'createdDate': '2026-10-09T10:00:00',
              'branchId': 1,
              'tenantId': 1,
            }),
            200,
          );
        }),
        session: AuthSession.instance,
      ),
      session: AuthSession.instance,
    );

    final created = await repository.create(
      serviceCategoryId: 1,
      serviceName: ' Beard Trim ',
      description: ' Short trim ',
      durationMinutes: 20,
      price: 800,
      categoryName: 'Hair',
    );

    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(requests.single.url.path, '/api/Services');
    expect(body['branchId'], 1);
    expect(body['serviceCategoryId'], 1);
    expect(body['serviceName'], 'Beard Trim');
    expect(body['description'], 'Short trim');
    expect(body['durationMinutes'], 20);
    expect(body['price'], 800);
    expect(body.containsKey('cost'), isFalse);
    expect(body.containsKey('commissionPercentage'), isFalse);
    expect(body.containsKey('tenantId'), isFalse);
    expect(created.serviceCode, 'SER000004');
    expect(created.categoryName, 'Hair');
    expect(created.serviceCategoryId, 1);
  });

  test('service list joins the category name', () {
    final services = ServiceApiMapper.page({
      'items': [
        {
          'serviceId': 1,
          'serviceCode': 'SER000001',
          'serviceName': 'Haircut',
          'description': '',
          'durationMinutes': 30,
          'price': 1000,
          'serviceCategoryId': 1,
          'isActive': true,
          'createdDate': '2026-10-06T00:00:00',
          'branchId': 1,
          'tenantId': 1,
        },
      ],
    }, {1: 'Hair'});

    expect(services.single.categoryName, 'Hair');
    expect(services.single.price, 1000);
  });
}
