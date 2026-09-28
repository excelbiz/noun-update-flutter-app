import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'notification_service.dart';

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
  bool dataSaver = false;
  bool accountSyncPending = false;
  String? get family => fonts[font]!.isEmpty ? null : fonts[font];
  Color get colour => accents[accent]!;

  Map<String,dynamic> get accountSettings => {
    'automatic': automatic,
    'mode': mode.name,
    'text_size': textSize,
    'font': font,
    'accent': accent,
    'data_saver': dataSaver,
  };

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(storageKey);
      final value = raw == null ? <String,dynamic>{} : jsonDecode(raw) as Map;
      mode = ThemeMode.values.firstWhere((m) => m.name == value['mode'], orElse: () => ThemeMode.system);
      automatic = value['automatic'] is bool ? value['automatic'] as bool : !value.containsKey('mode');
      textSize = textSizes.containsKey(value['textSize']) ? value['textSize'] as String : 'Default';
      font = fonts.containsKey(value['font']) ? value['font'] as String : 'Modern sans';
      accent = accents.containsKey(value['accent']) ? value['accent'] as String : 'Emerald';
      dataSaver = value['dataSaver'] == true;
      accountSyncPending = value['accountSyncPending'] == true;
    } catch (_) { mode=ThemeMode.system; automatic=true; textSize='Default'; font='Modern sans'; accent='Emerald'; dataSaver=false; accountSyncPending=false; }
    notifyListeners();
  }

  Future<void> _persist() async {
    final ok=await (await SharedPreferences.getInstance()).setString(storageKey,jsonEncode({
      'automatic':automatic,'textSize':textSize,'mode':mode.name,'font':font,'accent':accent,
      'dataSaver':dataSaver,'accountSyncPending':accountSyncPending,
    }));
    if(!ok)throw StateError('Your preference could not be saved. Please try again.');
  }

  Future<void> sync(ApiClient api) async {
    if(!await api.hasSession())return;
    final response=await api.getJson('/profile/settings');
    final data=Map<String,dynamic>.from(response['data'] as Map);
    final exists=data['exists']==true;
    Map<String,dynamic> serverSettings;
    if(!exists||accountSyncPending){
      final saved=await api.postJson('/profile/settings',{'settings':accountSettings});
      final savedData=Map<String,dynamic>.from(saved['data'] as Map);
      serverSettings=Map<String,dynamic>.from(savedData['settings'] as Map);
    }else{
      serverSettings=Map<String,dynamic>.from(data['settings'] as Map);
    }
    _applyServer(serverSettings);
    accountSyncPending=false;
    await _persist();
    notifyListeners();
    // The account-settings payload also contains notification category choices.
    // Reuse it rather than issuing a second network request during sign-in.
    try{await NotificationService.applyPreferences(serverSettings);}catch(_){/* Notification SDK failure must not block account settings. */}
  }

  void _applyServer(Map<String,dynamic> value) {
    mode=ThemeMode.values.firstWhere((m)=>m.name==value['mode'],orElse:()=>ThemeMode.system);
    automatic=value['automatic'] is bool?value['automatic'] as bool:true;
    textSize=textSizes.containsKey(value['text_size'])?value['text_size'] as String:'Default';
    font=fonts.containsKey(value['font'])?value['font'] as String:'Modern sans';
    accent=accents.containsKey(value['accent'])?value['accent'] as String:'Emerald';
    dataSaver=value['data_saver']==true;
  }

  Future<void> change({ThemeMode? mode, String? font, String? accent, bool? automatic, String? textSize, bool? dataSaver, ApiClient? api}) async {
    final nextAutomatic = automatic ?? (mode != null ? false : this.automatic);
    final nextTextSize = textSize ?? this.textSize;
    if (!textSizes.containsKey(nextTextSize)) throw ArgumentError('Unknown text size');
    final nextMode=mode??this.mode, nextFont=font??this.font, nextAccent=accent??this.accent, nextDataSaver=dataSaver??this.dataSaver;
    if(!fonts.containsKey(nextFont)||!accents.containsKey(nextAccent))throw ArgumentError('Unknown appearance option');
    this.automatic=nextAutomatic;this.textSize=nextTextSize;this.mode=nextMode;this.font=nextFont;this.accent=nextAccent;this.dataSaver=nextDataSaver;
    final signedIn=api!=null&&await api.hasSession();
    accountSyncPending=signedIn;
    await _persist();notifyListeners();
    if(!signedIn)return;
    try{
      final saved=await api.postJson('/profile/settings',{'settings':accountSettings});
      final data=Map<String,dynamic>.from(saved['data'] as Map);
      final serverSettings=Map<String,dynamic>.from(data['settings'] as Map);
      _applyServer(serverSettings);
      accountSyncPending=false;await _persist();notifyListeners();
      try{await NotificationService.applyPreferences(serverSettings);}catch(_){/* Keep appearance save successful even if push tags fail. */}
    }catch(_){
      accountSyncPending=true;await _persist();notifyListeners();rethrow;
    }
  }
}
