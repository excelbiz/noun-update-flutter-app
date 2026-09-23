import 'package:flutter/material.dart';

class AppColours {
  const AppColours._();

  static const green900 = Color(0xFF003E2F);
  static const green800 = Color(0xFF005A3F);
  static const green700 = Color(0xFF007A4D);
  static const green600 = Color(0xFF009B58);
  static const green500 = Color(0xFF00B768);
  static const mint = Color(0xFFE8F7EE);
  static const ink = Color(0xFF15211C);
  static const muted = Color(0xFF66736D);
  static const surface = Color(0xFFF6F8F7);
  static const warning = Color(0xFFF2A93B);
  static const danger = Color(0xFFD64545);
}

ThemeData buildAppTheme({Brightness brightness=Brightness.light, String? fontFamily='NUSans', Color accent=AppColours.green700}) {
  final dark=brightness==Brightness.dark;
  final scheme=ColorScheme.fromSeed(seedColor:accent,brightness:brightness);
  final base=ThemeData(useMaterial3:true,colorScheme:scheme,fontFamily:fontFamily);
  return base.copyWith(
    scaffoldBackgroundColor:dark?const Color(0xff101715):const Color(0xfff8faf9),
    textTheme:base.textTheme.copyWith(
      headlineLarge:base.textTheme.headlineLarge?.copyWith(fontSize:30,fontWeight:FontWeight.w700),
      headlineMedium:base.textTheme.headlineMedium?.copyWith(fontSize:24,fontWeight:FontWeight.w700),
      titleLarge:base.textTheme.titleLarge?.copyWith(fontSize:20,fontWeight:FontWeight.w700),
      titleMedium:base.textTheme.titleMedium?.copyWith(fontSize:15,fontWeight:FontWeight.w700),
      bodyLarge:base.textTheme.bodyLarge?.copyWith(height:1.45),
      bodyMedium:base.textTheme.bodyMedium?.copyWith(height:1.4),
    ),
    appBarTheme:AppBarTheme(backgroundColor:dark?const Color(0xff17201d):AppColours.green900,foregroundColor:Colors.white,elevation:0,centerTitle:false),
    cardTheme:CardThemeData(elevation:0,color:scheme.surfaceContainerLow,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
    inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:scheme.surfaceContainerLow,hintStyle:TextStyle(color:scheme.onSurfaceVariant),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:scheme.outlineVariant)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:scheme.primary,width:1.5))),
    filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(minimumSize:const Size(0,48),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),textStyle:base.textTheme.labelLarge?.copyWith(fontWeight:FontWeight.w700))),
    navigationBarTheme:NavigationBarThemeData(backgroundColor:scheme.surface,indicatorColor:scheme.secondaryContainer,labelTextStyle:WidgetStatePropertyAll(base.textTheme.labelSmall?.copyWith(fontSize:11,fontWeight:FontWeight.w700,color:scheme.onSurface))),
  );
}
