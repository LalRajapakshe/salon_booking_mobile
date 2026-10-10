import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/availability_api_mapper.dart';
import '../models/employee_availability.dart';

class AvailabilityRepository {
  AvailabilityRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  /// `GET /api/Availability`. Duration comes from the service record.
  /// Branch and tenant stay on the authenticated user.
  Future<List<EmployeeAvailability>> find({
    required int serviceId,
    required DateTime date,
    int? employeeId,
  }) async {
    if (!_session.isSignedIn) {
      throw const ApiException('Sign in is required.', statusCode: 401);
    }

    final employeeQuery = employeeId == null || employeeId <= 0
        ? ''
        : '&employeeId=$employeeId';
    final body = await _client.getJsonList(
      '/api/Availability?serviceId=$serviceId&date=${_dateOnly(date)}$employeeQuery',
    );
    return AvailabilityApiMapper.employees(body);
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
