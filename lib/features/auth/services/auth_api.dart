import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';

class AuthApi {
  AuthApi({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  Future<void> login({
    required String username,
    required String password,
    String? tenantCode,
  }) async {
    final payload = <String, dynamic>{
      'username': username,
      'password': password,
    };
    final code = tenantCode?.trim();
    if (code != null && code.isNotEmpty) payload['tenantCode'] = code;

    final body = await _client.postJson('/api/Auth/login', payload);
    final token = body['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Sign in did not return a token.');
    }

    final profile = body['profile'];
    final permissions = <String>{};
    String? fullName;
    if (profile is Map) {
      fullName = profile['fullName'] as String?;
      final granted = profile['permissions'];
      if (granted is List) {
        permissions.addAll(granted.whereType<String>());
      }
    }

    _session.save(
      accessToken: token,
      username: body['username'] as String? ?? username,
      fullName: fullName,
      expiresAt: DateTime.tryParse(body['expiresAt'] as String? ?? '') ?? DateTime.now(),
      permissions: permissions,
    );
  }
}
