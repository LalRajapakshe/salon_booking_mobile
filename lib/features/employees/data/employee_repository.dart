import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/employee_api_mapper.dart';
import '../models/employee_record.dart';

class EmployeeRepository {
  EmployeeRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  /// Signed-in sessions read `GET /api/Employees`.
  /// Tenant and branch stay on the authenticated user.
  Future<List<EmployeeRecord>> list() async {
    final employees = <EmployeeRecord>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/Employees?page=$page&pageSize=100');
      employees.addAll(EmployeeApiMapper.page(body));
      if (page >= EmployeeApiMapper.totalPages(body)) break;
      page++;
    }
    return employees;
  }

  /// `POST /api/Employees`. The server assigns the employee code, tenant, and branch.
  Future<EmployeeRecord> create({
    required String firstName,
    required String lastName,
    required String mobileNo,
    required String designation,
    required DateTime hireDate,
    required double salary,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'mobileNo': mobileNo.trim(),
      'designation': designation.trim(),
      'hireDate': _dateOnly(hireDate),
      'salary': salary,
    };
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) body['email'] = trimmedEmail;
    final trimmedGender = gender?.trim();
    if (trimmedGender != null && trimmedGender.isNotEmpty) body['gender'] = trimmedGender;
    if (dateOfBirth != null) body['dateOfBirth'] = _dateOnly(dateOfBirth);
    final trimmedAddress = address?.trim();
    if (trimmedAddress != null && trimmedAddress.isNotEmpty) body['address'] = trimmedAddress;

    final created = EmployeeApiMapper.employee(await _client.postJson('/api/Employees', body));
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  /// `PUT /api/Employees/{id}`. The employee code is left unchanged.
  Future<EmployeeRecord> update(EmployeeRecord employee) async {
    final hireDate = employee.hireDate;
    if (hireDate == null) {
      throw const ApiException('Hire date is required.');
    }
    final body = <String, dynamic>{
      'branchId': employee.branchId,
      'firstName': employee.firstName.trim(),
      'lastName': employee.lastName.trim(),
      'mobileNo': employee.mobileNo.trim(),
      'designation': (employee.designation ?? '').trim(),
      'hireDate': _dateOnly(hireDate),
      'salary': employee.salary,
      'isActive': employee.isActive,
    };
    final email = employee.email?.trim();
    if (email != null && email.isNotEmpty) body['email'] = email;
    final gender = employee.gender?.trim();
    if (gender != null && gender.isNotEmpty) body['gender'] = gender;
    if (employee.dateOfBirth != null) body['dateOfBirth'] = _dateOnly(employee.dateOfBirth!);
    final address = employee.address?.trim();
    if (address != null && address.isNotEmpty) body['address'] = address;

    return EmployeeApiMapper.employee(
      await _client.putJson('/api/Employees/${employee.id}', body),
    );
  }

  /// `DELETE /api/Employees/{id}` marks the row deleted. It stays in the database.
  Future<void> delete(int employeeId) {
    return _client.deleteJson('/api/Employees/$employeeId');
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
