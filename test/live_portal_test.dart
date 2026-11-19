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
import 'package:noun_update_student_app/core/green_glass.dart';
import 'package:noun_update_student_app/widgets/native_ui.dart';
import 'package:noun_update_student_app/screens/student_workspace.dart';
import 'package:noun_update_student_app/app/noun_update_app.dart';
import 'package:noun_update_student_app/screens/appearance_settings.dart';
import 'package:noun_update_student_app/screens/live_portal.dart';
import 'package:noun_update_student_app/screens/native_tools.dart';
import 'package:noun_update_student_app/screens/glass_welcome.dart';
import 'package:noun_update_student_app/screens/native_account.dart';
import 'package:noun_update_student_app/screens/native_notifications.dart';
import 'package:noun_update_student_app/screens/native_timetable.dart';

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

class GlassVisualApi extends DirectoryApi{
  GlassVisualApi(super.services);
  @override Future<Map<String,dynamic>> getJson(String path)async{
    if(path.startsWith('/materials?'))return {'data':{'items':[{'id':14,'course_code':'CIT411','title':'Internet Programming'}]}};
    if(path=='/calendar')return {'data':{'events':[
      {'semester':'2026_2','title':'Registration closes','start_at':'2026-11-12','category':'Registration'},
      {'semester':'2026_2','title':'E-Exam begins','start_at':'2026-11-18','category':'Examinations'},
    ]}};
    if(path.startsWith('/timetable?'))return {'data':{
      'current_period':'2026_2','source_period':'2026_2','items':[
        {'course_code':'CIT411','course_title':'Internet Programming','date':'2026-11-26','time':'9:00 AM','exam_type':'POP'},
        {'course_code':'GST302','course_title':'Business Creation and Growth','date':'2026-11-27','time':'11:00 AM','exam_type':'CBT'},
      ],
    }};
    return super.getJson(path);
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
      expect(find.text('YOUR STUDENT DASHBOARD'), findsOneWidget);
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
      await tester.tap(find.text('Updates').last);await tester.pumpAndSettle();
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}updates');
      await tester.tap(find.byTooltip('Notifications').first);await tester.pumpAndSettle();
      expect(find.text('Published updates from NOUN Update'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}notifications');
      expect(tester.takeException(),isNull);
      await tester.pageBack();await tester.pumpAndSettle();
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}profile');
      await tester.scrollUntilVisible(find.text('Sign in'),120,scrollable:find.byType(Scrollable).first);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('One account. One balance.'), findsOneWidget);
      expect(find.text('₦0.00'), findsNothing);
      await tester.ensureVisible(find.text('Sign in'));await tester.tap(find.text('Sign in'));await tester.pumpAndSettle();
      expect(find.text('Welcome back!'),findsOneWidget);
      if(width==390)await capture(tester,captureKey,'${dark?'dark-':''}login');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('My Courses persists and opens a course hub',(tester)async{
    SharedPreferences.setMockInitialValues({});
    final workspace=StudentWorkspace('test-student');await workspace.load();
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildAppTheme(),home:MyCoursesPage(workspace:workspace,openResource:(_,__){}))));
    await tester.enterText(find.byType(TextField),'CIT411');
    await tester.tap(find.text('Add course'));await tester.pumpAndSettle();
    final restored=StudentWorkspace('test-student');await restored.load();expect(restored.courses,['CIT411']);
    await capture(tester,key,'my-courses');
    await tester.tap(find.text('CIT411'));await tester.pumpAndSettle();
    expect(find.text('CIT411 Course Hub'),findsOneWidget);expect(tester.takeException(),isNull);
    await capture(tester,key,'course-hub');await tester.pumpWidget(const SizedBox.shrink());
    workspace.dispose();restored.dispose();
  });
  testWidgets('Green Glass renders native Home, Study Hub and a live-theme service route',(tester)async{
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Appearance.instance.load();
    await Appearance.instance.change(mode:ThemeMode.light);
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key:key,child:NounUpdateApp(
      home:LivePortal(apiClient:DirectoryApi(services),serviceBundle:ServiceBundle(jsonEncode(services))))));
    await tester.runAsync(()=>precacheImage(const AssetImage('assets/images/noun_update_logo.png'),tester.element(find.byType(LivePortal))));
    await tester.pumpAndSettle();
    expect(GreenGlass.of(tester.element(find.byType(LivePortal))),isNotNull);
    await capture(tester,key,'green-glass-home-light');
    await Appearance.instance.change(mode:ThemeMode.dark);
    await tester.pumpAndSettle();
    await capture(tester,key,'green-glass-home-dark');
    await tester.tap(find.text('Mock e-Exam').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byType(NativeUnavailable),findsOneWidget);
    await Appearance.instance.change(mode:ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(NativeUnavailable))).brightness,Brightness.light);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study Hub').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Revision plan'),findsOneWidget);
    await capture(tester,key,'green-glass-study-hub-light');
    await Appearance.instance.change(mode:ThemeMode.dark);
    await tester.pumpAndSettle();
    await capture(tester,key,'green-glass-study-hub-dark');
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Green Glass welcome completes once and persists on relaunch',(tester)async{
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey();
    Widget app()=>RepaintBoundary(key:key,child:MaterialApp(theme:buildGreenGlass(),
      home:const GlassWelcomeGate(home:Scaffold(body:Text('Dashboard ready')))));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.runAsync(()async{
      final context=tester.element(find.byType(GlassWelcomeGate));
      await precacheImage(const AssetImage('assets/images/noun_update_logo.png'),context);
      if(context.mounted)await precacheImage(const AssetImage('assets/images/skins/campus.webp'),context);
    });
    await tester.pumpAndSettle();
    expect(find.text('NOUN Update'),findsOneWidget);
    await capture(tester,key,'green-glass-welcome');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));await tester.pumpAndSettle();
    expect(find.text('All your NOUN study tools'),findsOneWidget);
    await capture(tester,key,'green-glass-onboarding');
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));await tester.pumpAndSettle();
    expect(find.text('Dashboard ready'),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
    await tester.pumpWidget(app());await tester.pumpAndSettle();
    expect(find.text('Dashboard ready'),findsOneWidget);
  });
  for(final (width,scaling) in [(390.0,1.0),(320.0,1.5)]){
    testWidgets('Green Glass inner routes fit at $width with $scaling text',(tester)async{
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize=Size(width,844);tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      final workspace=StudentWorkspace('glass-test',api:GlassVisualApi(services))
        ..courses=['CIT411','GST302']
        ..details={'Programme':'BSc Computer Science','Faculty':'Faculty of Computing'};
      addTearDown(workspace.dispose);
      final key=GlobalKey();
      Future<void> render(Widget screen,String name)async{
        final host=RepaintBoundary(key:key,child:MaterialApp(theme:buildGreenGlass(),darkTheme:buildGreenGlass(brightness:Brightness.dark),
          themeMode:ThemeMode.light,builder:(context,child)=>MediaQuery(
            data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scaling)),child:child!),home:screen));
        await tester.pumpWidget(host);await tester.pumpAndSettle();
        expect(tester.takeException(),isNull,reason:name);
        if(width==390)await capture(tester,key,'green-glass-$name-light');
        await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(
          theme:buildGreenGlass(brightness:Brightness.dark),builder:(context,child)=>MediaQuery(
            data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scaling)),child:child!),home:screen)));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull,reason:'$name dark');
        if(width==390)await capture(tester,key,'green-glass-$name-dark');
        await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
      }
      await render(NativeAuth(workspace.api),'login');
      await render(MyCoursesPage(workspace:workspace,openResource:(_,__){}),'registered');
      await render(GlassCourseOverview(api:workspace.api,code:'CIT411',programme:workspace.details['Programme'],
        faculty:workspace.details['Faculty'],openResource:(_,__){}),'course-overview');
      await render(NativeTimetable(api:workspace.api,courses:workspace.courses,onManageCourses:(){}),'timetable');
      await render(NativeCalendar(workspace.api),'calendar');
      await render(NuPage(title:'Notifications',child:NativeNotifications(api:workspace.api,onArticle:(_){})),'inbox');
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
    await tester.scrollUntilVisible(find.text('Classic serif'),150,scrollable:find.byType(Scrollable).first);await Scrollable.ensureVisible(tester.element(find.text('Classic serif')),alignment:0.5);await tester.pumpAndSettle();await tester.tap(find.text('Classic serif').hitTestable());await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AppearanceSettings))).textTheme.bodyMedium?.fontFamily,'NUReading');
    final restored=Appearance();await restored.load();expect(restored.mode,ThemeMode.dark);expect(restored.font,'Classic serif');expect(find.text('Accent colour'),findsNothing);restored.dispose();
    await tester.drag(find.byType(ListView).first,const Offset(0,1000));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);await capture(tester,key,'settings-dark-serif');
    await Appearance.instance.change(mode:ThemeMode.light,font:'Modern sans',accent:'Emerald');await tester.pumpAndSettle();
    await capture(tester,key,'settings-light');
    await Appearance.instance.change(textSize:'Extra Large');await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    await Appearance.instance.change(textSize:'Default');await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Course layout and signed-in wallet render with fixture data',(tester)async{
    FlutterSecureStorage.setMockInitialValues({'noun_central_access_token':'fixture-token'});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey(),api=DirectoryApi(services,signedIn:true);
    await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildAppTheme(),home:LivePortal(apiClient:api,serviceBundle:ServiceBundle(jsonEncode(services))))));
    await tester.pumpAndSettle();await tester.tap(find.text('Profile').last);await tester.pumpAndSettle();
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

