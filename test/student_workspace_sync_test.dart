import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/academic_period.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/screens/student_workspace.dart';

class _TestSessionStore extends SessionStore {
  const _TestSessionStore();

  @override
  Future<String?> readAccessToken() async => 'a' * 64;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<void> clear() async {}
}

ApiClient _api(http.Client client) => ApiClient(
      client: client,
      sessionStore: const _TestSessionStore(),
    );

Map<String,String> _details(String programme) {
  final period=AcademicPeriod.forDate(DateTime.now());
  return {'Programme':programme,'Session':period.sessionKey,'Semester':period.semesterLabel};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signed-in workspace restores server data and caches it locally', () async {
    SharedPreferences.setMockInitialValues({});
    final client=MockClient((request) async {
      expect(request.method,'GET');
      expect(request.url.path,'/api/central/index.php');
      expect(request.url.queryParameters['route'],'/workspace');
      expect(request.headers['Authorization'],'Bearer ${'a' * 64}');
      return http.Response(jsonEncode({'data':{
        'exists':true,
        'details':{..._details('B.Sc Chemistry'),'Level':'300 Level'},
        'courses':['CHM301','CHM303'],
        'pins':['fees'],
        'revision':4,
        'updated_at':'2026-09-28T10:00:00Z',
      }}),200,headers:{'content-type':'application/json'});
    });
    final workspace=StudentWorkspace('42',api:_api(client));
    await workspace.load();
    expect(workspace.details['Programme'],'B.Sc Chemistry');
    expect(workspace.courses,['CHM301','CHM303']);
    expect(workspace.pins,contains('fees'));
    expect(workspace.revision,4);
    expect(workspace.syncPending,isFalse);
    final prefs=await SharedPreferences.getInstance();
    expect(prefs.getString('nu-workspace-v1-42'),contains('CHM303'));
  });

  test('local signed-in edit is posted with current revision', () async {
    SharedPreferences.setMockInitialValues({
      'nu-workspace-v1-77':jsonEncode({
        'details':_details('B.Sc Biology'),
        'courses':['BIO301'],
        'pins':<String>[],
        'revision':2,
        'dirty':false,
      }),
    });
    var getCount=0;var postCount=0;
    final client=MockClient((request) async {
      expect(request.url.path,'/api/central/index.php');
      expect(request.url.queryParameters['route'],'/workspace');
      if(request.method=='GET'){
        getCount++;
        return http.Response(jsonEncode({'data':{
          'exists':true,'details':_details('B.Sc Biology'),'courses':['BIO301'],'pins':[],'revision':2,'updated_at':'2026-09-28T10:00:00Z'
        }}),200,headers:{'content-type':'application/json'});
      }
      expect(request.method,'POST');
      postCount++;
      final body=jsonDecode(request.body) as Map<String,dynamic>;
      expect(body['base_revision'],2);
      expect(body['courses'],contains('BIO303'));
      return http.Response(jsonEncode({'data':{
        'exists':true,'details':body['details'],'courses':body['courses'],'pins':body['pins'],'revision':3,'updated_at':'2026-09-28T10:01:00Z'
      }}),200,headers:{'content-type':'application/json'});
    });
    final workspace=StudentWorkspace('77',api:_api(client));
    await workspace.load();
    workspace.courses=[...workspace.courses,'BIO303'];
    await workspace.save();
    expect(getCount,1);
    expect(postCount,1);
    expect(workspace.revision,3);
    expect(workspace.syncPending,isFalse);
    expect(workspace.courses,contains('BIO303'));
  });

  test('guest workspace remains device-only', () async {
    SharedPreferences.setMockInitialValues({});
    var calls=0;
    final client=MockClient((request) async {calls++;return http.Response('{}',500);});
    final workspace=StudentWorkspace('guest',api:_api(client));
    await workspace.load();
    workspace.courses=['GST302'];
    await workspace.save();
    expect(calls,0);
    expect(workspace.courses,['GST302']);
  });

  test('stale device does not overwrite newer account courses until reviewed',()async{
    SharedPreferences.setMockInitialValues({'nu-workspace-v1-95':jsonEncode({'details':_details('Local programme'),'courses':['CIT411'],'pins':[],'revision':1,'dirty':true})});
    var writes=0;var remote=<String,dynamic>{'account_id':'95','exists':true,'details':_details('Cloud programme'),'courses':['GST302'],'pins':[],'revision':2};
    final client=MockClient((request)async{
      if(request.method=='POST'){
        writes++;final body=jsonDecode(request.body) as Map;
        expect(body['account_id'],'95');expect(body['base_revision'],2);
        remote={...remote,'details':body['details'],'courses':body['courses'],'pins':body['pins'],'revision':3};
      }
      return http.Response(jsonEncode({'data':remote}),200);
    });
    final w=StudentWorkspace('95',api:_api(client));await w.load();
    expect(w.courses,['CIT411']);expect(w.conflict,isNotNull);expect(writes,0);
    await w.resolveConflict(true);expect(writes,1);expect(w.conflict,isNull);expect(w.revision,3);expect(w.courses,['CIT411']);
  });
  test('legacy local copy is retained and account copy can be chosen explicitly',()async{
    SharedPreferences.setMockInitialValues({'nu-workspace-v1-96':jsonEncode({'details':{},'courses':['CIT411'],'pins':[]})});
    final client=MockClient((request)async{
      expect(request.method,'GET');
      return http.Response(jsonEncode({'data':{'account_id':'96','exists':true,'details':{},'courses':['GST302'],'pins':[],'revision':5}}),200);
    });
    final w=StudentWorkspace('96',api:_api(client));await w.load();expect(w.courses,['CIT411']);expect(w.conflict,isNotNull);
    await w.resolveConflict(false);expect(w.courses,['GST302']);expect(w.syncPending,isFalse);
  });
  test('open student form is not replaced during dashboard refresh',()async{
    SharedPreferences.setMockInitialValues({});var calls=0;
    final client=MockClient((request)async{calls++;return http.Response('{}',500);});
    final w=StudentWorkspace('97',api:_api(client));w.details={'Name':'Student'};w.beginEdit();await w.load();
    expect(w.details['Name'],'Student');expect(calls,0);w.endEdit();
  });
}
