import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'notification_service.dart';

class NotificationPreferences extends ChangeNotifier {
  NotificationPreferences({required this.api, required this.userId});

  final ApiClient api;
  final String? userId;

  bool enabled = true;
  bool tmas = true;
  bool exams = true;
  bool results = true;
  bool fees = true;
  bool general = true;
  bool syncPending = false;
  bool loading = false;
  Object? error;

  bool get signedIn => userId != null && userId!.trim().isNotEmpty;
  String get storageKey => 'nu-notification-preferences-${userId ?? 'guest'}';

  Map<String, dynamic> get payload => {
        'notifications_enabled': enabled,
        'notify_tmas': tmas,
        'notify_exams': exams,
        'notify_results': results,
        'notify_fees': fees,
        'notify_general': general,
      };

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    await _loadLocal();
    if (signedIn) {
      try {
        await sync();
      } catch (e) {
        error = e;
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> sync() async {
    if (!signedIn) return;
    final response = await api.getJson('/profile/settings');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final remote = Map<String, dynamic>.from(data['settings'] as Map);
    if (syncPending || data['exists'] != true) {
      final saved = await api.postJson('/profile/settings', {'settings': payload});
      final savedData = Map<String, dynamic>.from(saved['data'] as Map);
      _apply(Map<String, dynamic>.from(savedData['settings'] as Map));
      syncPending = false;
    } else {
      _apply(remote);
    }
    error = null;
    await _persist();
    await NotificationService.loginStudent(userId!);
    await NotificationService.applyPreferences(payload);
    notifyListeners();
  }

  Future<void> change({
    bool? enabled,
    bool? tmas,
    bool? exams,
    bool? results,
    bool? fees,
    bool? general,
  }) async {
    this.enabled = enabled ?? this.enabled;
    this.tmas = tmas ?? this.tmas;
    this.exams = exams ?? this.exams;
    this.results = results ?? this.results;
    this.fees = fees ?? this.fees;
    this.general = general ?? this.general;
    error = null;
    syncPending = signedIn;
    await _persist();
    notifyListeners();
    if (!signedIn) return;
    try {
      final saved = await api.postJson('/profile/settings', {'settings': payload});
      final data = Map<String, dynamic>.from(saved['data'] as Map);
      _apply(Map<String, dynamic>.from(data['settings'] as Map));
      syncPending = false;
      await _persist();
      await NotificationService.loginStudent(userId!);
      await NotificationService.applyPreferences(payload);
      notifyListeners();
    } catch (e) {
      error = e;
      syncPending = true;
      await _persist();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadLocal() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(storageKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is! Map) return;
      _apply(Map<String, dynamic>.from(data));
      syncPending = data['sync_pending'] == true;
    } catch (_) {
      enabled = true;
      tmas = true;
      exams = true;
      results = true;
      fees = true;
      general = true;
      syncPending = false;
    }
  }

  void _apply(Map<String, dynamic> data) {
    enabled = data['notifications_enabled'] is bool ? data['notifications_enabled'] as bool : true;
    tmas = data['notify_tmas'] is bool ? data['notify_tmas'] as bool : true;
    exams = data['notify_exams'] is bool ? data['notify_exams'] as bool : true;
    results = data['notify_results'] is bool ? data['notify_results'] as bool : true;
    fees = data['notify_fees'] is bool ? data['notify_fees'] as bool : true;
    general = data['notify_general'] is bool ? data['notify_general'] as bool : true;
  }

  Future<void> _persist() async {
    final ok = await (await SharedPreferences.getInstance()).setString(
      storageKey,
      jsonEncode({...payload, 'sync_pending': syncPending}),
    );
    if (!ok) throw StateError('Notification preferences could not be saved on this device.');
  }
}
