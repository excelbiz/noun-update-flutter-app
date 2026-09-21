import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/appearance.dart';
import '../screens/live_portal.dart';

class NounUpdateApp extends StatelessWidget {
  const NounUpdateApp({super.key,this.home});
  final Widget? home;
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable:Appearance.instance,builder:(context,_)=>MaterialApp(
    title: 'NOUN Update', debugShowCheckedModeBanner: false,
    theme: buildAppTheme(fontFamily:Appearance.instance.family,accent:Appearance.instance.colour),
    darkTheme:buildAppTheme(brightness:Brightness.dark,fontFamily:Appearance.instance.family,accent:Appearance.instance.colour),
    themeMode:Appearance.instance.mode,home: home??const LivePortal(),
  ));
}
