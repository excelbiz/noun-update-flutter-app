import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'skin_theme.dart';

/// The production design. Entitlements never affect this theme.
@immutable
class GreenGlass extends ThemeExtension<GreenGlass> {
  const GreenGlass(this.top, this.bottom, this.highlight);
  final Color top, bottom, highlight;

  static GreenGlass? of(BuildContext context) =>
      Theme.of(context).extension<GreenGlass>();

  @override
  GreenGlass copyWith({Color? top, Color? bottom, Color? highlight}) =>
      GreenGlass(top ?? this.top, bottom ?? this.bottom, highlight ?? this.highlight);

  @override
  GreenGlass lerp(covariant GreenGlass? other, double t) => other == null
      ? this
      : GreenGlass(Color.lerp(top, other.top, t)!, Color.lerp(bottom, other.bottom, t)!,
          Color.lerp(highlight, other.highlight, t)!);
}

ThemeData buildGreenGlass({Brightness brightness = Brightness.light, String? fontFamily = 'NUSans'}) {
  final dark = brightness == Brightness.dark;
  final base = buildAppTheme(brightness: brightness, fontFamily: fontFamily);
  final primary = Color(dark ? 0xff67e88e : 0xff006341);
  final background = Color(dark ? 0xff041811 : 0xfff8fdfa);
  final surface = Color(dark ? 0xff0c2b20 : 0xfffcfffe);
  final ink = Color(dark ? 0xffedf9f0 : 0xff10291e);
  final border = Color(dark ? 0xff285241 : 0xffcce5d7);
  final tint = Color(dark ? 0xff194831 : 0xffdff5e7);
  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
    primary: primary, onPrimary: dark ? const Color(0xff032215) : Colors.white,
    primaryContainer: tint, onPrimaryContainer: ink,
    surface: surface, surfaceContainerLow: surface,
    surfaceContainer: dark ? const Color(0xff103626) : const Color(0xffeef8f1),
    onSurface: ink, onSurfaceVariant: Color(dark ? 0xffadd1bf : 0xff3c5a4b),
    outlineVariant: border,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    extensions: [
      GreenGlass(background, Color(dark ? 0xff092b1e : 0xffeaf8f0), tint),
      SkinTokens(skin: AppSkin.defaultNoun, background: background, surface: surface,
        primary: primary, gold: Color(dark ? 0xffffd45e : 0xff785600), ink: ink, radius: 15),
    ],
    appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: ink,
      titleTextStyle: base.textTheme.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800, fontSize: 17),
      centerTitle: true, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent),
    navigationBarTheme: base.navigationBarTheme.copyWith(backgroundColor: surface,
      indicatorColor: tint, surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
        color: states.contains(WidgetState.selected) ? primary : scheme.onSurfaceVariant))),
    cardTheme: CardThemeData(color: surface, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: border))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: scheme.surfaceContainer,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: primary, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: const Color(0xff00713d), foregroundColor: Colors.white,
      minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    dialogTheme: DialogThemeData(backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22)))),
  );
}
