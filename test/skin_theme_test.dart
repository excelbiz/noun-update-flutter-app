import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/skin_theme.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
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
}
