import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'skin_theme.dart';

/// Entitlement is never restored from a local boolean. Each session verifies with the server.
class PremiumService extends ChangeNotifier {
  static final instance=PremiumService();
  Map<String,dynamic> _entitlement={},preferences={};
  String? accountId;
  String? error;
  DateTime? lastVerifiedAt;
  Timer? _expiry;
  int _generation=0;
  bool get isPremium=>_entitlement['active']==true;
  bool allows(String feature)=>isPremium && (_entitlement['features'] as Map?)?[feature]==true;
  bool get suppressAds=>isPremium; // Never request ad inventory for active Premium.
  String? get currentPlan=>_entitlement['plan'] as String?;
  AppSkin get preferredSkin=>AppSkin.values.firstWhere((s)=>s.name==preferences['preferred_skin'],orElse:()=>AppSkin.defaultNoun);
  AppSkin get effectiveSkin=>allows('premium_skins')?preferredSkin:AppSkin.defaultNoun;
  String get preferredProfileFrame=>'${preferences['profile_frame']??'classic'}';
  String get effectiveProfileFrame=>allows('profile_frames')?preferredProfileFrame:'classic';
  Map<String,dynamic> get birthday=>Map<String,dynamic>.from(preferences['birthday'] as Map? ?? {});
  void clear(){_generation++;_expiry?.cancel();accountId=null;_entitlement={};preferences={};lastVerifiedAt=null;error=null;notifyListeners();}
  Future<void> refresh(ApiClient api,String id) async {
    if(accountId!=id){clear();accountId=id;}
    final generation=++_generation;
    try {
      final responses=await Future.wait([api.getJson('/premium/status'),api.getJson('/profile/preferences')]);
      if(generation!=_generation)return;
      final e=Map<String,dynamic>.from(responses[0]['data'] as Map);
      final server=DateTime.tryParse('${e['server_time']}');
      final expires=DateTime.tryParse('${e['expires_at']}');
      final remaining=server==null||expires==null?Duration.zero:expires.difference(server);
      _entitlement={...e,'active':e['active']==true&&remaining>Duration.zero};
      preferences=Map<String,dynamic>.from(responses[1]['data'] as Map);
      lastVerifiedAt=DateTime.now();error=null;_expiry?.cancel();
      if(isPremium)_expiry=Timer(remaining,(){_entitlement={..._entitlement,'active':false};notifyListeners();});
      notifyListeners();
    } catch (_) {
      if(generation!=_generation)return;
      _expiry?.cancel();_entitlement={};error='Account personalisation could not be verified. Please reconnect and refresh.';notifyListeners();
    }
  }
  Future<void> save(ApiClient api,Map<String,dynamic> patch)async{
    if(accountId==null)throw const ApiException('Sign in to save your preferences.');
    final generation=_generation;
    final r=await api.postJson('/profile/preferences',patch);
    if(generation!=_generation)return;
    preferences=Map<String,dynamic>.from(r['data'] as Map);notifyListeners();
  }
  bool isBirthday(DateTime local)=>accountId!=null&&birthday['celebration_enabled']==true&&birthday['month']==local.month&&birthday['day']==local.day;
  @override void dispose(){_expiry?.cancel();super.dispose();}
}
