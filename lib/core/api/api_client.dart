import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, AuthSession? session, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _session = session ?? AuthSession.instance,
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _http;
  final AuthSession _session;
  final String _baseUrl;

  Future<Map<String, dynamic>> getJson(String path) {
    return _sendMap(() => _http.get(_uri(path), headers: _headers()));
  }

  Future<List<dynamic>> getJsonList(String path) {
    return _sendList(() => _http.get(_uri(path), headers: _headers()));
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) {
    return _sendMap(
      () => _http.post(
        _uri(path),
        headers: _headers(json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> _sendMap(Future<http.Response> Function() request) async {
    final decoded = await _decode(request);
    if (decoded == null) return {};
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('The server returned an unexpected response.');
  }

  Future<List<dynamic>> _sendList(Future<http.Response> Function() request) async {
    final decoded = await _decode(request);
    if (decoded is List) return decoded;
    throw const ApiException('The server returned an unexpected response.');
  }

  Future<Object?> _decode(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } catch (_) {
      throw const ApiException('Cannot reach the salon server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw ApiException(_message(response), statusCode: response.statusCode);
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = _session.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  String _message(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['title'] is String && (decoded['title'] as String).isNotEmpty) {
        return decoded['title'] as String;
      }
    } catch (_) {}

    if (response.statusCode == 401) return 'Sign in is required.';
    if (response.statusCode == 403) return 'You cannot view another branch.';
    return 'The request failed (${response.statusCode}).';
  }
}
