import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/appearance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('New installs use local daytime and night boundaries', () async {
    SharedPreferences.setMockInitialValues({});
    final a = Appearance();
    await a.load();
    expect(a.automatic, isTrue);
    for (final hour in [0, 5, 19, 23]) {
      expect(a.effectiveMode(DateTime(2026, 9, 22, hour, 59)), ThemeMode.dark);
    }
    for (final hour in [6, 12, 18]) {
      expect(a.effectiveMode(DateTime(2026, 9, 22, hour)), ThemeMode.light);
    }
    a.dispose();
  });
  test('Manual choice overrides clock and all preferences persist', () async {
    SharedPreferences.setMockInitialValues({});
    final a = Appearance();
    await a.change(mode: ThemeMode.light, textSize: 'Extra Large');
    expect(a.effectiveMode(DateTime(2026, 9, 22, 23)), ThemeMode.light);
    final b = Appearance();
    await b.load();
    expect(b.automatic, isFalse);
    expect(b.textScale, 1.3);
    await b.change(automatic: true);
    expect(b.effectiveMode(DateTime(2026, 9, 22, 23)), ThemeMode.dark);
    await b.change(mode: ThemeMode.system);
    expect(b.effectiveMode(DateTime(2026, 9, 22, 23)), ThemeMode.system);
    a.dispose(); b.dispose();
  });
  test('Existing theme preference is preserved during upgrade', () async {
    SharedPreferences.setMockInitialValues({Appearance.storageKey: jsonEncode({'mode':'dark','font':'Classic serif','accent':'Ocean'})});
    final a = Appearance(); await a.load();
    expect(a.automatic, isFalse);
    expect(a.mode, ThemeMode.dark);
    expect(a.font, 'Classic serif');
    expect(a.textSize, 'Default');
    a.dispose();
  });
}
