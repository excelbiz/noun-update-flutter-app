import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/premium_service.dart';
import 'package:noun_update_student_app/core/skin_theme.dart';
import 'package:noun_update_student_app/screens/live_portal.dart';
import 'package:noun_update_student_app/screens/native_account.dart';
import 'package:noun_update_student_app/screens/skin_gallery.dart';
import 'live_portal_test.dart' show capture;

class EditorialReviewApi extends ApiClient {
  final writes = <String>[];
  @override Future<Map<String,dynamic>> getJson(String path) async {
    if(path=='/services')return {'data':{'items':jsonDecode(await rootBundle.loadString('assets/data/services.json'))}};
    if(path=='/study/CIT321/state')return {'data':{'done':[for(var i=0;i<13;i++)i]}};
    if(path=='/study/CIT321')return {'data':{'course_title':'Computer Systems and Networks','sections':[for(var i=0;i<20;i++){'index':i}]}};
    if(path=='/motivation/today')return {'data':{'quote':{'id':0,'quote':'Discipline today creates the freedom you want tomorrow.','author':'NOUN UPDATE','date':DateTime.now().toUtc().add(const Duration(hours:1)).toIso8601String().substring(0,10)}}};
    if(path.startsWith('/posts/'))return {'data':{'items':[{'id':0,'category':'news','title':'Examination Timetable Now Available','published_at':DateTime.now().toIso8601String()}]}};
    return {'data':{'items':[]}};
  }
  @override Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey})async{writes.add(path);throw const ApiException('Review fixture is read-only.');}
}

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{
   await rootBundle.loadString('assets/data/services.json');
   for(final f in [('NUSans','NUSans-Regular.ttf'),('NUReading','NUReading.ttf')]){await (FontLoader(f.$1)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${f.$2}').readAsBytesSync())))).load();}
   final icons=File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
   await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
 });
 for(final scenario in [(390.0,844.0,1.0,false),(390.0,1040.0,1.0,false),(390.0,844.0,1.0,true),(320.0,844.0,1.0,false),(390.0,844.0,1.25,false),(320.0,844.0,1.5,false),(320.0,844.0,1.5,true)]){
  testWidgets('Elegant Editorial real layouts ${scenario.$1}x${scenario.$2} scale ${scenario.$3} dark ${scenario.$4}',(tester)async{
   SharedPreferences.setMockInitialValues({});PremiumService.instance.clear();addTearDown(PremiumService.instance.clear);
   tester.view.physicalSize=Size(scenario.$1,scenario.$2);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   final api=EditorialReviewApi(),key=GlobalKey();
   final theme=buildSkinTheme(AppSkin.elegantEditorial,brightness:scenario.$4?Brightness.dark:Brightness.light);
   Widget wrap(Widget child)=>RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:theme,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scenario.$3)),child:child!),home:child));
   await tester.pumpWidget(wrap(LivePortal(apiClient:api,preview:true,previewData:editorialPreviewData())));
   await tester.runAsync(()=>precacheImage(const AssetImage('assets/images/skins/editorial-emblem.webp'),tester.element(find.byType(LivePortal))));await tester.pumpAndSettle();
   expect(find.text('CIT321'),findsWidgets);expect(find.text('65% complete'),findsOneWidget);expect(tester.takeException(),isNull);
   final suffix='${scenario.$2.toInt()}-${scenario.$4?'dark':'light'}';
   if(scenario.$1==390&&scenario.$3==1)await capture(tester,key,'editorial-home-$suffix');
   await tester.tap(find.text('Study').last);await tester.pumpAndSettle();
   expect(find.text('Course Summary'),findsOneWidget);expect(find.text('Exam Summary'),findsOneWidget);expect(tester.takeException(),isNull);
   if(scenario.$1==390&&scenario.$3==1){
     // Extra screen height must not stretch the poster's compact study cards.
     final icon=tester.getRect(find.byIcon(Icons.menu_book_outlined).first);
     final title=tester.getRect(find.text('Course Summary'));
     expect(title.top-icon.bottom,closeTo(18,0.1));
   }
   await tester.scrollUntilVisible(find.byTooltip('Quote actions'),100,scrollable:find.byType(Scrollable).first);
   await tester.tap(find.byTooltip('Quote actions'));await tester.pumpAndSettle();
   expect(find.text('Share Quote'),findsOneWidget);expect(find.text('Save Quote'),findsOneWidget);
   await tester.tap(find.text('Save Quote'));await tester.pumpAndSettle();
   expect(api.writes,isEmpty);
   await tester.pump(const Duration(seconds:5));await tester.pumpAndSettle();
   // Restore the first viewport for the visual review captures.
   await tester.drag(find.byType(ListView).first,const Offset(0,1500));await tester.pumpAndSettle();

   if(scenario.$1==390&&scenario.$3==1)await capture(tester,key,'editorial-study-$suffix');
   await tester.tap(find.text('Wallet').last);await tester.pumpAndSettle();
   expect(find.text('₦5,200.00'),findsOneWidget);expect(find.text('Active'),findsNothing);expect(tester.takeException(),isNull);
   if(scenario.$1==390&&scenario.$3==1)await capture(tester,key,'editorial-wallet-$suffix');
   await tester.scrollUntilVisible(find.text('My Exam Summaries'),200,scrollable:find.byType(Scrollable).first);await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   await tester.tap(find.text('More').last);await tester.pumpAndSettle();expect(find.byType(TextField),findsOneWidget);expect(tester.takeException(),isNull);
   await tester.pumpWidget(wrap(NativeAuth(api)));
   await tester.runAsync(()=>precacheImage(const AssetImage('assets/images/skins/editorial-campus.webp'),tester.element(find.byType(NativeAuth))));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   if(scenario.$1==390&&scenario.$3==1)await capture(tester,key,'editorial-welcome-$suffix');
   await tester.scrollUntilVisible(find.text('Log In'),200,scrollable:find.byType(Scrollable).first);await tester.tap(find.text('Log In'));await tester.pumpAndSettle();
   expect(find.widgetWithText(TextField,'Email address'),findsOneWidget);expect(find.widgetWithText(TextField,'Password'),findsOneWidget);expect(tester.takeException(),isNull);
   expect(api.writes,isEmpty);expect(PremiumService.instance.isPremium,isFalse);expect((await SharedPreferences.getInstance()).getString('nu-study-editorial-sample-CIT321'),isNull);
   await tester.pumpWidget(const SizedBox.shrink());
  });
 }
}
