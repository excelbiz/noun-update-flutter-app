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
  static const _accessTokenKey = 'noun_central_access_token';
  static const _refreshTokenKey = 'noun_central_refresh_token';

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
  int _sessionGeneration=0;
  int get sessionGeneration=>_sessionGeneration;
  Future<void> _sessionWrites=Future<void>.value();
  Future<void> _writeSession(Future<void> Function() action){
    final next=_sessionWrites.catchError((Object _){}).then((_)=>action());
    _sessionWrites=next;return next;
  }

  Future<bool> hasSession() async {
    final token = await _sessionStore.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession(){
    _sessionGeneration++;
    return _writeSession(_sessionStore.clear);
  }
  Future<void> saveSession({required String accessToken,required String refreshToken}){
    _sessionGeneration++;
    return _writeSession(()=>_sessionStore.saveTokens(accessToken:accessToken,refreshToken:refreshToken));
  }
  /// Device sign-out is always possible, including after expiry or lost connectivity.
  Future<bool> signOut()async{
    bool revoked=false;
    try{await postJson('/auth/logout',{});revoked=true;}catch(_){/* Do not trap a student in an expired session. */}
    finally{await clearSession();}
    return revoked;
  }

  Future<bool> _refresh() async {
    final generation=_sessionGeneration;
    final token = await _sessionStore.readRefreshToken();
    if (token == null || token.isEmpty || generation!=_sessionGeneration) return false;
    final response = await _client.post(_uri('/auth/refresh'),
      headers: await _headers('/auth/refresh'), body: jsonEncode({'refresh_token': token}))
      .timeout(const Duration(seconds: 20));
    bool refreshed=false;
    if(response.statusCode==401){
      await _writeSession(()async{
        if(generation==_sessionGeneration && await _sessionStore.readRefreshToken()==token){
          _sessionGeneration++;await _sessionStore.clear();
        }
      });
      return false;
    }
    final data = _decode(response)['data'];
    if(data is! Map || data['access_token'] is! String || data['refresh_token'] is! String ||
       (data['access_token'] as String).isEmpty || (data['refresh_token'] as String).isEmpty){
      throw const ApiException('Session renewal returned an invalid response. Please try again.');
    }
    await _writeSession(()async{
      if(generation!=_sessionGeneration || await _sessionStore.readRefreshToken()!=token)return;
      await _sessionStore.saveTokens(accessToken:data['access_token'] as String,refreshToken:data['refresh_token'] as String);
      refreshed=true;
    });
    return refreshed;
  }

  Future<bool> _refreshOnce() async {
    if (_refreshing != null) return _refreshing!;
    _refreshing = _refresh();
    try { return await _refreshing!; } finally { _refreshing = null; }
  }

  bool _central(String path) => path.startsWith('/premium/') || path.startsWith('/motivation/') || path.startsWith('/auth/') || path.startsWith('/wallet') || path == '/app/bootstrap' || path == '/workspace' || path == '/saved-resources' || path.startsWith('/profile') || path.startsWith('/course-summary') || path.startsWith('/orders') || path.contains('/state') || (path.startsWith('/exam-summaries/') && !path.endsWith('/pdf'));

  Uri _uri(String path) {
    if (!_central(path)) return Uri.parse('${AppConfig.apiBaseUrl}$path');
    final route = Uri.parse(path);
    return Uri.parse(AppConfig.apiBaseUrl).replace(path: '/api/central/index.php', queryParameters: {...route.queryParameters, 'route': route.path});
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final generation=_sessionGeneration;
    var response = await _client
        .get(_uri(path), headers: await _headers(path))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 401 && _central(path) && generation==_sessionGeneration && await _refreshOnce()) {
      if(generation!=_sessionGeneration)throw const ApiException('Your session changed. Reopen this page.',statusCode:401,code:'SESSION_CHANGED');
      response = await _client.get(_uri(path), headers: await _headers(path)).timeout(const Duration(seconds: 20));
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final generation=_sessionGeneration;
    final headers = await _headers(path);
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    var response = await _client
        .post(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: path.startsWith('/course-summary') ? 300 : 60));
    if (response.statusCode == 401 && _central(path) && !path.startsWith('/auth/') && generation==_sessionGeneration && await _refreshOnce()) {
      if(generation!=_sessionGeneration)throw const ApiException('Your session changed. Reopen this page.',statusCode:401,code:'SESSION_CHANGED');
      final retryHeaders = await _headers(path);
      if (idempotencyKey != null) retryHeaders['Idempotency-Key'] = idempotencyKey;
      response = await _client.post(_uri(path), headers: retryHeaders,
        body: jsonEncode(body)).timeout(Duration(seconds: path.startsWith('/course-summary') ? 300 : 60));
    }
    return _decode(response);
  }

  Future<Uint8List> getPdf(String path) async {
    final base=Uri.parse(AppConfig.apiBaseUrl);
    final uri=path.startsWith('https://')?Uri.parse(path):_uri(path);
    if(uri.origin!=base.origin||!uri.path.startsWith('${base.path}/'))throw const ApiException('Invalid document location.');
    final request=http.Request('GET',uri)..followRedirects=false;
    request.headers.addAll(await _headers(path));
    final response=await _client.send(request).timeout(const Duration(seconds:45));
    if(response.statusCode!=200)throw const ApiException('Unable to load this document. Reopen your purchase and try again.');
    final bytes=BytesBuilder();
    await for(final part in response.stream.timeout(const Duration(seconds:45))){bytes.add(part);if(bytes.length>50000000)throw const ApiException('This document is too large to open on this device.');}
    final data=bytes.takeBytes();
    if(data.length<5||ascii.decode(data.sublist(0,5),allowInvalid:true)!='%PDF-')throw const ApiException('This resource is not a readable PDF.');
    return data;
  }

  Future<Map<String, String>> _headers(String path) async {
    final token = await _sessionStore.readAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'NOUNUpdateMobile/central-v1',
      'X-App-Platform': 'flutter',
      'X-App-Version': '0.9.7',
      if (_central(path) && token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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
