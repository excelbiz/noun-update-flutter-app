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
import 'package:noun_update_student_app/widgets/bold_layouts.dart';
import 'live_portal_test.dart' show capture;

class BoldReviewApi extends ApiClient {
  final writes = <String>[];
  @override Future<Map<String,dynamic>> getJson(String path) async {
    if(path=='/services')return {'data':{'items':jsonDecode(await rootBundle.loadString('assets/data/services.json'))}};
    if(path=='/study/EDU302/state')return {'data':{'done':[for(var i=0;i<12;i++)i]}};
    if(path=='/study/EDU302')return {'data':{'course_title':'Research Methods in Education','sections':[for(var i=0;i<20;i++){'index':i}]}};
    if(path=='/motivation/today')return {'data':{'quote':{'id':0,'quote':'Consistency today creates success tomorrow.','author':'NOUN Update','date':DateTime.now().toUtc().add(const Duration(hours:1)).toIso8601String().substring(0,10)}}};
    if(path.startsWith('/posts/'))return {'data':{'items':boldPreviewNotices()}};
    return {'data':{'items':[]}};
  }
  @override Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey})async {
    writes.add(path);throw const ApiException('Design fixture is read-only.');
  }
}

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{
   await rootBundle.loadString('assets/data/services.json');
   for(final f in [('NUSans','NUSans-Regular.ttf'),('NUReading','NUReading.ttf')]){
     await (FontLoader(f.$1)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${f.$2}').readAsBytesSync())))).load();
   }
   final icons=File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
   await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
 });
 for(final scenario in [(390.0,844.0,1.0,false),(390.0,1040.0,1.0,false),(390.0,844.0,1.0,true),
   (320.0,844.0,1.0,false),(390.0,844.0,1.25,false),(320.0,844.0,1.5,false),(320.0,844.0,1.5,true)]){
  testWidgets('Bold Premium native review ${scenario.$1}x${scenario.$2} scale ${scenario.$3} dark ${scenario.$4}',(tester)async{
   SharedPreferences.setMockInitialValues({});PremiumService.instance.clear();addTearDown(PremiumService.instance.clear);
   tester.view.physicalSize=Size(scenario.$1,scenario.$2);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   final api=BoldReviewApi(),key=GlobalKey();
   Widget wrap(Widget child,{AppSkin skin=AppSkin.boldPremium})=>RepaintBoundary(key:key,child:MaterialApp(
     debugShowCheckedModeBanner:false,theme:buildSkinTheme(skin,brightness:scenario.$4?Brightness.dark:Brightness.light),
     builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scenario.$3)),child:child!),home:child));
   final portal=LivePortal(apiClient:api,preview:true,previewData:boldPreviewData());
   await tester.pumpWidget(wrap(portal));await tester.pumpAndSettle();
   expect(find.text('60% complete'),findsOneWidget);expect(find.text('₦5,000.00'),findsOneWidget);
   expect(find.text('IMPORTANT UPDATE'),findsWidgets);expect(tester.takeException(),isNull);
   final suffix='${scenario.$2.toInt()}-${scenario.$4?'dark':'light'}';
   final screenshots=scenario.$1==390&&scenario.$3==1;
   if(screenshots)await capture(tester,key,'bold-home-$suffix');
   if(scenario.$3==1){
     await tester.tap(find.byTooltip('Dismiss update'));await tester.pumpAndSettle();
     expect(find.text('IMPORTANT UPDATE'),findsNothing);
   }
   await tester.tap(find.text('Study').last);await tester.pumpAndSettle();
   if(scenario.$3<=1.3){
   final titles=find.byType(BoldStudyLayout).evaluate().single;
   final rects=[for(final title in ['My Courses','Course Summary','Exam Summary','Past Questions','Course Materials','Study Hub'])tester.getRect(find.descendant(of:find.byWidget(titles.widget),matching:find.text(title)))];
   expect(rects[0].top,lessThan(rects[2].top));expect(rects[2].top,lessThan(rects[4].top));
   }
   expect(tester.takeException(),isNull);
   if(screenshots)await capture(tester,key,'bold-study-$suffix');
   await tester.scrollUntilVisible(find.byTooltip('Quote actions'),100,scrollable:find.byType(Scrollable).first);
   await Scrollable.ensureVisible(tester.element(find.byTooltip('Quote actions')),alignment:.5);await tester.pumpAndSettle();
   await tester.tap(find.byTooltip('Quote actions'));await tester.pumpAndSettle();
   expect(find.text('Share Quote'),findsOneWidget);await tester.tap(find.text('Save Quote'));await tester.pumpAndSettle();
   expect(api.writes,isEmpty);await tester.pump(const Duration(seconds:5));await tester.pumpAndSettle();
   await tester.tap(find.text('Tools').last);await tester.pumpAndSettle();
   expect(find.text('Tools & Wallet'),findsOneWidget);expect(find.text('Explore'),findsOneWidget);expect(find.text('Active'),findsNothing);
   for(final title in ['Fee Checker','PAS Status','Personalised Timetable','Mock e-Exam','Result Checker','CGPA Calculator'])expect(find.text(title),findsWidgets);
   expect(tester.takeException(),isNull);
   if(screenshots)await capture(tester,key,'bold-tools-$suffix');
   await tester.tap(find.text('See All').first);await tester.pumpAndSettle();
   await tester.enterText(find.byType(TextField),'result');await tester.pumpAndSettle();
   expect(find.byType(TextField),findsOneWidget);expect(find.text('Result Checker'),findsWidgets);expect(tester.takeException(),isNull);
   await tester.tap(find.text('Wallet').last);await tester.pumpAndSettle();
   expect(find.byKey(const PageStorageKey('wallet')),findsOneWidget);expect(find.text('₦5,000.00'),findsOneWidget);
   expect(find.text('+₦5,000.00'),findsOneWidget);expect(find.text('−₦500.00'),findsOneWidget);expect(tester.takeException(),isNull);
   if(screenshots)await capture(tester,key,'bold-wallet-$suffix');
   await tester.tap(find.text('Top Up'));await tester.pumpAndSettle();
   expect(find.text('Add funds'),findsOneWidget);await tester.tap(find.text('Cancel'));await tester.pumpAndSettle();
   // A skin change while on the extra Wallet destination must keep native navigation valid.
   if(scenario.$3==1){await tester.pumpWidget(wrap(portal,skin:AppSkin.defaultNoun));await tester.pumpAndSettle();expect(tester.takeException(),isNull);}
   await tester.pumpWidget(wrap(NativeAuth(api)));
   await tester.runAsync(()async{for(final a in ['bold-premium-welcome','editorial-emblem']){
     await precacheImage(AssetImage('assets/images/skins/$a.webp'),tester.element(find.byType(NativeAuth)));}});
   await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   if(screenshots)await capture(tester,key,'bold-welcome-$suffix');
   await tester.scrollUntilVisible(find.text('Sign In'),100,scrollable:find.byType(Scrollable).first);
   await tester.tap(find.text('Sign In'));await tester.pumpAndSettle();
   expect(find.widgetWithText(TextField,'Email address'),findsOneWidget);expect(find.widgetWithText(TextField,'Password'),findsOneWidget);
   expect(tester.takeException(),isNull);expect(api.writes,isEmpty);expect(PremiumService.instance.isPremium,isFalse);
   expect((await SharedPreferences.getInstance()).getString('nu-study-bold-sample-EDU302'),isNull);
   await tester.pumpWidget(const SizedBox.shrink());
  });
 }
}
