import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'app_config.dart';

class NotificationService {
  const NotificationService._();

  static void initialise() {
    if (AppConfig.oneSignalAppId.isEmpty) return;
    OneSignal.initialize(AppConfig.oneSignalAppId);
  }

  static Future<bool> requestPermission() async {
    if (AppConfig.oneSignalAppId.isEmpty) return false;
    return OneSignal.Notifications.requestPermission(true);
  }

  static Future<void> loginStudent(String studentId) async {
    if (AppConfig.oneSignalAppId.isEmpty) return;
    OneSignal.login(studentId);
  }

  static Future<void> logoutStudent() async {
    if (AppConfig.oneSignalAppId.isEmpty) return;
    OneSignal.logout();
  }
}

