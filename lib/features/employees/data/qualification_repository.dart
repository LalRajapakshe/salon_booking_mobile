import '../../../core/api/api_client.dart';

class QualificationRecord {
  final int id;
  final String name;
  final String? level;
  final String? description;
  final bool isActive;

  const QualificationRecord({
    required this.id,
    required this.name,
    this.level,
    this.description,
    required this.isActive,
  });

  factory QualificationRecord.fromJson(Map<String, dynamic> json) {
    return QualificationRecord(
      id: json['qualificationId'] is num ? (json['qualificationId'] as num).toInt() : 0,
      name: json['qualificationName'] as String? ?? '',
      level: json['qualificationLevel'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] == true,
    );
  }
}

class EmployeeQualificationRecord {
  final int id;
  final int employeeId;
  final int qualificationId;
  final String name;
  final String? level;
  final String? institution;
  final int? year;
  final String verificationStatus;
  final bool isCustomerVisible;

  const EmployeeQualificationRecord({
    required this.id,
    required this.employeeId,
    required this.qualificationId,
    required this.name,
    this.level,
    this.institution,
    this.year,
    required this.verificationStatus,
    required this.isCustomerVisible,
  });

  factory EmployeeQualificationRecord.fromJson(Map<String, dynamic> json) {
    return EmployeeQualificationRecord(
      id: json['employeeQualificationId'] is num ? (json['employeeQualificationId'] as num).toInt() : 0,
      employeeId: json['employeeId'] is num ? (json['employeeId'] as num).toInt() : 0,
      qualificationId: json['qualificationId'] is num ? (json['qualificationId'] as num).toInt() : 0,
      name: json['qualificationName'] as String? ?? '',
      level: json['qualificationLevel'] as String?,
      institution: json['awardingInstitution'] as String?,
      year: json['completionYear'] is num ? (json['completionYear'] as num).toInt() : null,
      verificationStatus: json['verificationStatus'] as String? ?? 'Pending',
      isCustomerVisible: json['isCustomerVisible'] == true,
    );
  }
}

class QualificationRepository {
  QualificationRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<QualificationRecord>> list() async {
    final rows = await _client.getJsonList('/api/Qualifications');
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) QualificationRecord.fromJson(row),
    ];
  }

  Future<QualificationRecord> create({
    required String name,
    String? level,
    String? description,
  }) async {
    return QualificationRecord.fromJson(
      await _client.postJson('/api/Qualifications', {
        'qualificationName': name.trim(),
        'qualificationLevel': _empty(level),
        'description': _empty(description),
        'isActive': true,
      }),
    );
  }

  Future<List<EmployeeQualificationRecord>> forEmployee(int employeeId) async {
    final rows = await _client.getJsonList('/api/Qualifications/employees/$employeeId');
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) EmployeeQualificationRecord.fromJson(row),
    ];
  }

  Future<EmployeeQualificationRecord> saveLink({
    int? id,
    required int employeeId,
    required int qualificationId,
    String? institution,
    int? year,
    required String verificationStatus,
    required bool isCustomerVisible,
  }) async {
    final body = {
      'employeeId': employeeId,
      'qualificationId': qualificationId,
      'awardingInstitution': _empty(institution),
      'completionYear': year,
      'verificationStatus': verificationStatus,
      'isCustomerVisible': isCustomerVisible,
    };
    final json = id == null
        ? await _client.postJson('/api/Qualifications/employees', body)
        : await _client.putJson('/api/Qualifications/employees/$id', body);
    return EmployeeQualificationRecord.fromJson(json);
  }

  Future<void> removeLink(int id) {
    return _client.deleteJson('/api/Qualifications/employees/$id');
  }

  static String? _empty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
