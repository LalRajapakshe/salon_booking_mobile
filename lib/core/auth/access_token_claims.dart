import 'dart:convert';

/// Reads claims the API already placed on the access token.
///
/// The signature is not checked here. The server still enforces tenant and
/// branch on every request.
class AccessTokenClaims {
  const AccessTokenClaims._();

  static int? branchId(String? token) {
    final value = _claim(token, 'BranchId');
    if (value == null || value <= 0) return null;
    return value;
  }

  static int? tenantId(String? token) {
    final value = _claim(token, 'TenantId');
    if (value == null || value <= 0) return null;
    return value;
  }

  static int? _claim(String? token, String name) {
    final payload = _payload(token);
    if (payload == null) return null;
    return _int(payload[name]);
  }

  static Map<String, dynamic>? _payload(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return Map<String, dynamic>.from(payload);
    } catch (_) {
      return null;
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
