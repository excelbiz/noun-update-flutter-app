import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/appearance.dart';

class _AppearanceSessionStore extends SessionStore {
  const _AppearanceSessionStore({this.signedIn = true});
  final bool signedIn;

  @override
  Future<String?> readAccessToken() async => signedIn ? 'c' * 64 : null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<void> clear() async {}
}

ApiClient _api(http.Client client, {bool signedIn = true}) => ApiClient(
      client: client,
      sessionStore: _AppearanceSessionStore(signedIn: signedIn),
    );

http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('existing server appearance restores on another signed-in device', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/central/index.php');
      expect(request.url.queryParameters['route'], '/profile/settings');
      return _json({'data': {
        'exists': true,
        'settings': {
          'automatic': false,
          'mode': 'dark',
          'text_size': 'Extra Large',
          'font': 'Classic serif',
          'accent': 'Plum',
          'data_saver': true,
        }
      }});
    });
    final appearance = Appearance();
    await appearance.load();
    await appearance.sync(_api(client));

    expect(appearance.automatic, isFalse);
    expect(appearance.mode, ThemeMode.dark);
    expect(appearance.textSize, 'Extra Large');
    expect(appearance.font, 'Classic serif');
    expect(appearance.accent, 'Plum');
    expect(appearance.dataSaver, isTrue);
    expect(appearance.accountSyncPending, isFalse);
    appearance.dispose();
  });

  test('first signed-in sync seeds server from existing local appearance', () async {
    SharedPreferences.setMockInitialValues({
      Appearance.storageKey: jsonEncode({
        'automatic': false,
        'mode': 'light',
        'textSize': 'Large',
        'font': 'Device font',
        'accent': 'Terracotta',
        'dataSaver': true,
      }),
    });
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json({'data': {
          'exists': false,
          'settings': {
            'automatic': true,
            'mode': 'system',
            'text_size': 'Default',
            'font': 'Modern sans',
            'accent': 'Emerald',
            'data_saver': false,
          }
        }});
      }
      posts++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final settings = Map<String, dynamic>.from(body['settings'] as Map);
      expect(settings['mode'], 'light');
      expect(settings['text_size'], 'Large');
      expect(settings['font'], 'Device font');
      expect(settings['accent'], 'Terracotta');
      expect(settings['data_saver'], isTrue);
      return _json({'data': {'exists': true, 'settings': settings}});
    });
    final appearance = Appearance();
    await appearance.load();
    await appearance.sync(_api(client));

    expect(posts, 1);
    expect(appearance.mode, ThemeMode.light);
    expect(appearance.accountSyncPending, isFalse);
    appearance.dispose();
  });

  test('failed authenticated change remains local and pending', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async => throw Exception('offline'));
    final appearance = Appearance();
    await appearance.load();

    await expectLater(
      appearance.change(
        mode: ThemeMode.dark,
        textSize: 'Large',
        dataSaver: true,
        api: _api(client),
      ),
      throwsA(isA<Exception>()),
    );

    expect(appearance.mode, ThemeMode.dark);
    expect(appearance.textSize, 'Large');
    expect(appearance.dataSaver, isTrue);
    expect(appearance.accountSyncPending, isTrue);
    final cached = jsonDecode((await SharedPreferences.getInstance()).getString(Appearance.storageKey)!) as Map<String, dynamic>;
    expect(cached['accountSyncPending'], isTrue);
    expect(cached['dataSaver'], isTrue);
    appearance.dispose();
  });

  test('next sync pushes pending local settings before accepting older server copy', () async {
    SharedPreferences.setMockInitialValues({
      Appearance.storageKey: jsonEncode({
        'automatic': false,
        'mode': 'dark',
        'textSize': 'Large',
        'font': 'Classic serif',
        'accent': 'Ocean',
        'dataSaver': true,
        'accountSyncPending': true,
      }),
    });
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json({'data': {
          'exists': true,
          'settings': {
            'automatic': true,
            'mode': 'system',
            'text_size': 'Default',
            'font': 'Modern sans',
            'accent': 'Emerald',
            'data_saver': false,
          }
        }});
      }
      posts++;
      final settings = Map<String, dynamic>.from((jsonDecode(request.body) as Map)['settings'] as Map);
      expect(settings['mode'], 'dark');
      expect(settings['text_size'], 'Large');
      expect(settings['data_saver'], isTrue);
      return _json({'data': {'exists': true, 'settings': settings}});
    });
    final appearance = Appearance();
    await appearance.load();
    await appearance.sync(_api(client));

    expect(posts, 1);
    expect(appearance.mode, ThemeMode.dark);
    expect(appearance.textSize, 'Large');
    expect(appearance.dataSaver, isTrue);
    expect(appearance.accountSyncPending, isFalse);
    appearance.dispose();
  });

  test('guest appearance remains device-local', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return _json({'data': {}});
    });
    final appearance = Appearance();
    await appearance.load();
    await appearance.change(accent: 'Ocean', api: _api(client, signedIn: false));
    await appearance.sync(_api(client, signedIn: false));

    expect(calls, 0);
    expect(appearance.accent, 'Ocean');
    expect(appearance.accountSyncPending, isFalse);
    appearance.dispose();
  });
}
