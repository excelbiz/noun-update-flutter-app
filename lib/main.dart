import 'package:flutter/material.dart';

import 'app/noun_update_app.dart';
import 'core/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.initialise();
  runApp(const NounUpdateApp());
}
