import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appearance extends ChangeNotifier {
  static final instance = Appearance();
  static const storageKey = 'nu-appearance-v1';
  static const fonts = {'Modern sans': 'NUSans', 'Classic serif': 'NUReading', 'Device font': ''};
  static const accents = {'Emerald': Color(0xff006341), 'Ocean': Color(0xff245caa), 'Plum': Color(0xff784080), 'Terracotta': Color(0xff99502e)};
  ThemeMode mode = ThemeMode.system;
  bool automatic = true;
  static const textSizes = {'Small': 0.9, 'Default': 1.0, 'Large': 1.15, 'Extra Large': 1.3};
  String textSize = 'Default';
  double get textScale => textSizes[textSize]!;
  ThemeMode effectiveMode(DateTime localTime) => automatic
      ? (localTime.hour >= 6 && localTime.hour < 19 ? ThemeMode.light : ThemeMode.dark)
      : mode;
  String font = 'Modern sans', accent = 'Emerald';
  String? get family => fonts[font]!.isEmpty ? null : fonts[font];
  Color get colour => accents[accent]!;
  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(storageKey);
      final value = raw == null ? <String,dynamic>{} : jsonDecode(raw) as Map;
      mode = ThemeMode.values.firstWhere((m) => m.name == value['mode'], orElse: () => ThemeMode.system);
      automatic = value['automatic'] is bool ? value['automatic'] as bool : !value.containsKey('mode');
      textSize = textSizes.containsKey(value['textSize']) ? value['textSize'] as String : 'Default';
      font = fonts.containsKey(value['font']) ? value['font'] as String : 'Modern sans';
      accent = accents.containsKey(value['accent']) ? value['accent'] as String : 'Emerald';
    } catch (_) { mode=ThemeMode.system; automatic=true; textSize='Default'; font='Modern sans'; accent='Emerald'; }
    notifyListeners();
  }
  Future<void> change({ThemeMode? mode, String? font, String? accent, bool? automatic, String? textSize}) async {
    final nextAutomatic = automatic ?? (mode != null ? false : this.automatic);
    final nextTextSize = textSize ?? this.textSize;
    if (!textSizes.containsKey(nextTextSize)) throw ArgumentError('Unknown text size');
    final nextMode=mode??this.mode, nextFont=font??this.font, nextAccent=accent??this.accent;
    if(!fonts.containsKey(nextFont)||!accents.containsKey(nextAccent))throw ArgumentError('Unknown appearance option');
    final ok=await (await SharedPreferences.getInstance()).setString(storageKey,jsonEncode({'automatic':nextAutomatic,'textSize':nextTextSize,'mode':nextMode.name,'font':nextFont,'accent':nextAccent}));
    if(!ok)throw StateError('Your preference could not be saved. Please try again.');
    this.automatic=nextAutomatic;this.textSize=nextTextSize;this.mode=nextMode;this.font=nextFont;this.accent=nextAccent;notifyListeners();
  }
}
