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
  // Night palettes use bright accents; white hero text needs a darker fill.
  Color get heroSurface => primary.computeLuminance() > .18
      ? Color.lerp(primary, Colors.black, .65)!
      : primary;

  /// Typography is part of the layout family. The app bundles NUSans and
  /// NUReading; platform generic families are used deliberately for condensed,
  /// monospaced and light technical treatments, with NUSans as the safe fallback.
  String get bodyFont => switch(skin){
    AppSkin.premiumDark=>'NUSans',
    AppSkin.glassmorphism=>'sans-serif-light',
    AppSkin.studentFriendly=>'sans-serif',
    AppSkin.minimalAcademic=>'NUSans',
    AppSkin.elegantEditorial=>'NUSans',
    AppSkin.productivityDashboard=>'sans-serif-condensed',
    AppSkin.friendlyModern=>'NUSans',
    AppSkin.futureTech=>'NUSans',
    AppSkin.boldPremium=>'NUSans',
    _=>'NUSans',
  };
  String get displayFont => switch(skin){
    AppSkin.smartCampus=>'NUSans',
    AppSkin.premiumDark=>'NUReading',
    AppSkin.glassmorphism=>'sans-serif-light',
    AppSkin.studentFriendly=>'NUSans',
    AppSkin.minimalAcademic=>'NUReading',
    AppSkin.elegantEditorial=>'NUReading',
    AppSkin.productivityDashboard=>'sans-serif-condensed',
    AppSkin.friendlyModern=>'NUSans',
    AppSkin.futureTech=>'NUSans',
    AppSkin.boldPremium=>'NUSans',
    _=>'NUSans',
  };
  String get numberFont => switch(skin){
    AppSkin.productivityDashboard||AppSkin.futureTech=>'NUSans',
    AppSkin.premiumDark=>'NUReading',
    _=>bodyFont,
  };
  List<String> get fontFallback => const ['NUSans','Roboto','Arial'];
  FontWeight get headingWeight => switch(skin){
    AppSkin.glassmorphism=>FontWeight.w500,
    AppSkin.minimalAcademic=>FontWeight.w600,
    AppSkin.elegantEditorial=>FontWeight.w600,
    AppSkin.productivityDashboard=>FontWeight.w800,
    AppSkin.futureTech=>FontWeight.w700,
    AppSkin.boldPremium=>FontWeight.w900,
    _=>FontWeight.w800,
  };
  FontWeight get titleWeight => switch(skin){
    AppSkin.glassmorphism=>FontWeight.w600,
    AppSkin.minimalAcademic||AppSkin.elegantEditorial=>FontWeight.w600,
    AppSkin.boldPremium=>FontWeight.w900,
    _=>FontWeight.w800,
  };
  double get headingTracking => switch(skin){
    AppSkin.premiumDark=>-.25,
    AppSkin.glassmorphism=>.15,
    AppSkin.studentFriendly=>-.15,
    AppSkin.minimalAcademic=>-.30,
    AppSkin.elegantEditorial=>-.45,
    AppSkin.productivityDashboard=>-.20,
    AppSkin.friendlyModern=>-.20,
    AppSkin.futureTech=>-.20,
    AppSkin.boldPremium=>-.55,
    _=>-.15,
  };
  double get labelTracking => switch(skin){
    AppSkin.premiumDark=>1.15,
    AppSkin.glassmorphism=>1.55,
    AppSkin.studentFriendly=>.20,
    AppSkin.minimalAcademic=>1.05,
    AppSkin.elegantEditorial=>.75,
    AppSkin.productivityDashboard=>.65,
    AppSkin.friendlyModern=>.10,
    AppSkin.futureTech=>.30,
    AppSkin.boldPremium=>1.10,
    _=>.35,
  };
  double get headingHeight => switch(skin){
    AppSkin.elegantEditorial=>1.05,
    AppSkin.boldPremium=>.98,
    AppSkin.futureTech=>1.02,
    _=>1.12,
  };
  String get shellTagline => switch(skin){
    AppSkin.smartCampus=>'Smarter tools · brighter results',
    AppSkin.premiumDark=>'Discipline · consistency · results',
    AppSkin.glassmorphism=>'Your academic companion',
    AppSkin.studentFriendly=>'Same students · bigger possibilities',
    AppSkin.minimalAcademic=>'Learn · track · prepare · succeed',
    AppSkin.elegantEditorial=>'A brighter you, always',
    AppSkin.productivityDashboard=>'Study smarter · stay organised',
    AppSkin.friendlyModern=>'Support · learn · prepare · succeed',
    AppSkin.futureTech=>'STUDY · TRACK · PLAN · SUCCEED',
    AppSkin.boldPremium=>'STUDENTS · SUPPORT · SUCCESS',
    _=>'Your academic companion',
  };
  String get studyHeadline => switch(skin){
    AppSkin.smartCampus=>'Learn. Practise. Excel.',
    AppSkin.premiumDark=>'Prepare smart. Perform better.',
    AppSkin.glassmorphism=>'Study smart. Pass confidently.',
    AppSkin.studentFriendly=>'Everything you need to excel.',
    AppSkin.minimalAcademic=>'Organise. Study. Excel.',
    AppSkin.elegantEditorial=>'Prepare smarter. Do better.',
    AppSkin.productivityDashboard=>'Learn today. A brighter tomorrow.',
    AppSkin.friendlyModern=>'Knowledge today, a brighter tomorrow.',
    AppSkin.futureTech=>'Everything you need to excel',
    AppSkin.boldPremium=>'Learn · Prepare · Excel',
    _=>'Learn smart. Study confidently.',
  };
  String get toolsSubtitle => switch(skin){
    AppSkin.smartCampus=>'Smart tools for a smoother academic journey.',
    AppSkin.premiumDark=>'Powerful tools for a smoother NOUN journey.',
    AppSkin.glassmorphism=>'Useful shortcuts for every stage of your semester.',
    AppSkin.studentFriendly=>'Essential tools for every NOUN student.',
    AppSkin.minimalAcademic=>'Essential tools for your NOUN journey.',
    AppSkin.elegantEditorial=>'A considered collection of academic utilities.',
    AppSkin.productivityDashboard=>'Plan, check, calculate and keep moving.',
    AppSkin.friendlyModern=>'Smart tools for a smoother NOUN journey.',
    AppSkin.futureTech=>'Helpful utilities for NOUN students',
    AppSkin.boldPremium=>'More tools. A smoother NOUN experience.',
    _=>'Useful shortcuts for every stage of your semester.',
  };

  String get backdropAsset => 'assets/images/skins/${switch(skin){
    AppSkin.smartCampus||AppSkin.productivityDashboard=>'campus',
    AppSkin.studentFriendly||AppSkin.friendlyModern=>'students',
    AppSkin.futureTech=>'future-tech-campus',
    AppSkin.premiumDark||AppSkin.glassmorphism||AppSkin.minimalAcademic||AppSkin.elegantEditorial=>'study',
    AppSkin.boldPremium=>'bold-premium-welcome',
    _=>'campus',
  }}.webp';
  String get heroAsset => 'assets/images/skins/${switch(skin){
    AppSkin.studentFriendly||AppSkin.friendlyModern=>'students',
    AppSkin.premiumDark||AppSkin.glassmorphism||AppSkin.minimalAcademic||AppSkin.elegantEditorial||AppSkin.futureTech=>'study',
    AppSkin.boldPremium=>'bold-premium-welcome',
    _=>'campus',
  }}.webp';
  String get loginAsset => 'assets/images/skins/${switch(skin){
    AppSkin.studentFriendly||AppSkin.friendlyModern=>'students',
    AppSkin.futureTech=>'future-tech-campus',
    AppSkin.premiumDark||AppSkin.glassmorphism||AppSkin.minimalAcademic||AppSkin.elegantEditorial=>'study',
    AppSkin.boldPremium=>'bold-premium-welcome',
    _=>'campus',
  }}.webp';
  bool get resourceList => [AppSkin.smartCampus,AppSkin.premiumDark,AppSkin.minimalAcademic,AppSkin.futureTech].contains(skin);

  static SkinTokens of(BuildContext context) => Theme.of(context).extension<SkinTokens>() ??
      forSkin(AppSkin.defaultNoun, Theme.of(context).brightness);
  static SkinTokens forSkin(AppSkin skin, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final palette=switch(skin){
      AppSkin.smartCampus => dark ? [0xff0b2018,0xff16382a,0xff9bddb9,0xffffd778] : [0xfff0f6f2,0xffffffff,0xff005638,0xff805d00],
      AppSkin.premiumDark => dark ? [0xff030e0b,0xff10221d,0xffffd677,0xff7be0b0] : [0xfff3eedf,0xfffffcf3,0xff064331,0xff765500],
      AppSkin.glassmorphism => dark ? [0xff092b25,0xff21473f,0xffb7f7d9,0xffffdc87] : [0xffdceee6,0xffedf8f2,0xff005642,0xff755400],
      AppSkin.studentFriendly => dark ? [0xff14271e,0xff223f31,0xffa9eec3,0xffffd77e] : [0xfff9fcf4,0xffffffff,0xff096442,0xff875300],
      AppSkin.minimalAcademic => dark ? [0xff191e19,0xff252e26,0xffb6d3bb,0xffd8c89d] : [0xfff6f5ef,0xfffffefa,0xff234e38,0xff746345],
      AppSkin.elegantEditorial => dark ? [0xff0e2119,0xff193529,0xffb5dec2,0xffe3c581] : [0xfff7f4eb,0xfffffcf3,0xff005037,0xff8c6824],
      AppSkin.productivityDashboard => dark ? [0xff0b1e22,0xff183039,0xff93dbc3,0xff9ccfff] : [0xffeef4f6,0xffffffff,0xff005749,0xff265c83],
      AppSkin.friendlyModern => dark ? [0xff232a20,0xff343e2e,0xffc1e8ae,0xffefd29a] : [0xfff8f7eb,0xfffffef8,0xff37613f,0xff795826],
      AppSkin.futureTech => dark ? [0xff021710,0xff082c20,0xff5aefad,0xffffd858] : [0xffe7f8ef,0xfff6fff9,0xff005c3b,0xff746000],
      AppSkin.boldPremium => dark ? [0xff0c2018,0xff17352a,0xffa6dfbd,0xffffce62] : [0xfff5f8fa,0xffffffff,0xff00653d,0xff9c7410],
      AppSkin.defaultNoun => dark ? [0xff101715,0xff17201d,0xffa5dfbd,0xffffd979] : [0xfff8faf9,0xffffffff,0xff00553a,0xff795800],
    };
    final radius=switch(skin){AppSkin.minimalAcademic=>10.0,AppSkin.elegantEditorial=>8.0,AppSkin.friendlyModern=>26.0,AppSkin.studentFriendly=>22.0,AppSkin.productivityDashboard=>12.0,AppSkin.boldPremium=>14.0,AppSkin.futureTech=>12.0,_=>18.0};
    return SkinTokens(skin:skin,background:Color(palette[0]),surface:Color(palette[1]),primary:Color(palette[2]),gold:Color(palette[3]),ink:Color(dark?0xfff2f6ef:0xff132b23),radius:radius);
  }
  @override SkinTokens copyWith({AppSkin? skin, Color? background, Color? surface, Color? primary, Color? gold, Color? ink, double? radius}) =>
    SkinTokens(skin:skin??this.skin,background:background??this.background,surface:surface??this.surface,primary:primary??this.primary,gold:gold??this.gold,ink:ink??this.ink,radius:radius??this.radius);
  @override SkinTokens lerp(covariant SkinTokens? other,double t) => other == null ? this : SkinTokens(
    skin:t<.5?skin:other.skin,background:Color.lerp(background,other.background,t)!,surface:Color.lerp(surface,other.surface,t)!,primary:Color.lerp(primary,other.primary,t)!,gold:Color.lerp(gold,other.gold,t)!,ink:Color.lerp(ink,other.ink,t)!,radius:radius+(other.radius-radius)*t);
}

