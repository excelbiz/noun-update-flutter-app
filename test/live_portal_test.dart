import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
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
  Future<Map<String, dynamic>> getJson(String path) async {
    return {'data': {'items': path == '/services' ? services : <dynamic>[]}};
  }
}

class ServiceBundle extends CachingAssetBundle {
  ServiceBundle(this.json);
  final String json;
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(key, 'assets/data/services.json');
    return json;
  }
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<dynamic> services;
  setUpAll(() async {
    services = jsonDecode(File('assets/data/services.json').readAsStringSync()) as List<dynamic>;
    final font = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    if(font.existsSync()){final loader=FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));await loader.load();}
  });
  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('Native navigation and summaries fit a $width phone', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = DirectoryApi(services);
      final captureKey=GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key:captureKey,child:MaterialApp(theme: buildAppTheme(), home: LivePortal(apiClient: api, serviceBundle: ServiceBundle(jsonEncode(services))))));
      await tester.pumpAndSettle();
      expect(find.text('Quick access'), findsOneWidget);
      if(width==390)await capture(tester,captureKey,'home');
      await tester.tap(find.text('Study').last);await tester.pumpAndSettle();
      expect(find.text('Study smarter'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'study');
      expect(tester.takeException(),isNull);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tools').last);
      await tester.pumpAndSettle();
      if(width==390)await capture(tester,captureKey,'tools');
      await tester.enterText(find.byType(TextField), 'summary');
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Exam Summary'), 150, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Exam Summary'), findsOneWidget);
      expect(find.text('Course Summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Notifications'));await tester.pumpAndSettle();
      expect(find.text('Published updates from NOUN Update'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'notifications');
      expect(tester.takeException(),isNull);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('One account. One balance.'), findsOneWidget);
      expect(find.text('₦0.00'), findsNothing);
      if(width==390)await capture(tester,captureKey,'profile');
      await tester.tap(find.text('Sign in'));await tester.pumpAndSettle();
      expect(find.text('Welcome back!'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'login');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> capture(WidgetTester tester,GlobalKey key,String name) async {
 await tester.runAsync(()async{
  final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image=await boundary.toImage(pixelRatio:2);
  final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
  Directory('screenshots').createSync(recursive:true);
  File('screenshots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();
 });
}
