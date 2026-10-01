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
import 'package:noun_update_student_app/screens/native_tools.dart';
import 'package:noun_update_student_app/screens/skin_gallery.dart';
import 'package:noun_update_student_app/widgets/future_tech_layouts.dart';
import 'package:noun_update_student_app/widgets/native_ui.dart';
import 'live_portal_test.dart' show capture;

class TechReviewApi extends ApiClient {
 final writes=<String>[];
 @override Future<Map<String,dynamic>> getJson(String path)async{
  if(path=='/services')return {'data':{'items':jsonDecode(File('assets/data/services.json').readAsStringSync())}};
  if(path.startsWith('/study/'))return futurePreviewStudy(path);
  if(path.startsWith('/materials'))return {'data':{'items':[{'course_code':'GST101','title':'Use of English'}]}};
  if(path=='/fees/options')return {'data':{'items':[{'program':'B.Sc. Computer Science','level':'300','semester':'2026_2'}]}};
  if(path.startsWith('/posts/'))return {'data':{'items':boldPreviewNotices()}};
  return {'data':{'items':[]}};
 }
 @override Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey})async{writes.add(path);throw const ApiException('Read-only style review.');}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{
  await rootBundle.loadString('assets/data/services.json');
  for(final f in [('NUSans','NUSans-Regular.ttf'),('NUReading','NUReading.ttf')]){
   final loader=FontLoader(f.$1)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${f.$2}').readAsBytesSync())));
   if(f.$1=='NUSans')loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/NUSans-Bold.ttf').readAsBytesSync())));
   await loader.load();
  }
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())))).load();
 });
 for(final scenario in [(390.0,844.0,1.0,true),(390.0,1040.0,1.0,true),(390.0,844.0,1.0,false),(320.0,844.0,1.5,true),(320.0,844.0,1.5,false)]){
 testWidgets('Future Tech reference ${scenario.$1}x${scenario.$2} scale ${scenario.$3} dark ${scenario.$4}',(tester)async{
  SharedPreferences.setMockInitialValues({});PremiumService.instance.clear();addTearDown(PremiumService.instance.clear);
  tester.view.physicalSize=Size(scenario.$1,scenario.$2);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final api=TechReviewApi(),key=GlobalKey(),suffix='${scenario.$2.toInt()}-${scenario.$4?'dark':'light'}';final screenshots=scenario.$1==390;
  Widget wrap(Widget child)=>RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildSkinTheme(AppSkin.futureTech,brightness:scenario.$4?Brightness.dark:Brightness.light),builder:(c,child)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:TextScaler.linear(scenario.$3)),child:child!),home:child));
  await tester.pumpWidget(wrap(LivePortal(apiClient:api,preview:true,previewData:futurePreviewData())));await tester.pumpAndSettle();await tester.runAsync(()=>precacheImage(const AssetImage('assets/images/skins/study.webp'),tester.element(find.byType(LivePortal))));await tester.pumpAndSettle();
  expect(find.text('65%'),findsOneWidget);expect(find.text('70%'),findsOneWidget);expect(find.text('4 of 6 courses completed'),findsOneWidget);expect(find.text('₦12,500.00'),findsOneWidget);expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-home-$suffix');
  await tester.tap(find.text('Study').last);await tester.pumpAndSettle();
  if(scenario.$3==1)expect(find.byType(TechResourceRow),findsNWidgets(6));expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-study-$suffix');
  await tester.tap(find.text('Course Summary'));await tester.pumpAndSettle();expect(find.byType(MaterialLibrary),findsOneWidget);
  expect(SkinTokens.of(tester.element(find.byType(MaterialLibrary))).skin,AppSkin.futureTech);expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-summary-$suffix');await tester.pageBack();await tester.pumpAndSettle();
  await tester.tap(find.text('Tools').last);await tester.pumpAndSettle();expect(find.text('Fee Checker'),findsOneWidget);expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-tools-$suffix');
  await tester.tap(find.text('Fee Checker'));await tester.pumpAndSettle();expect(find.byType(NativeFees),findsOneWidget);expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-fees-$suffix');await tester.pageBack();await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('My Courses hub'));await tester.pumpAndSettle();expect(find.text('My Courses'),findsWidgets);expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-courses-$suffix');await tester.pageBack();await tester.pumpAndSettle();
  await tester.pumpWidget(wrap(NativeAuth(api)));await tester.runAsync(()async{for(final a in ['future-tech-campus','editorial-emblem']){await precacheImage(AssetImage('assets/images/skins/$a.webp'),tester.element(find.byType(NativeAuth)));}});await tester.pumpAndSettle();
  expect(tester.takeException(),isNull);if(screenshots)await capture(tester,key,'future-welcome-$suffix');
  await tester.scrollUntilVisible(find.text('Sign In'),100,scrollable:find.byType(Scrollable).first);await tester.tap(find.text('Sign In'));await tester.pumpAndSettle();expect(find.widgetWithText(TextField,'Email address'),findsOneWidget);expect(tester.takeException(),isNull);
  if(screenshots)await capture(tester,key,'future-signin-$suffix');expect(api.writes,isEmpty);expect(PremiumService.instance.isPremium,isFalse);
 });}
 for(final skin in AppSkin.values){for(final brightness in Brightness.values){testWidgets('Routes retain ${skin.label} ${brightness.name} and its form/dialog theme',(tester)async{
  SharedPreferences.setMockInitialValues({});tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);final key=GlobalKey(),api=TechReviewApi();
  final preview=Theme(data:buildSkinTheme(skin,brightness:brightness),child:Builder(builder:(c)=>Scaffold(body:Center(child:FilledButton(onPressed:()=>pushNu(c,NativeFees(api)),child:const Text('Open fee form'))))));
  await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildSkinTheme(AppSkin.defaultNoun),home:preview)));
  await tester.tap(find.text('Open fee form'));await tester.pumpAndSettle();
  final c=tester.element(find.byType(NativeFees)),theme=Theme.of(c);expect(SkinTokens.of(c).skin,skin);expect(theme.brightness,brightness);
  if(skin.isPremium){expect(theme.inputDecorationTheme.fillColor,SkinTokens.of(c).surface);expect(theme.dialogTheme.backgroundColor,SkinTokens.of(c).surface);}
  if([AppSkin.futureTech,AppSkin.boldPremium,AppSkin.elegantEditorial].contains(skin))await capture(tester,key,'inside-${skin.name}-fees-${brightness.name}');
  pushNu(c,const NativeCgpa());await tester.pumpAndSettle();expect(SkinTokens.of(tester.element(find.byType(NativeCgpa))).skin,skin);
  if([AppSkin.futureTech,AppSkin.boldPremium,AppSkin.elegantEditorial].contains(skin))await capture(tester,key,'inside-${skin.name}-cgpa-${brightness.name}');
  final inner=tester.element(find.byType(NativeCgpa));
  showDialog<void>(context:inner,builder:(c)=>AlertDialog(title:const Text('Review form'),content:const Text('Skin continuity'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close review'))]));await tester.pumpAndSettle();
  expect(SkinTokens.of(tester.element(find.byType(AlertDialog))).skin,skin);await tester.tap(find.text('Close review'));await tester.pumpAndSettle();
  pushNu(inner,MaterialLibrary(api:api,summaries:true));await tester.pumpAndSettle();
  expect(SkinTokens.of(tester.element(find.byType(MaterialLibrary))).skin,skin);expect(find.text('GST101'),findsOneWidget);
  await tester.runAsync(()=>precacheImage(const AssetImage('assets/images/skins/study.webp'),tester.element(find.byType(MaterialLibrary))));await tester.pumpAndSettle();
  if([AppSkin.futureTech,AppSkin.boldPremium,AppSkin.elegantEditorial].contains(skin))await capture(tester,key,'inside-${skin.name}-library-${brightness.name}');
  await tester.pageBack();await tester.pumpAndSettle();await tester.pageBack();await tester.pumpAndSettle();await tester.pageBack();await tester.pumpAndSettle();expect(find.text('Open fee form'),findsOneWidget);expect(api.writes,isEmpty);expect(tester.takeException(),isNull);
 });}}
}
