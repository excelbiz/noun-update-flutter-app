import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/premium_service.dart';
import 'package:noun_update_student_app/core/skin_theme.dart';
import 'package:noun_update_student_app/screens/skin_gallery.dart';
import 'package:noun_update_student_app/screens/personalisation.dart';
import 'package:noun_update_student_app/screens/profile_cosmetics.dart';
import 'package:noun_update_student_app/screens/live_portal.dart';
import 'live_portal_test.dart' show capture;

class PersonalisationApi extends ApiClient {
  bool active=true,fail=false;
  Map<String,dynamic> prefs={'preferred_skin':'futureTech','profile_frame':'futureGlow','birthday':{'month':9,'day':27,'celebration_enabled':true}};
  @override Future<Map<String,dynamic>> getJson(String path)async{
    if(fail)throw const ApiException('Offline');
    if(path=='/premium/status')return {'data':{'active':active,'features':{'premium_skins':true,'profile_frames':true},'server_time':'2026-09-27T12:00:00Z','expires_at':'2026-09-27T13:00:00Z'}};
    return {'data':prefs};
  }
  @override Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey})async{prefs={...prefs,...body};return {'data':prefs};}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(()async{
  await rootBundle.loadString('assets/data/services.json');
  for(final f in [('NUSans','NUSans-Regular.ttf'),('NUReading','NUReading.ttf')]){await (FontLoader(f.$1)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/${f.$2}').readAsBytesSync())))).load();}
  // Premium layout families deliberately use platform light, condensed and
  // technical/monospaced faces. The headless Linux renderer does not provide
  // Android's family aliases automatically, so load deterministic local test
  // aliases. This changes screenshots/tests only; physical devices use their
  // native system families with NUSans fallback from SkinTokens.
  final sans=File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
  final mono=File('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf');
  if(sans.existsSync()){
    for(final family in ['sans-serif','sans-serif-light','sans-serif-condensed','Roboto']){
      await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(sans.readAsBytesSync())))).load();
    }
  }
  if(mono.existsSync()){
    await (FontLoader('monospace')..addFont(Future.value(ByteData.sublistView(mono.readAsBytesSync())))).load();
  }
  final icons=File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
 });
 test('Server entitlement controls skin and profile frame; expiry preserves preferences',()async{
  final p=PremiumService(),api=PersonalisationApi();
  await p.refresh(api,'1');expect(p.effectiveSkin,AppSkin.futureTech);expect(p.suppressAds,isTrue);expect(p.effectiveProfileFrame,'futureGlow');
  expect(p.isBirthday(DateTime(2026,9,27)),isTrue);expect(p.isBirthday(DateTime(2026,9,28)),isFalse);
  api.active=false;await p.refresh(api,'1');expect(p.effectiveSkin,AppSkin.defaultNoun);expect(p.preferredSkin,AppSkin.futureTech);expect(p.effectiveProfileFrame,'classic');expect(p.preferredProfileFrame,'futureGlow');
  api.active=true;api.fail=true;await p.refresh(api,'1');expect(p.isPremium,isFalse);expect(p.effectiveProfileFrame,'classic');
  p.clear();expect(p.accountId,isNull);expect(p.isBirthday(DateTime(2026,9,27)),isFalse);p.dispose();
 });
 testWidgets('Profile style selector shows all frames and applies selected frame',(tester)async{
   SharedPreferences.setMockInitialValues({});
   final api=PersonalisationApi();final p=PremiumService.instance;p.clear();
   addTearDown(p.clear);
   await p.refresh(api,'1');
   tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(MaterialApp(theme:buildSkinTheme(AppSkin.defaultNoun),home:ProfileCosmeticsPage(api:api,name:'NOUN Student')));await tester.pumpAndSettle();
   for(final label in ['Classic','Academic Gold','Campus Green','Future Glow','Editorial Ink'])expect(find.text(label),findsOneWidget);
   expect(find.byType(PremiumProfileAvatar),findsWidgets);
   final apply=find.widgetWithText(FilledButton,'Apply').first;
   await tester.ensureVisible(apply);
   await tester.pump();
   await tester.tap(apply);
   await tester.pump();
   await tester.pump(const Duration(milliseconds:350));
   expect(p.preferredProfileFrame,isNot('futureGlow'));
   await tester.pumpWidget(const SizedBox.shrink());
 });
 for(final skin in AppSkin.values.where((s)=>s.isPremium)){
  testWidgets('${skin.label} supports both appearances without applying entitlement',(tester)async{
   SharedPreferences.setMockInitialValues({});PremiumService.instance.clear();
   tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   final key=GlobalKey();await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,home:SkinPreview(skin:skin))));await tester.pumpAndSettle();
   await tester.runAsync(()async{for(final a in ['campus','students','study']){await precacheImage(AssetImage('assets/images/skins/$a.webp'),tester.element(find.byType(SkinPreview)));}await precacheImage(const AssetImage('assets/images/noun_update_logo.png'),tester.element(find.byType(SkinPreview)));});await tester.pumpAndSettle();
   expect(tester.takeException(),isNull);await capture(tester,key,'skin-${skin.name}-light');
   for(final label in ['Study','Tools']){
     await tester.tap(find.text(label).last);await tester.pumpAndSettle();expect(tester.takeException(),isNull);
     if(label=='Tools')expect(find.text('No tools match your search.'),findsNothing);
     await capture(tester,key,'skin-${skin.name}-${label.toLowerCase()}-light');
   }
   await tester.tap(find.text('Home').last);await tester.pumpAndSettle();
   await tester.tap(find.byTooltip('Preview dark'));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   await capture(tester,key,'skin-${skin.name}-dark');expect(PremiumService.instance.isPremium,isFalse);
   expect(find.byType(LivePortal),findsOneWidget);
   for(final label in ['Study','Tools','Updates','Profile']){
     await tester.tap(find.text(label).last);await tester.pumpAndSettle();expect(tester.takeException(),isNull);
     if(label=='Tools')expect(find.text('No tools match your search.'),findsNothing);
     if(label=='Study'||label=='Tools')await capture(tester,key,'skin-${skin.name}-${label.toLowerCase()}-dark');
   }
   await tester.tap(find.byTooltip('Preview sign-in'));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   await capture(tester,key,'skin-${skin.name}-login-dark');
   expect((await SharedPreferences.getInstance()).getString('nu-daily-motivation'),isNull);
   await tester.tap(find.byTooltip('Preview dashboard'));await tester.pumpAndSettle();
   tester.view.physicalSize=const Size(320,844);
   await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(1.5)),child:child!),home:SkinPreview(skin:skin))));await tester.pumpAndSettle();
   await tester.tap(find.text('Study').last);await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   await tester.drag(find.byKey(const PageStorageKey('study')),const Offset(0,-430));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
   await tester.pumpWidget(const SizedBox.shrink());
  });
 }
 testWidgets('Branded share card contains only explicitly selected public text',(tester)async{
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final key=GlobalKey();await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:buildSkinTheme(AppSkin.defaultNoun),home:const BrandedShareCard(title:'Today’s motivation',message:'Every small step counts.',author:'NOUN Update'))));await tester.pumpAndSettle();
  await tester.runAsync(()=>precacheImage(const AssetImage('assets/images/noun_update_logo.png'),tester.element(find.byType(BrandedShareCard))));await tester.pumpAndSettle();
  expect(find.textContaining('Every small step'),findsOneWidget);expect(find.textContaining('email'),findsNothing);
  await capture(tester,key,'quote-share-card');await tester.pumpWidget(const SizedBox.shrink());
 });
}
