import 'dart:async';
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
  final directoryReady = Completer<void>();
  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path == '/services' && !directoryReady.isCompleted) directoryReady.complete();
    return {'data': {'items': path == '/services' ? services : <dynamic>[]}};
  }
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
      final api = DirectoryApi(services);
      await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: LivePortal(apiClient: api)));
      // Asset I/O completes outside the widget test's fake clock.
      await tester.runAsync(() => api.directoryReady.future.timeout(const Duration(seconds: 10)));
      await tester.pumpAndSettle();
      expect(find.text('Make today count'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'summary');
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      if (find.text('Exam Summary').evaluate().isEmpty) {
        debugPrint('Directory rows: ${services.length}');
        debugPrint('Visible text: ${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).toList()}');
      }
      await tester.scrollUntilVisible(find.text('Exam Summary'), 150, scrollable: find.byType(Scrollable).first);
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
