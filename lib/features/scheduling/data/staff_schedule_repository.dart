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

  /// `GET /api/StaffSchedules` for the token branch, or [branchId] when the
  /// signed-in account covers every branch.
  Future<List<StaffScheduleRecord>> list({int? branchId}) async {
    final query = branchId != null && branchId > 0 ? '?branchId=$branchId' : '';
    return StaffScheduleApiMapper.list(
      await _client.getJsonList('/api/StaffSchedules$query'),
    );
  }

  /// `POST /api/StaffSchedules`. Tenant and branch stay on the authenticated user.
  /// The row repeats every week for [dayOfWeek]. It is not one calendar date.
  Future<StaffScheduleRecord> createWorking({
    required int employeeId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? branchId,
  }) async {
    final body = <String, dynamic>{
      'employeeId': employeeId,
      'dayOfWeek': dayOfWeek,
      'segmentType': 'Working',
      'startTime': startTime,
      'endTime': endTime,
      'isActive': true,
    };
    if (branchId != null && branchId > 0) body['branchId'] = branchId;
    final created = StaffScheduleApiMapper.record(
      await _client.postJson('/api/StaffSchedules', body),
    );
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }
}
