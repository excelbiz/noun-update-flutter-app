import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/study_state_store.dart';

class _StudySessionStore extends SessionStore {
  const _StudySessionStore();

  @override
  Future<String?> readAccessToken() async => 'b' * 64;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<void> clear() async {}
}

ApiClient _api(http.Client client) => ApiClient(
      client: client,
      sessionStore: const _StudySessionStore(),
    );

http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pending local Study edit syncs using its server revision', () async {
    SharedPreferences.setMockInitialValues({
      'nu-study-42-CIT411': jsonEncode({
        'done': [0, 2],
        'notes': 'Offline note',
        'revision': 3,
        'dirty': true,
      }),
    });
    var posts = 0;
    final client = MockClient((request) async {
      expect(request.url.path, '/api/central/index.php');
      expect(request.url.queryParameters['route'], '/study/CIT411/state');
      if (request.method == 'GET') {
        return _json({'data': {'done': [0], 'notes': 'Offline note', 'revision': 3}});
      }
      posts++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['base_revision'], 3);
      expect(body['done'], [0, 2]);
      return _json({'data': {'done': [0, 2], 'notes': 'Offline note', 'revision': 4}});
    });

    final store = StudyStateStore(api: _api(client), courseCode: 'CIT411', userId: '42');
    await store.load();

    expect(posts, 1);
    expect(store.revision, 4);
    expect(store.syncPending, isFalse);
    expect(store.done, containsAll(<int>{0, 2}));
  });

  test('different non-empty notes on a newer device are never overwritten silently', () async {
    SharedPreferences.setMockInitialValues({
      'nu-study-77-BIO301': jsonEncode({
        'done': [0, 1],
        'notes': 'My offline explanation',
        'revision': 2,
        'dirty': true,
      }),
    });
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') posts++;
      return _json({'data': {
        'done': [0, 2],
        'notes': 'Notes from my other phone',
        'revision': 4,
      }});
    });

    final store = StudyStateStore(api: _api(client), courseCode: 'BIO301', userId: '77');
    await store.load();

    expect(posts, 0);
    expect(store.hasConflict, isTrue);
    expect(store.notes, 'My offline explanation');
    expect(store.conflictNotes, 'Notes from my other phone');
    expect(store.done, containsAll(<int>{0, 1, 2}));
    expect(store.revision, 4);
    expect(store.syncPending, isTrue);
  });

  test('network failure keeps signed-in Study changes queued on device', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async => throw Exception('offline'));
    final store = StudyStateStore(api: _api(client), courseCode: 'GST302', userId: '91');

    await store.save(<int>{1, 3}, 'Read this again before the exam');

    expect(store.syncPending, isTrue);
    final prefs = await SharedPreferences.getInstance();
    final cached = jsonDecode(prefs.getString('nu-study-91-GST302')!) as Map<String, dynamic>;
    expect(cached['dirty'], isTrue);
    expect(cached['notes'], 'Read this again before the exam');
    expect(cached['done'], [1, 3]);
  });

  test('guest Study state is device-only and never becomes pending', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return _json({'data': {}});
    });
    final store = StudyStateStore(api: _api(client), courseCode: 'GST302');

    await store.save(<int>{0}, 'Guest note');
    await store.load();

    expect(calls, 0);
    expect(store.done, {0});
    expect(store.notes, 'Guest note');
    expect(store.syncPending, isFalse);
  });
}
