import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/screens/live_portal.dart';

class DirectoryApi extends ApiClient {
  DirectoryApi(this.services);
  final List<dynamic> services;
  @override
  Future<Map<String, dynamic>> getJson(String path) async => {
    'data': {'items': path == '/services' ? services : <dynamic>[]}
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<dynamic> services;
  setUpAll(() async {
    services = jsonDecode(await rootBundle.loadString('assets/data/services.json')) as List<dynamic>;
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Home, service search and wallet fit a $width phone', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: LivePortal(apiClient: DirectoryApi(services))));
      await tester.pumpAndSettle();
      expect(find.text('Make today count'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'summary');
      await tester.pumpAndSettle();
      expect(find.text('Exam Summary'), findsOneWidget);
      expect(find.text('Course Summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('One account. One balance.'), findsOneWidget);
      expect(find.text('₦0.00'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
