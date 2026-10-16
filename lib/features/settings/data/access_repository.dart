import '../../../core/api/api_client.dart';

class AccessUser {
  AccessUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.category,
    required this.isActive,
    this.email,
    this.mobileNo,
    this.branchId,
    this.employeeId,
    this.customerId,
    this.roleIds = const [],
    this.roleNames = const [],
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? email;
  final String? mobileNo;
  final String category;
  final int? branchId;
  final int? employeeId;
  final int? customerId;
  final bool isActive;
  final List<int> roleIds;
  final List<String> roleNames;

  factory AccessUser.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    final roleIds = <int>[];
    final roleNames = <String>[];
    if (roles is List) {
      for (final role in roles) {
        if (role is Map) {
          final id = _int(role['roleId']);
          if (id != null) roleIds.add(id);
          final name = role['roleName'];
          if (name is String && name.isNotEmpty) roleNames.add(name);
        }
      }
    }
    return AccessUser(
      id: _int(json['userId']) ?? 0,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      mobileNo: json['mobileNo'] as String?,
      category: json['userCategory'] as String? ?? 'General',
      branchId: _int(json['branchId']),
      employeeId: _int(json['employeeId']),
      customerId: _int(json['customerId']),
      isActive: json['isActive'] == true,
      roleIds: roleIds,
      roleNames: roleNames,
    );
  }
}

class AccessRole {
  AccessRole({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    this.description,
    this.permissionIds = const [],
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final List<int> permissionIds;

  factory AccessRole.fromJson(Map<String, dynamic> json) {
    final ids = <int>[];
    final raw = json['permissionIds'];
    if (raw is List) {
      for (final id in raw) {
        final parsed = _int(id);
        if (parsed != null) ids.add(parsed);
      }
    }
    return AccessRole(
      id: _int(json['roleId']) ?? 0,
      code: json['roleCode'] as String? ?? '',
      name: json['roleName'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['isActive'] == true,
      permissionIds: ids,
    );
  }
}

class AccessPermission {
  AccessPermission({
    required this.id,
    required this.code,
    required this.name,
    required this.area,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String area;
  final String? description;

  factory AccessPermission.fromJson(Map<String, dynamic> json) {
    return AccessPermission(
      id: _int(json['permissionId']) ?? 0,
      code: json['permissionCode'] as String? ?? '',
      name: json['permissionName'] as String? ?? '',
      area: json['area'] as String? ?? 'Other',
      description: json['description'] as String?,
    );
  }
}

class DirectoryOption {
  DirectoryOption({required this.id, required this.label});

  final int id;
  final String label;
}

class AccessRepository {
  AccessRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<AccessUser>> listUsers() async {
    final body = await _client.getJson('/api/Users?page=1&pageSize=100');
    return _maps(body['items']).map(AccessUser.fromJson).toList();
  }

  Future<AccessUser> saveUser({
    int? id,
    required String username,
    required String firstName,
    required String lastName,
    required String category,
    required List<int> roleIds,
    String? password,
    String? email,
    String? mobileNo,
    int? branchId,
    int? employeeId,
    int? customerId,
  }) async {
    final payload = <String, dynamic>{
      'username': username.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'userCategory': category,
      'roleIds': roleIds,
    };
    if (password != null && password.isNotEmpty) payload['password'] = password;
    if (email != null && email.trim().isNotEmpty) payload['email'] = email.trim();
    if (mobileNo != null && mobileNo.trim().isNotEmpty) payload['mobileNo'] = mobileNo.trim();
    if (branchId != null) payload['branchId'] = branchId;
    if (employeeId != null) payload['employeeId'] = employeeId;
    if (customerId != null) payload['customerId'] = customerId;

    final body = id == null
        ? await _client.postJson('/api/Users', payload)
        : await _client.putJson('/api/Users/$id', payload);
    return AccessUser.fromJson(body);
  }

  Future<void> setActive(int id, bool isActive) async {
    await _client.postJson('/api/Users/$id/activation', {'isActive': isActive});
  }

  Future<List<AccessRole>> listRoles() async {
    final body = await _client.getJsonList('/api/Roles');
    return body.whereType<Map>().map((item) => AccessRole.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<AccessRole> saveRole({
    int? id,
    required String code,
    required String name,
    required bool isActive,
    String? description,
  }) async {
    final payload = {
      'roleCode': code.trim(),
      'roleName': name.trim(),
      'description': description?.trim(),
      'isActive': isActive,
    };
    final body = id == null
        ? await _client.postJson('/api/Roles', payload)
        : await _client.putJson('/api/Roles/$id', payload);
    return AccessRole.fromJson(body);
  }

  Future<void> setRolePermissions(int roleId, List<int> permissionIds) async {
    await _client.putJson('/api/Roles/$roleId/permissions', {'permissionIds': permissionIds});
  }

  Future<List<AccessPermission>> listPermissions() async {
    final body = await _client.getJsonList('/api/Permissions');
    return body
        .whereType<Map>()
        .map((item) => AccessPermission.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<DirectoryOption>> listEmployees() async {
    final body = await _client.getJson('/api/Employees?page=1&pageSize=100');
    return _maps(body['items']).map((item) {
      final id = _int(item['employeeId']) ?? 0;
      final name = item['fullName'] as String? ?? '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'.trim();
      return DirectoryOption(id: id, label: name.isEmpty ? 'Employee $id' : name);
    }).where((item) => item.id > 0).toList();
  }

  Future<List<DirectoryOption>> listCustomers() async {
    final body = await _client.getJson('/api/Customers?page=1&pageSize=100');
    return _maps(body['items']).map((item) {
      final id = _int(item['customerId']) ?? 0;
      final name = item['fullName'] as String? ?? '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'.trim();
      return DirectoryOption(id: id, label: name.isEmpty ? 'Customer $id' : name);
    }).where((item) => item.id > 0).toList();
  }

  Future<List<DirectoryOption>> listBranches() async {
    final body = await _client.getJson('/api/Branch?page=1&pageSize=100');
    return _maps(body['items']).map((item) {
      final id = _int(item['branchId']) ?? 0;
      final name = item['branchName'] as String? ?? 'Branch $id';
      return DirectoryOption(id: id, label: name);
    }).where((item) => item.id > 0).toList();
  }
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return [];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
