import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/skin_theme.dart';
import 'package:noun_update_student_app/widgets/premium_layouts.dart';
void main(){
 for(final skin in AppSkin.values.where((s)=>s.isPremium)){
  testWidgets('${skin.label} retains account birthday, server quote and verified exam text',(tester)async{
   tester.view.physicalSize=const Size(320,844);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(MaterialApp(theme:buildSkinTheme(skin),home:Scaffold(body:PremiumHomeLayout(
    greeting:'Good morning',meta:'NOUN student',courseCount:4,walletBalance:'₦1,000',setupNeeded:false,quickServices:const [],
    nextExamSummary:'CIT411 · 30 September · 9:00 AM WAT',birthday:const Text('Account birthday'),motivation:const Text('Server daily quote'),latestUpdates:const SizedBox.shrink(),
    onSetup:(){},onCourses:(){},onExam:(){},onStudy:(){},onWallet:(){},onOpen:(_){},
   ))));
   await tester.pumpAndSettle();
   expect(find.text('Account birthday'),findsOneWidget);expect(find.text('Server daily quote'),findsOneWidget);
   final homeScroll=find.descendant(of:find.byKey(const PageStorageKey('home')),matching:find.byType(Scrollable)).first;
   await tester.scrollUntilVisible(find.text('CIT411 · 30 September · 9:00 AM WAT'),180,scrollable:homeScroll);
   expect(find.text('CIT411 · 30 September · 9:00 AM WAT'),findsOneWidget);expect(tester.takeException(),isNull);
  });
 }
}
