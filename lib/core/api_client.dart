import 'dart:convert';
import 'dart:typed_data';

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
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

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
  Future<bool>? _refreshing;

  Future<bool> _refresh() async {
    final token = await _sessionStore.readRefreshToken();
    if (token == null) return false;
    final response = await _client.post(Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': token}))
      .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) { await _sessionStore.clear(); return false; }
    final data = _decode(response)['data'] as Map<String, dynamic>;
    await _sessionStore.saveTokens(accessToken: data['access_token'] as String, refreshToken: data['refresh_token'] as String);
    return true;
  }

  Future<bool> _refreshOnce() async {
    if (_refreshing != null) return _refreshing!;
    _refreshing = _refresh();
    try { return await _refreshing!; } finally { _refreshing = null; }
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    var response = await _client
        .get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 401 && await _refreshOnce()) {
      response = await _client.get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: await _headers()).timeout(const Duration(seconds: 20));
    }
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
    var response = await _client
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: path.startsWith('/course-summary') ? 300 : 60));
    if (response.statusCode == 401 && !path.startsWith('/auth/') && await _refreshOnce()) {
      final retryHeaders = await _headers();
      if (idempotencyKey != null) retryHeaders['Idempotency-Key'] = idempotencyKey;
      response = await _client.post(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: retryHeaders,
        body: jsonEncode(body)).timeout(Duration(seconds: path.startsWith('/course-summary') ? 300 : 60));
    }
    return _decode(response);
  }

  Future<Uint8List> getPdf(String path) async {
    final base=Uri.parse(AppConfig.apiBaseUrl);
    final uri=path.startsWith('https://')?Uri.parse(path):Uri.parse('${AppConfig.apiBaseUrl}$path');
    if(uri.origin!=base.origin||!uri.path.startsWith('${base.path}/'))throw const ApiException('Invalid document location.');
    final request=http.Request('GET',uri)..followRedirects=false;
    request.headers.addAll(await _headers());
    final response=await _client.send(request).timeout(const Duration(seconds:45));
    if(response.statusCode!=200)throw const ApiException('Unable to load this document. Reopen your purchase and try again.');
    final bytes=BytesBuilder();
    await for(final part in response.stream.timeout(const Duration(seconds:45))){bytes.add(part);if(bytes.length>50000000)throw const ApiException('This document is too large to open on this device.');}
    final data=bytes.takeBytes();
    if(data.length<5||ascii.decode(data.sublist(0,5),allowInvalid:true)!='%PDF-')throw const ApiException('This resource is not a readable PDF.');
    return data;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _sessionStore.readAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-App-Platform': 'flutter',
      'X-App-Version': '0.4.0',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      throw ApiException(
        'NOUN Update is temporarily unavailable. Please try again shortly.',
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
