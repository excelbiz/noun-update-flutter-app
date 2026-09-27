import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Stable API identifiers. Screens and navigation are shared by every skin.
enum AppSkin {
  defaultNoun('NOUN Update Default'), smartCampus('Smart Campus'),
  premiumDark('Premium Dark'), glassmorphism('Glassmorphism'),
  studentFriendly('Student Friendly'), minimalAcademic('Minimal Academic'),
  elegantEditorial('Elegant Editorial'), productivityDashboard('Productivity Dashboard'),
  friendlyModern('Friendly Modern'), futureTech('Future Tech'), boldPremium('Bold Premium');
  const AppSkin(this.label);
  final String label;
  bool get isPremium => this != defaultNoun;
}

@immutable
class SkinTokens extends ThemeExtension<SkinTokens> {
  const SkinTokens({required this.skin, required this.background, required this.surface,
    required this.primary, required this.gold, required this.ink, required this.radius});
  final AppSkin skin;
  final Color background, surface, primary, gold, ink;
  final double radius;
  static SkinTokens of(BuildContext context) => Theme.of(context).extension<SkinTokens>() ??
      forSkin(AppSkin.defaultNoun, Theme.of(context).brightness);
  static SkinTokens forSkin(AppSkin skin, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final warm = {AppSkin.minimalAcademic, AppSkin.elegantEditorial, AppSkin.friendlyModern}.contains(skin);
    final tech = skin == AppSkin.futureTech;
    final radius = switch(skin) {
      AppSkin.minimalAcademic => 10.0, AppSkin.elegantEditorial => 8.0,
      AppSkin.friendlyModern => 26.0, AppSkin.studentFriendly => 22.0,
      AppSkin.productivityDashboard => 12.0, AppSkin.boldPremium => 14.0,
      _ => 18.0,
    };
    return SkinTokens(skin:skin,
      background: Color(dark ? (tech ? 0xff021711 : warm ? 0xff191d17 : 0xff081712) : (warm ? 0xfff8f4e9 : 0xfff3f9f6)),
      surface: Color(dark ? (tech ? 0xff082c20 : warm ? 0xff242b22 : 0xff142820) : (warm ? 0xfffffcf4 : 0xffffffff)),
      primary: Color(dark ? (tech ? 0xff5aefad : 0xffa5dfbd) : 0xff00553a),
      gold: Color(dark ? 0xffffd979 : 0xff795800),
      ink: Color(dark ? 0xfff2f6ef : 0xff132b23), radius: radius);
  }
  @override SkinTokens copyWith({AppSkin? skin, Color? background, Color? surface, Color? primary, Color? gold, Color? ink, double? radius}) =>
    SkinTokens(skin:skin??this.skin,background:background??this.background,surface:surface??this.surface,primary:primary??this.primary,gold:gold??this.gold,ink:ink??this.ink,radius:radius??this.radius);
  @override SkinTokens lerp(covariant SkinTokens? other,double t) => other == null ? this : SkinTokens(
    skin:t<.5?skin:other.skin,background:Color.lerp(background,other.background,t)!,surface:Color.lerp(surface,other.surface,t)!,primary:Color.lerp(primary,other.primary,t)!,gold:Color.lerp(gold,other.gold,t)!,ink:Color.lerp(ink,other.ink,t)!,radius:radius+(other.radius-radius)*t);
}

ThemeData buildSkinTheme(AppSkin skin, {Brightness brightness=Brightness.light, String? fontFamily='NUSans', Color accent=AppColours.green700}) {
  final base=buildAppTheme(brightness:brightness,fontFamily:fontFamily,accent:accent);
  if(skin==AppSkin.defaultNoun) return base;
  final t=SkinTokens.forSkin(skin,brightness);
  final scheme=ColorScheme.fromSeed(seedColor:t.primary,brightness:brightness).copyWith(
    primary:t.primary,secondary:t.gold,surface:t.surface,onSurface:t.ink,surfaceContainerLow:t.surface);
  final editorial=skin==AppSkin.elegantEditorial;
  return base.copyWith(colorScheme:scheme,scaffoldBackgroundColor:t.background,extensions:[t],
    textTheme:base.textTheme.copyWith(
      headlineLarge:base.textTheme.headlineLarge?.copyWith(fontFamily:editorial?'NUReading':fontFamily),
      titleLarge:base.textTheme.titleLarge?.copyWith(fontFamily:editorial?'NUReading':fontFamily)),
    cardTheme:base.cardTheme.copyWith(color:t.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(t.radius))),
    navigationBarTheme:base.navigationBarTheme.copyWith(backgroundColor:t.surface,indicatorColor:scheme.secondaryContainer));
}
