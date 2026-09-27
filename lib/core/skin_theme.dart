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
    // Each tuple is background, surface, primary and secondary. Dark palettes
    // are authored independently rather than inverted from the light palette.
    final palette=switch(skin){
      AppSkin.smartCampus => dark ? [0xff0b2018,0xff16382a,0xff9bddb9,0xffffd778] : [0xfff0f6f2,0xffffffff,0xff005638,0xff805d00],
      AppSkin.premiumDark => dark ? [0xff030e0b,0xff10221d,0xffffd677,0xff7be0b0] : [0xfff3eedf,0xfffffcf3,0xff064331,0xff765500],
      AppSkin.glassmorphism => dark ? [0xff092b25,0xff21473f,0xffb7f7d9,0xffffdc87] : [0xffdceee6,0xffedf8f2,0xff005642,0xff755400],
      AppSkin.studentFriendly => dark ? [0xff14271e,0xff223f31,0xffa9eec3,0xffffd77e] : [0xfff9fcf4,0xffffffff,0xff096442,0xff875300],
      AppSkin.minimalAcademic => dark ? [0xff191e19,0xff252e26,0xffb6d3bb,0xffd8c89d] : [0xfff6f5ef,0xfffffefa,0xff234e38,0xff746345],
      AppSkin.elegantEditorial => dark ? [0xff211e16,0xff302d23,0xffd4e6cb,0xffe3c581] : [0xfff6f0df,0xfffffaed,0xff163b2a,0xff805e19],
      AppSkin.productivityDashboard => dark ? [0xff0b1e22,0xff183039,0xff93dbc3,0xff9ccfff] : [0xffeef4f6,0xffffffff,0xff005749,0xff265c83],
      AppSkin.friendlyModern => dark ? [0xff232a20,0xff343e2e,0xffc1e8ae,0xffefd29a] : [0xfff8f7eb,0xfffffef8,0xff37613f,0xff795826],
      AppSkin.futureTech => dark ? [0xff021710,0xff082c20,0xff5aefad,0xffffd858] : [0xffe7f8ef,0xfff6fff9,0xff005c3b,0xff746000],
      AppSkin.boldPremium => dark ? [0xff061d16,0xff10382a,0xfff5d474,0xffa9edc2] : [0xfff3f6f3,0xffffffff,0xff004d30,0xff8c5600],
      AppSkin.defaultNoun => dark ? [0xff101715,0xff17201d,0xffa5dfbd,0xffffd979] : [0xfff8faf9,0xffffffff,0xff00553a,0xff795800],
    };
    final radius=switch(skin){AppSkin.minimalAcademic=>10.0,AppSkin.elegantEditorial=>8.0,AppSkin.friendlyModern=>26.0,AppSkin.studentFriendly=>22.0,AppSkin.productivityDashboard=>12.0,AppSkin.boldPremium=>14.0,_=>18.0};
    return SkinTokens(skin:skin,background:Color(palette[0]),surface:Color(palette[1]),primary:Color(palette[2]),gold:Color(palette[3]),ink:Color(dark?0xfff2f6ef:0xff132b23),radius:radius);
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
