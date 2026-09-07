import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../repositories/app_repository.dart';
import '../screens/app_shell.dart';
import '../widgets/shared_widgets.dart';

class NounUpdateApp extends StatefulWidget {
  const NounUpdateApp({super.key});

  @override
  State<NounUpdateApp> createState() => _NounUpdateAppState();
}

class _NounUpdateAppState extends State<NounUpdateApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController(HybridAppRepository())..initialise();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NOUN Update',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.isLoading) return const _SplashScreen();
            if (controller.bootstrap == null) {
              return _LoadErrorScreen(
                message: controller.loadError ?? 'Unable to load the app.',
                onRetry: controller.initialise,
              );
            }
            return AppShell(controller: controller);
          },
        ),
      );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColours.green900,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(onDark: true),
                SizedBox(height: 22),
                Text(
                  'Information. Resources. Success.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: AppColours.green500,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LoadErrorScreen extends StatelessWidget {
  const _LoadErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 62,
                  color: AppColours.green700,
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
}
