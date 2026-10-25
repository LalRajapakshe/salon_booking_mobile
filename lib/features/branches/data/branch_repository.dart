import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/access_token_claims.dart';
import '../../../core/auth/auth_session.dart';
import '../models/branch_record.dart';

class BranchRepository {
  BranchRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  Future<List<BranchRecord>> list() async {
    final branches = <BranchRecord>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/Branch?page=$page&pageSize=100');
      final items = body['items'];
      if (items is List) {
        branches.addAll([
          for (final item in items)
            if (item is Map<String, dynamic>) _branch(item),
        ]);
      }
      final pages = body['totalPages'];
      final total = pages is num && pages > 0 ? pages.toInt() : 1;
      if (page >= total) break;
      page++;
    }
    return branches;
  }

  Future<BranchRecord> create({
    required String branchName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? phoneNo,
    String? email,
    String? managerName,
    required bool isHeadOffice,
  }) async {
    final tenantId = AccessTokenClaims.tenantId(_session.accessToken);
    if (tenantId == null) {
      throw const ApiException('A salon is required.');
    }
    final created = _branch(
      await _client.postJson('/api/Branch', {
        'tenantId': tenantId,
        'branchName': branchName.trim(),
        'addressLine1': _empty(addressLine1),
        'addressLine2': _empty(addressLine2),
        'city': _empty(city),
        'phoneNo': _empty(phoneNo),
        'email': _empty(email),
        'managerName': _empty(managerName),
        'isHeadOffice': isHeadOffice,
      }),
    );
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  Future<BranchRecord> update(BranchRecord branch) async {
    return _branch(
      await _client.putJson('/api/Branch/${branch.id}', {
        'tenantId': branch.tenantId,
        'branchName': branch.branchName.trim(),
        'addressLine1': _empty(branch.addressLine1),
        'addressLine2': _empty(branch.addressLine2),
        'city': _empty(branch.city),
        'phoneNo': _empty(branch.phoneNo),
        'email': _empty(branch.email),
        'managerName': _empty(branch.managerName),
        'isHeadOffice': branch.isHeadOffice,
        'isActive': branch.isActive,
      }),
    );
  }

  /// `DELETE /api/Branch/{id}` marks the row deleted. It stays in the database.
  Future<void> delete(int branchId) {
    return _client.deleteJson('/api/Branch/$branchId');
  }

  static String? _empty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static BranchRecord _branch(Map<String, dynamic> json) {
    int number(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    String? text(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return BranchRecord(
      id: number(json['branchId']),
      tenantId: number(json['tenantId']),
      branchCode: json['branchCode'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      addressLine1: text(json['addressLine1']),
      addressLine2: text(json['addressLine2']),
      city: text(json['city']),
      phoneNo: text(json['phoneNo']),
      email: text(json['email']),
      managerName: text(json['managerName']),
      isHeadOffice: json['isHeadOffice'] == true,
      isActive: json['isActive'] == true,
    );
  }
}
