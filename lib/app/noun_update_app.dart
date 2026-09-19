import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../screens/live_portal.dart';

class NounUpdateApp extends StatelessWidget {
  const NounUpdateApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NOUN Update', debugShowCheckedModeBanner: false,
    theme: buildAppTheme(), home: const LivePortal(),
  );
}
