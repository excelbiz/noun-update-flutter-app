import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/notification_preferences.dart';

class _NotificationSessionStore extends SessionStore {
  const _NotificationSessionStore();

  @override
  Future<String?> readAccessToken() async => 'd' * 64;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<void> clear() async {}
}

ApiClient _api(http.Client client) => ApiClient(
      client: client,
      sessionStore: const _NotificationSessionStore(),
    );

http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _settings({
  bool enabled = true,
  bool tmas = true,
  bool exams = true,
  bool results = true,
  bool fees = true,
  bool general = true,
}) => {
      'automatic': true,
      'mode': 'system',
      'text_size': 'Default',
      'font': 'Modern sans',
      'accent': 'Emerald',
      'data_saver': false,
      'notifications_enabled': enabled,
      'notify_tmas': tmas,
      'notify_exams': exams,
      'notify_results': results,
      'notify_fees': fees,
      'notify_general': general,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notification categories restore from signed-in account', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.queryParameters['route'], '/profile/settings');
      return _json({'data': {
        'exists': true,
        'settings': _settings(tmas: false, fees: false, general: false),
      }});
    });
    final prefs = NotificationPreferences(api: _api(client), userId: '42');
    await prefs.load();

    expect(prefs.tmas, isFalse);
    expect(prefs.exams, isTrue);
    expect(prefs.results, isTrue);
    expect(prefs.fees, isFalse);
    expect(prefs.general, isFalse);
    expect(prefs.syncPending, isFalse);
    prefs.dispose();
  });

  test('offline category change is retained and marked pending', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async => throw Exception('offline'));
    final prefs = NotificationPreferences(api: _api(client), userId: '77');

    await expectLater(prefs.change(tmas: false, exams: false), throwsA(isA<Exception>()));

    expect(prefs.tmas, isFalse);
    expect(prefs.exams, isFalse);
    expect(prefs.syncPending, isTrue);
    final local = jsonDecode((await SharedPreferences.getInstance()).getString('nu-notification-preferences-77')!) as Map<String, dynamic>;
    expect(local['notify_tmas'], isFalse);
    expect(local['sync_pending'], isTrue);
    prefs.dispose();
  });

  test('pending notification choices win over older server copy on reconnect', () async {
    SharedPreferences.setMockInitialValues({
      'nu-notification-preferences-91': jsonEncode({
        ..._settings(tmas: false, results: false),
        'sync_pending': true,
      }),
    });
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json({'data': {'exists': true, 'settings': _settings()}});
      }
      posts++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final patch = Map<String, dynamic>.from(body['settings'] as Map);
      expect(patch['notify_tmas'], isFalse);
      expect(patch['notify_results'], isFalse);
      return _json({'data': {
        'exists': true,
        'settings': {..._settings(), ...patch},
      }});
    });
    final prefs = NotificationPreferences(api: _api(client), userId: '91');
    await prefs.load();

    expect(posts, 1);
    expect(prefs.tmas, isFalse);
    expect(prefs.results, isFalse);
    expect(prefs.syncPending, isFalse);
    prefs.dispose();
  });

  test('guest notification choices never call the account API', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return _json({'data': {}});
    });
    final prefs = NotificationPreferences(api: _api(client), userId: null);
    await prefs.load();
    await prefs.change(general: false);

    expect(calls, 0);
    expect(prefs.general, isFalse);
    expect(prefs.syncPending, isFalse);
    prefs.dispose();
  });
}
