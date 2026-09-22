import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/core/appearance.dart';
import 'package:noun_update_student_app/app/noun_update_app.dart';
import 'package:noun_update_student_app/screens/appearance_settings.dart';
import 'package:noun_update_student_app/screens/live_portal.dart';
import 'package:noun_update_student_app/screens/native_tools.dart';

class DirectoryApi extends ApiClient {
  DirectoryApi(this.services,{this.signedIn=false});
  final bool signedIn;
  final List<dynamic> services;
  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if(path=='/app/bootstrap')return {'data':{'profile':signedIn?{'id':'12','name':'Preview Student','email':'student@example.test'}:null,'wallet':signedIn?{'balance_kobo':525000,'transactions':[]}:null}};
    if(path=='/study/GST302')return {'data':{'sections':[
      for(var i=0;i<5;i++){'index':i,'module_title':'Module ${i+1}','unit_title':['Introduction to Entrepreneurship','Opportunity Identification','Business Planning','Financing New Ventures','Venture Growth and Sustainability'][i],'source_text':'Preview course content used only by the widget test fixture.'}
    ]}};
    if(path=='/posts/news')return {'data':{'items':[
      {'id':1,'category':'news','title':'TMA study reminder','excerpt':'Plan time to review your course material before assessment.','published_at':DateTime.now().toIso8601String()},
      {'id':2,'category':'news','title':'Examination preparation guide','excerpt':'Organise your revision and check your academic calendar.','published_at':DateTime.now().subtract(const Duration(days:2)).toIso8601String()},
      {'id':3,'category':'news','title':'General student update','excerpt':'Find study materials and revision resources in the app.','published_at':DateTime.now().subtract(const Duration(days:9)).toIso8601String()},
    ]}};
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
    if(font.existsSync()){for(final family in ['sans-serif','Roboto']){final loader=FontLoader(family)..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));await loader.load();}}
    for(final f in [('NUSans','NUSans-Regular.ttf'),('NUReading','NUReading.ttf')]){await (FontLoader(f.$1)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${f.$2}').readAsBytesSync())))).load();}
    final icons=File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if(!icons.existsSync())throw StateError('Material icon font missing from preview environment');
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
  });
  for (final scenario in [(320.0,1.0,false),(390.0,1.0,false),(430.0,1.0,false),(320.0,1.5,false),(390.0,1.0,true),(320.0,1.5,true)]) {
    final width=scenario.$1,scale=scenario.$2;final dark=scenario.$3;
    testWidgets('Native navigation and summaries fit a $width phone at text scale $scale dark=$dark', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = DirectoryApi(services);
      final captureKey=GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key:captureKey,child:MaterialApp(debugShowCheckedModeBanner:false,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),theme: buildAppTheme(brightness:dark?Brightness.dark:Brightness.light,fontFamily:dark&&width==320?'NUReading':width==430?null:'NUSans'), home: LivePortal(apiClient: api, serviceBundle: ServiceBundle(jsonEncode(services))))));
      await tester.runAsync(()async{for(final path in ['assets/images/noun_update_logo.png','assets/images/student-hero.webp']){await precacheImage(AssetImage(path),tester.element(find.byType(LivePortal)));}});
      await tester.pumpAndSettle();
      if(scale>1)await tester.scrollUntilVisible(find.text('Quick access'),150,scrollable:find.byType(Scrollable).first);
      expect(find.text('Quick access'), findsOneWidget);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}home');
      await tester.tap(find.text('Study').last);await tester.pumpAndSettle();
      expect(find.text('Study smarter'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}study');
      expect(tester.takeException(),isNull);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tools').last);
      await tester.pumpAndSettle();
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}tools');
      await tester.enterText(find.byType(TextField), 'summary');
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Exam Summary'), 150, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Exam Summary'), findsOneWidget);
      expect(find.text('Course Summary'), findsOneWidget);
      await tester.tap(find.text('Exam Summary'));await tester.pumpAndSettle();
      expect(find.text('Open central wallet'),findsOneWidget);
      await tester.tap(find.text('Open central wallet'));await tester.pumpAndSettle();
      expect(find.text('One account. One balance.'),findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Notifications'));await tester.pumpAndSettle();
      expect(find.text('Published updates from NOUN Update'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}notifications');
      expect(tester.takeException(),isNull);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('One account. One balance.'), findsOneWidget);
      expect(find.text('₦0.00'), findsNothing);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}profile');
      await tester.tap(find.text('Sign in'));await tester.pumpAndSettle();
      expect(find.text('Welcome back!'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}login');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('Appearance applies immediately and survives a reload',(tester)async{
    SharedPreferences.setMockInitialValues({});await Appearance.instance.load();
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key:key,child:NounUpdateApp(home:AppearanceSettings(api:DirectoryApi(services)))));await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mode-dark')));await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AppearanceSettings))).brightness,Brightness.dark);
    await tester.ensureVisible(find.text('Classic serif'));await tester.tap(find.text('Classic serif'));await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AppearanceSettings))).textTheme.bodyMedium?.fontFamily,'NUReading');
    await tester.ensureVisible(find.text('Ocean'));await tester.tap(find.text('Ocean'));await tester.pumpAndSettle();
    final restored=Appearance();await restored.load();expect(restored.mode,ThemeMode.dark);expect(restored.font,'Classic serif');expect(restored.accent,'Ocean');restored.dispose();
    await tester.drag(find.byType(ListView).first,const Offset(0,1000));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);await capture(tester,key,'settings-dark-serif');
    await Appearance.instance.change(mode:ThemeMode.light,font:'Modern sans',accent:'Emerald');await tester.pumpAndSettle();
    await capture(tester,key,'settings-light');await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Course layout and signed-in wallet render with fixture data',(tester)async{
    FlutterSecureStorage.setMockInitialValues({'noun_access_token':'fixture-token'});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey(),api=DirectoryApi(services,signedIn:true);
    await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildAppTheme(),home:LivePortal(apiClient:api,serviceBundle:ServiceBundle(jsonEncode(services))))));
    await tester.pumpAndSettle();await tester.tap(find.text('Profile'));await tester.pumpAndSettle();
    expect(find.text('₦5250.00'),findsOneWidget);expect(tester.takeException(),isNull);
    await capture(tester,key,'wallet');
    await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildAppTheme(),home:NativeStudy(api:api,row:const {'id':1,'course_code':'GST302','title':'Entrepreneurship'}))));
    await tester.pumpAndSettle();expect(find.text('Introduction to Entrepreneurship'),findsOneWidget);
    expect(tester.takeException(),isNull);await capture(tester,key,'study-course');
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
