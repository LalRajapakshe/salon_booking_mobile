import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';

class AuthApi {
  AuthApi({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  Future<void> login({required String username, required String password}) async {
    final body = await _client.postJson('/api/Auth/login', {
      'username': username,
      'password': password,
    });
    final token = body['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Sign in did not return a token.');
    }

    _session.save(
      accessToken: token,
      username: body['username'] as String? ?? username,
      expiresAt: DateTime.tryParse(body['expiresAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
