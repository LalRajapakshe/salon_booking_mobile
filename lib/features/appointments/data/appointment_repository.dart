import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/appointment_api_mapper.dart';
import '../models/appointment.dart';
import '../models/appointment_service_line.dart';
import '../models/appointment_status.dart';
import '../services/appointment_catalog.dart';

class AppointmentRepository {
  AppointmentRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  /// Signed-in sessions read `GET /api/Appointments`.
  /// The list screen keeps the local catalog until a token exists so the
  /// current screens stay usable without a server.
  Future<List<Appointment>> list({DateTime? date}) async {
    if (!_session.isSignedIn) {
      return AppointmentCatalog.appointments;
    }

    final dateQuery = date == null ? '' : '&date=${_dateOnly(date)}';
    final appointments = <Appointment>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson(
        '/api/Appointments?page=$page&pageSize=100$dateQuery',
      );
      appointments.addAll(AppointmentApiMapper.page(body));
      if (page >= AppointmentApiMapper.totalPages(body)) break;
      page++;
    }
    return appointments;
  }

  /// `POST /api/Appointments`. Branch and tenant stay on the authenticated user.
  /// Employee and times are not header fields.
  Future<Appointment> create({
    required int customerId,
    required DateTime appointmentDate,
    required AppointmentStatus status,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'customerId': customerId,
      'appointmentDate': _dateOnly(appointmentDate),
    };
    final statusName = status.apiValue;
    if (statusName != null) body['status'] = statusName;
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) body['notes'] = trimmedNotes;

    final created = AppointmentApiMapper.appointment(await _client.postJson('/api/Appointments', body));
    if (created.appointmentId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  /// `POST /api/Appointments/{id}/services`. Duration, price, and sequence
  /// are taken from the service on the server.
  Future<AppointmentServiceLine> addService({
    required int appointmentId,
    required int serviceId,
    String? notes,
  }) async {
    final body = <String, dynamic>{'serviceId': serviceId};
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) body['notes'] = trimmedNotes;
    return AppointmentApiMapper.serviceLine(
      await _client.postJson('/api/Appointments/$appointmentId/services', body),
    );
  }

  Future<Appointment> get(int appointmentId) async {
    final appointment = AppointmentApiMapper.appointment(
      await _client.getJson('/api/Appointments/$appointmentId'),
    );
    if (appointment.appointmentId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return appointment;
  }

  /// `POST /api/Appointments/{id}/services/{lineId}/schedule`.
  Future<AppointmentServiceLine> scheduleLine({
    required int appointmentId,
    required int appointmentServiceId,
    required int employeeId,
    required DateTime startTime,
    required DateTime endTime,
    required String rowVersion,
  }) async {
    final scheduled = AppointmentApiMapper.serviceLine(
      await _client.postJson(
        '/api/Appointments/$appointmentId/services/$appointmentServiceId/schedule',
        {
          'employeeId': employeeId,
          'startTime': _timestamp(startTime),
          'endTime': _timestamp(endTime),
          'rowVersion': rowVersion,
        },
      ),
    );
    if (scheduled.rowVersion == null || scheduled.rowVersion!.isEmpty) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return scheduled;
  }

  static String _timestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-'
        '${two(value.month)}-${two(value.day)}T'
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
