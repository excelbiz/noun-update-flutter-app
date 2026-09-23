import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/appearance.dart';
import '../screens/live_portal.dart';

class NounUpdateApp extends StatefulWidget {
  const NounUpdateApp({super.key, this.home});
  final Widget? home;
  @override
  State<NounUpdateApp> createState() => _NounUpdateAppState();
}

class _NounUpdateAppState extends State<NounUpdateApp> with WidgetsBindingObserver {
  Timer? _timer;
  ThemeMode get _mode => Appearance.instance.effectiveMode(DateTime.now());
  late ThemeMode _lastMode;
  @override
  void initState() {
    super.initState();
    _lastMode = _mode;
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }
  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    // Re-evaluate at the next local minute, including clock/timezone changes.
    _timer = Timer(Duration(milliseconds: 60000 - now.second * 1000 - now.millisecond), () {
      if (!mounted) return;
      _refresh();
      _schedule();
    });
  }
  void _refresh() {
    if (_lastMode != _mode) setState(() => _lastMode = _mode);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _schedule();
    } else {
      _timer?.cancel();
    }
  }
  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Appearance.instance,
    builder: (context, _) {
      final a = Appearance.instance;
      _lastMode = _mode;
      return MaterialApp(
        title: 'NOUN Update', debugShowCheckedModeBanner: false,
        theme: buildAppTheme(fontFamily: a.family, accent: a.colour),
        darkTheme: buildAppTheme(brightness: Brightness.dark, fontFamily: a.family, accent: a.colour),
        themeMode: _mode,
        themeAnimationDuration: WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations
            ? Duration.zero : const Duration(milliseconds: 200),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: _PreferredTextScaler(media.textScaler, a.textScale)),
            child: child!,
          );
        },
        home: widget.home ?? const LivePortal(),
      );
    },
  );
}

// Preserve OS accessibility scaling, including nonlinear scaling.
class _PreferredTextScaler extends TextScaler {
  const _PreferredTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;
  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;
  @override
  double get textScaleFactor => system.scale(14) / 14 * factor;
}
