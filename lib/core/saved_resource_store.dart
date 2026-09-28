import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class SavedResourceStore {
  SavedResourceStore({required this.api,this.userId});
  final ApiClient api;
  final String? userId;
  final Map<String,Map<String,dynamic>> items={};
  final Map<String,Map<String,dynamic>> pending={};
  bool get signedIn=>userId!=null&&userId!.trim().isNotEmpty;
  String get slot=>'nu-saved-resources-${userId??'guest'}';

  Map<String,dynamic> _data(Map<String,dynamic> response)=>
      Map<String,dynamic>.from(response['data'] as Map? ?? const {});

  List<Map<String,dynamic>> _records(dynamic value)=>[
    for(final item in value is List?value:const [])
      if(item is Map)Map<String,dynamic>.from(item),
  ];

  Future<void> load()async{
    await _loadLocal();
    if(!signedIn)return;
    try{
      final data=_data(await api.getJson('/saved-resources'));
      items
        ..clear()
        ..addEntries(_records(data['items']).map((item)=>MapEntry('${item['resource_key']}',item)));
      _applyPending();
      await _syncPending();
      await _persist();
    }catch(_){/* Offline: retain local state and pending operations. */}
  }

  bool contains(String key)=>items.containsKey(key);
  List<Map<String,dynamic>> get all=>items.values.toList()
    ..sort((a,b)=>'${b['saved_at']??''}'.compareTo('${a['saved_at']??''}'));

  Future<void> setSaved(Map<String,dynamic> resource,bool saved)async{
    final key='${resource['resource_key']??''}'.trim();
    if(key.isEmpty)throw ArgumentError('resource_key is required');
    final body=<String,dynamic>{
      'resource_key':key,
      'saved':saved,
      if(saved)'resource_type':'${resource['resource_type']??'resource'}',
      if(saved)'title':'${resource['title']??key}',
      if(saved&&resource['course_code']!=null)'course_code':resource['course_code'],
      if(saved&&resource['route']!=null)'route':resource['route'],
    };
    if(saved){items[key]={...resource,...body,'saved_at':DateTime.now().toUtc().toIso8601String()};}else{items.remove(key);}
    if(signedIn)pending[key]=body;
    await _persist();
    if(signedIn)await _syncOne(key);
  }

  Future<void> _syncPending()async{
    for(final key in List<String>.from(pending.keys)){await _syncOne(key);}
  }

  Future<void> _syncOne(String key)async{
    final body=pending[key];if(body==null)return;
    try{
      final data=_data(await api.postJson('/saved-resources',body));
      if(data['saved']==true){items[key]=Map<String,dynamic>.from(data);}else{items.remove(key);}
      pending.remove(key);
      await _persist();
    }catch(_){/* Leave queued for the next load/save. */}
  }

  void _applyPending(){
    for(final entry in pending.entries){
      final body=entry.value;
      if(body['saved']==true){
        final existing=items[entry.key]??const <String,dynamic>{};
        items[entry.key]={...existing,...body};
      }else{
        items.remove(entry.key);
      }
    }
  }

  Future<void> _loadLocal()async{
    try{
      final raw=(await SharedPreferences.getInstance()).getString(slot);if(raw==null)return;
      final data=jsonDecode(raw) as Map;
      for(final item in _records(data['items'])){items['${item['resource_key']}']=item;}
      for(final item in _records(data['pending'])){pending['${item['resource_key']}']=item;}
    }catch(_){items.clear();pending.clear();}
  }

  Future<void> _persist()async{
    final ok=await (await SharedPreferences.getInstance()).setString(slot,jsonEncode({'items':items.values.toList(),'pending':pending.values.toList()}));
    if(!ok)throw StateError('Could not save bookmarks on this device.');
  }
}