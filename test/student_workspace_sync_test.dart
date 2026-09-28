import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/screens/student_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signed-in workspace restores server data and caches it locally', () async {
    SharedPreferences.setMockInitialValues({});
    final client=MockClient((request) async {
      expect(request.method,'GET');
      expect(request.url.queryParameters['route'],'/workspace');
      return http.Response(jsonEncode({'data':{
        'exists':true,
        'details':{'Programme':'B.Sc Chemistry','Level':'300 Level'},
        'courses':['CHM301','CHM303'],
        'pins':['fees'],
        'revision':4,
        'updated_at':'2026-09-28T10:00:00Z',
      }}),200,headers:{'content-type':'application/json'});
    });
    final workspace=StudentWorkspace('42',api:ApiClient(client:client));
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
        'details':{'Programme':'B.Sc Biology'},
        'courses':['BIO301'],
        'pins':<String>[],
        'revision':2,
        'dirty':false,
      }),
    });
    var getCount=0;var postCount=0;
    final client=MockClient((request) async {
      if(request.method=='GET'){
        getCount++;
        return http.Response(jsonEncode({'data':{
          'exists':true,'details':{'Programme':'B.Sc Biology'},'courses':['BIO301'],'pins':[],'revision':2,'updated_at':'2026-09-28T10:00:00Z'
        }}),200,headers:{'content-type':'application/json'});
      }
      postCount++;
      final body=jsonDecode(request.body) as Map<String,dynamic>;
      expect(body['base_revision'],2);
      expect(body['courses'],contains('BIO303'));
      return http.Response(jsonEncode({'data':{
        'exists':true,'details':body['details'],'courses':body['courses'],'pins':body['pins'],'revision':3,'updated_at':'2026-09-28T10:01:00Z'
      }}),200,headers:{'content-type':'application/json'});
    });
    final workspace=StudentWorkspace('77',api:ApiClient(client:client));
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
    final workspace=StudentWorkspace('guest',api:ApiClient(client:client));
    await workspace.load();
    workspace.courses=['GST302'];
    await workspace.save();
    expect(calls,0);
    expect(workspace.courses,['GST302']);
  });
}
