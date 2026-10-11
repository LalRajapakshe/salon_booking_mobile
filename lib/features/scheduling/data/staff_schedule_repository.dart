import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/staff_schedule_api_mapper.dart';
import '../models/staff_schedule_record.dart';

class StaffScheduleRepository {
  StaffScheduleRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  /// `GET /api/StaffSchedules` for the token branch.
  Future<List<StaffScheduleRecord>> list() async {
    return StaffScheduleApiMapper.list(
      await _client.getJsonList('/api/StaffSchedules'),
    );
  }

  /// `POST /api/StaffSchedules`. Tenant and branch stay on the authenticated user.
  /// The row repeats every week for [dayOfWeek]. It is not one calendar date.
  Future<StaffScheduleRecord> createWorking({
    required int employeeId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final created = StaffScheduleApiMapper.record(
      await _client.postJson('/api/StaffSchedules', {
        'employeeId': employeeId,
        'dayOfWeek': dayOfWeek,
        'segmentType': 'Working',
        'startTime': startTime,
        'endTime': endTime,
        'isActive': true,
      }),
    );
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }
}
