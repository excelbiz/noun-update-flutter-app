import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/skin_theme.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/widgets/premium_layouts.dart';
double contrast(Color a,Color b){
 final x=a.computeLuminance(),y=b.computeLuminance();
 return ((x>y?x:y)+.05)/((x>y?y:x)+.05);
}
void main(){
 test('One free design and ten premium designs',(){
  expect(AppSkin.values.length,11);
  expect(AppSkin.values.where((s)=>s.isPremium).length,10);
 });
 test('Default design remains unchanged',(){
  for(final brightness in Brightness.values){
   expect(buildSkinTheme(AppSkin.defaultNoun,brightness:brightness).scaffoldBackgroundColor,buildAppTheme(brightness:brightness).scaffoldBackgroundColor);
  }
 });
 test('Each premium skin has deliberate light and dark surfaces',(){
  for(final skin in AppSkin.values.where((s)=>s.isPremium)){
   final light=buildSkinTheme(skin),dark=buildSkinTheme(skin,brightness:Brightness.dark);
   expect(light.brightness,Brightness.light);
   expect(dark.brightness,Brightness.dark);
   expect(light.scaffoldBackgroundColor,isNot(dark.scaffoldBackgroundColor));
   expect(light.extension<SkinTokens>()!.skin,skin);
  }
 });
 testWidgets('Premium headers and preview titles remain readable in both appearances',(tester)async{
  for(final skin in AppSkin.values.where((s)=>s.isPremium)){
   for(final brightness in Brightness.values){
    final theme=buildSkinTheme(skin,brightness:brightness);
    final tokens=theme.extension<SkinTokens>()!;
    for(final fill in [tokens.heroSurface,Color.lerp(tokens.heroSurface,tokens.gold,.12)!]){
     expect(contrast(Color.alphaBlend(Colors.white.withValues(alpha:.82),fill),fill),greaterThanOrEqualTo(4.5),reason:'${skin.label} hero labels $brightness');
    }
    expect(contrast(theme.appBarTheme.titleTextStyle!.color!,theme.appBarTheme.backgroundColor!),greaterThanOrEqualTo(4.5),reason:'${skin.label} preview title $brightness');
    await tester.pumpWidget(MaterialApp(theme:theme,home:Scaffold(appBar:PremiumTopBar(onTools:(){},onRefresh:(){},onNotifications:(){}))));
    final bar=tester.widget<AppBar>(find.byType(AppBar));
    expect(contrast(bar.foregroundColor!,bar.backgroundColor!),greaterThanOrEqualTo(4.5),reason:'${skin.label} Home header $brightness');
   }
  }
 });
}