ThemeData buildSkinTheme(AppSkin skin, {Brightness brightness=Brightness.light, String? fontFamily='NUSans', Color accent=AppColours.green700}) {
  if(skin==AppSkin.defaultNoun)return buildAppTheme(brightness:brightness,fontFamily:fontFamily,accent:accent);
  final t=SkinTokens.forSkin(skin,brightness);
  final base=buildAppTheme(brightness:brightness,fontFamily:t.bodyFont,accent:accent);
  final scheme=ColorScheme.fromSeed(seedColor:t.primary,brightness:brightness).copyWith(
    primary:t.primary,onPrimary:t.primary.computeLuminance()>.18?const Color(0xff09281c):Colors.white,
    secondary:t.gold,onSecondary:t.gold.computeLuminance()>.18?const Color(0xff202311):Colors.white,
    surface:t.surface,onSurface:t.ink,surfaceContainerLow:t.surface,
    surfaceContainer:t.surface,surfaceContainerHigh:Color.lerp(t.surface,t.primary,.05),
    surfaceContainerHighest:Color.lerp(t.surface,t.primary,.10),
    primaryContainer:Color.lerp(t.surface,t.primary,.12),onPrimaryContainer:t.ink,
    secondaryContainer:Color.lerp(t.surface,t.gold,.13),onSecondaryContainer:t.ink,
    onSurfaceVariant:t.ink.withValues(alpha:.72),outline:t.primary.withValues(alpha:.45),outlineVariant:t.ink.withValues(alpha:.12));
  final body=base.textTheme.apply(fontFamily:t.bodyFont,fontFamilyFallback:t.fontFallback,bodyColor:t.ink,displayColor:t.ink);
  final text=body.copyWith(
    displayLarge:body.displayLarge?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.headingWeight,letterSpacing:t.headingTracking,height:t.headingHeight),
    displayMedium:body.displayMedium?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.headingWeight,letterSpacing:t.headingTracking,height:t.headingHeight),
    headlineLarge:body.headlineLarge?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.headingWeight,letterSpacing:t.headingTracking,height:t.headingHeight),
    headlineMedium:body.headlineMedium?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.headingWeight,letterSpacing:t.headingTracking,height:t.headingHeight),
    headlineSmall:body.headlineSmall?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.headingWeight,letterSpacing:t.headingTracking,height:t.headingHeight),
    titleLarge:body.titleLarge?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.titleWeight,letterSpacing:t.headingTracking),
    titleMedium:body.titleMedium?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.titleWeight),
    titleSmall:body.titleSmall?.copyWith(fontFamily:t.displayFont,fontFamilyFallback:t.fontFallback,fontWeight:t.titleWeight,height:1),
    labelLarge:body.labelLarge?.copyWith(fontFamily:t.bodyFont,fontFamilyFallback:t.fontFallback,fontWeight:FontWeight.w700,letterSpacing:t.labelTracking*.25,height:1),
    labelMedium:body.labelMedium?.copyWith(fontFamily:t.bodyFont,fontFamilyFallback:t.fontFallback,fontWeight:FontWeight.w700,letterSpacing:t.labelTracking*.18,height:1),
    labelSmall:body.labelSmall?.copyWith(fontFamily:t.bodyFont,fontFamilyFallback:t.fontFallback,letterSpacing:t.labelTracking*.18,height:t.skin == AppSkin.futureTech ? 0.90 : 1),
  );
  return base.copyWith(
    colorScheme:scheme,scaffoldBackgroundColor:t.background,extensions:[t],textTheme:text,
    cardTheme:base.cardTheme.copyWith(color:t.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(t.radius))),
    appBarTheme:base.appBarTheme.copyWith(titleTextStyle:text.titleLarge?.copyWith(color:base.appBarTheme.foregroundColor),toolbarTextStyle:text.bodyMedium?.copyWith(color:base.appBarTheme.foregroundColor)),
    navigationBarTheme:base.navigationBarTheme.copyWith(backgroundColor:t.surface,indicatorColor:scheme.secondaryContainer,labelTextStyle:WidgetStatePropertyAll(text.labelSmall)),
    inputDecorationTheme:base.inputDecorationTheme.copyWith(fillColor:t.surface,labelStyle:text.bodyMedium,hintStyle:text.bodyMedium?.copyWith(color:t.ink.withValues(alpha:.55)),
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(t.radius)),
      enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(t.radius),borderSide:BorderSide(color:scheme.outline)),
      focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(t.radius),borderSide:BorderSide(color:t.primary,width:1.5))),
    listTileTheme:base.listTileTheme.copyWith(textColor:t.ink,iconColor:t.primary,titleTextStyle:text.titleMedium?.copyWith(fontSize:14),subtitleTextStyle:text.bodySmall?.copyWith(color:scheme.onSurfaceVariant)),
    dialogTheme:DialogThemeData(backgroundColor:t.surface,surfaceTintColor:Colors.transparent,titleTextStyle:text.titleLarge,contentTextStyle:text.bodyMedium,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(t.radius))),
    popupMenuTheme:PopupMenuThemeData(color:t.surface,textStyle:text.bodyMedium,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(t.radius))),
    bottomSheetTheme:BottomSheetThemeData(backgroundColor:t.surface,modalBackgroundColor:t.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(t.radius)))),
    filledButtonTheme:FilledButtonThemeData(style:base.filledButtonTheme.style?.copyWith(textStyle:WidgetStatePropertyAll(text.labelLarge),shape:WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius:BorderRadius.circular(t.radius))))),
    outlinedButtonTheme:OutlinedButtonThemeData(style:base.outlinedButtonTheme.style?.copyWith(textStyle:WidgetStatePropertyAll(text.labelLarge),shape:WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius:BorderRadius.circular(t.radius))))),
    textButtonTheme:TextButtonThemeData(style:base.textButtonTheme.style?.copyWith(textStyle:WidgetStatePropertyAll(text.labelLarge))),
  );
}

/// Positional metric records are used throughout the Premium layout builders.
/// These getters keep the call sites expressive without allocating model objects.
extension PremiumMetricRecord on (String, String, IconData, Color) {
  String get label => $1;
  String get value => $2;
  IconData get icon => $3;
  Color get colour => $4;
}
