import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/employee_capability_api_mapper.dart';
import '../models/employee_capability_record.dart';

class EmployeeCapabilityRepository {
  EmployeeCapabilityRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  /// Signed-in sessions read `GET /api/EmployeeCapabilities` for the token branch.
  Future<List<EmployeeCapabilityRecord>> list() async {
    return EmployeeCapabilityApiMapper.list(
      await _client.getJsonList('/api/EmployeeCapabilities'),
    );
  }

  /// `POST /api/EmployeeCapabilities`. Tenant and branch stay on the authenticated user.
  Future<EmployeeCapabilityRecord> assign({
    required int employeeId,
    required int serviceId,
  }) async {
    final created = EmployeeCapabilityApiMapper.record(
      await _client.postJson('/api/EmployeeCapabilities', {
        'employeeId': employeeId,
        'serviceId': serviceId,
      }),
    );
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }
}
