import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/customer_api_mapper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  CustomerRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  /// Signed-in sessions read `GET /api/Customers`.
  /// Tenant and branch stay on the authenticated user.
  Future<List<Customer>> list() async {
    final customers = <Customer>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/Customers?page=$page&pageSize=100');
      customers.addAll(CustomerApiMapper.page(body));
      if (page >= CustomerApiMapper.totalPages(body)) break;
      page++;
    }
    return customers;
  }

  /// `POST /api/Customers`. The server assigns the customer code, tenant, and branch.
  Future<Customer> create({
    required String firstName,
    required String lastName,
    required String mobileNo,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'mobileNo': mobileNo.trim(),
    };
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) body['email'] = trimmedEmail;
    final trimmedGender = gender?.trim();
    if (trimmedGender != null && trimmedGender.isNotEmpty) body['gender'] = trimmedGender;
    if (dateOfBirth != null) body['dateOfBirth'] = _dateOnly(dateOfBirth);
    final trimmedRemarks = remarks?.trim();
    if (trimmedRemarks != null && trimmedRemarks.isNotEmpty) body['remarks'] = trimmedRemarks;

    final created = CustomerApiMapper.customer(await _client.postJson('/api/Customers', body));
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
