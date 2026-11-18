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

  static Future<void> applyPreferences(Map<String, dynamic> preferences) async {
    if (AppConfig.oneSignalAppId.isEmpty) return;
    String flag(String key, {bool fallback = true}) =>
        (preferences[key] is bool ? preferences[key] as bool : fallback) ? '1' : '0';
    final enabled = flag('notifications_enabled');
    await OneSignal.User.addTags({
      'nu_notifications': enabled,
      'nu_notify_tmas': flag('notify_tmas'),
      'nu_notify_exams': flag('notify_exams'),
      'nu_notify_results': flag('notify_results'),
      'nu_notify_fees': flag('notify_fees'),
      'nu_notify_general': flag('notify_general'),
    });
  }

  static Future<void> logoutStudent() async {
    if (AppConfig.oneSignalAppId.isEmpty) return;
    OneSignal.logout();
  }
}
