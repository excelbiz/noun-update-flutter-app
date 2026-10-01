import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/academic_period.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/core/premium_service.dart';
import 'package:noun_update_student_app/screens/live_portal.dart';

class _BootstrapApi extends ApiClient {
  int workspaceGets=0;

  static const settings=<String,dynamic>{
    'automatic':true,
    'mode':'system',
    'text_size':'Default',
    'font':'Modern sans',
    'accent':'Emerald',
    'data_saver':false,
  };

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<Map<String,dynamic>> getJson(String path) async {
    final period=AcademicPeriod.forDate(DateTime.now());
    if(path=='/app/bootstrap')return {'data':{
      'profile':{'id':42,'name':'Chemistry Student','email':'chemistry@example.test'},
      'wallet':{'balance_kobo':125000,'currency':'NGN','status':'active','transactions':[]},
      'workspace':{
        'exists':true,
        'details':{'Name':'Chemistry Student','Programme':'B.Sc Chemistry','Level':'300 Level','Session':period.sessionKey,'Semester':period.semesterLabel},
        'courses':['CHM301','CHM303'],
        'pins':['fees'],
        'revision':7,
        'updated_at':'2026-09-28T10:00:00Z',
      },
      'feature_flags':{'workspace_sync':true},
    }};
    if(path=='/workspace'){
      workspaceGets++;
      throw StateError('Bootstrap workspace should avoid a second workspace GET.');
    }
    if(path=='/premium/status')return {'data':{
      'active':false,'plan':null,'status':'inactive','started_at':null,'expires_at':null,
      'auto_renew':false,'features':{},'server_time':DateTime.now().toUtc().toIso8601String(),
    }};
    if(path=='/profile/preferences')return {'data':{
      'preferred_skin':'defaultNoun','profile_frame':'classic','birthday':{'month':null,'day':null,'celebration_enabled':true},
    }};
    if(path=='/profile/settings')return {'data':{'exists':true,'settings':settings}};
    if(path=='/posts/news')return {'data':{'items':[]}};
    if(path=='/services')return {'data':{'items':[]}};
    return {'data':{'items':[]}};
  }

  @override
  Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey}) async {
    if(path=='/profile/settings')return {'data':{'exists':true,'settings':Map<String,dynamic>.from(body['settings'] as Map? ?? settings)}};
    return {'data':{}};
  }
}

class _ServiceBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key,{bool cache=true}) async {
    if(key=='assets/data/services.json')return jsonEncode(<dynamic>[]);
    return rootBundle.loadString(key,cache:cache);
  }

  @override
  Future<ByteData> load(String key)=>rootBundle.load(key);
}

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-in dashboard hydrates workspace from bootstrap without second GET',(tester)async{
    SharedPreferences.setMockInitialValues({});
    PremiumService.instance.clear();
    final api=_BootstrapApi();
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(PremiumService.instance.clear);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner:false,
      theme:buildAppTheme(),
      home:LivePortal(apiClient:api,serviceBundle:_ServiceBundle()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('B.Sc Chemistry'),findsOneWidget);
    expect(api.workspaceGets,0);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('B.Sc Chemistry'),findsOneWidget);
    expect(find.text('2 registered courses'),findsOneWidget);
    expect(api.workspaceGets,0);
    expect(tester.takeException(),isNull);
  });
}
