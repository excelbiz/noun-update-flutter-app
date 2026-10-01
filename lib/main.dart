import 'package:flutter/material.dart';

import 'app/noun_update_app.dart';
import 'core/notification_service.dart';
import 'core/appearance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Appearance.instance.load();
  NotificationService.initialise();
  runApp(const NounUpdateApp());
}

