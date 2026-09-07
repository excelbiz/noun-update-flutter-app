import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class SessionStore {
  const SessionStore();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'noun_access_token';
  static const _refreshTokenKey = 'noun_refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clear() => _storage.deleteAll();
}

class ApiClient {
  ApiClient({
    http.Client? client,
    SessionStore? sessionStore,
  })  : _client = client ?? http.Client(),
        _sessionStore = sessionStore ?? const SessionStore();

  final http.Client _client;
  final SessionStore _sessionStore;

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client
        .get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final headers = await _headers();
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    final response = await _client
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _sessionStore.readAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-App-Platform': 'flutter',
      'X-App-Version': '0.1.0',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      throw ApiException(
        'The server returned an unreadable response.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final errorMap = error is Map<String, dynamic> ? error : null;
      throw ApiException(
        errorMap?['message'] as String? ?? 'Request failed. Please try again.',
        statusCode: response.statusCode,
        code: errorMap?['code'] as String?,
      );
    }
    return payload;
  }
}
