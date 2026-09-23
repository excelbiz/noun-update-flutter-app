import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noun_update_student_app/core/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Central identity routes cannot use legacy wallet or leak its token', () async {
    FlutterSecureStorage.setMockInitialValues({'noun_central_access_token':'central-token','noun_access_token':'legacy-token'});
    final requests=<http.Request>[];
    final api=ApiClient(client:MockClient((r) async {
      requests.add(r);
      return http.Response(jsonEncode({'data':{}}),200);
    }));
    await api.getJson('/app/bootstrap');
    await api.postJson('/wallet/fund',{'amount_kobo':10000},idempotencyKey:'example');
    await api.getJson('/posts/news');
    expect(requests[0].url.path,'/api/central/index.php');
    expect(requests[0].url.queryParameters['route'],'/app/bootstrap');
    expect(requests[0].headers['Authorization'],'Bearer central-token');
    expect(requests[1].url.queryParameters['route'],'/wallet/fund');
    expect(requests[1].headers['Idempotency-Key'],'example');
    expect(requests[2].url.path,'/api/v1/posts/news');
    expect(requests[2].headers.containsKey('Authorization'),isFalse);
  });
}
