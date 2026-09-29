import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/saved_resource_store.dart';

class _SavedSessionStore extends SessionStore {
  const _SavedSessionStore();
  @override Future<String?> readAccessToken() async=>'c'*64;
  @override Future<String?> readRefreshToken() async=>null;
  @override Future<void> saveTokens({required String accessToken,required String refreshToken})async{}
  @override Future<void> clear()async{}
}

ApiClient _api(http.Client client)=>ApiClient(client:client,sessionStore:const _SavedSessionStore());
http.Response _json(Map<String,dynamic> body,[int status=200])=>http.Response(jsonEncode(body),status,headers:{'content-type':'application/json'});

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signed-in saved resources restore from account',()async{
    SharedPreferences.setMockInitialValues({});
    final client=MockClient((request)async{
      expect(request.url.path,'/api/central/index.php');
      expect(request.url.queryParameters['route'],'/saved-resources');
      return _json({'data':{'account_id':'42','items':[{'resource_key':'course:CIT411:material','resource_type':'course_material','title':'CIT411 Course Material','course_code':'CIT411','route':'/courses/CIT411','saved_at':'2026-09-28T12:00:00Z'}]}});
    });
    final store=SavedResourceStore(api:_api(client),userId:'42');
    await store.load();
    expect(store.contains('course:CIT411:material'),isTrue);
    expect(store.all.single['course_code'],'CIT411');
  });

  test('offline save stays queued and replays later',()async{
    SharedPreferences.setMockInitialValues({});
    var online=false;var posts=0;
    final client=MockClient((request)async{
      if(!online)throw Exception('offline');
      if(request.method=='GET')return _json({'data':{'account_id':'42','items':[]}});
      posts++;
      final body=jsonDecode(request.body) as Map<String,dynamic>;
      return _json({'data':{...body,'account_id':'77','saved_at':'2026-09-28T12:01:00Z'}});
    });
    final store=SavedResourceStore(api:_api(client),userId:'77');
    await store.setSaved({'resource_key':'summary:GST302','resource_type':'course_summary','title':'GST302 Summary','course_code':'GST302','route':'/course-summary/GST302'},true);
    expect(store.contains('summary:GST302'),isTrue);
    expect(store.pending.containsKey('summary:GST302'),isTrue);
    online=true;
    await store.load();
    expect(posts,1);
    expect(store.pending,isEmpty);
    expect(store.contains('summary:GST302'),isTrue);
  });

  test('guest bookmark remains device-only',()async{
    SharedPreferences.setMockInitialValues({});
    var calls=0;
    final client=MockClient((request)async{calls++;return _json({'data':{}});});
    final store=SavedResourceStore(api:_api(client));
    await store.setSaved({'resource_key':'guide:exam','resource_type':'guide','title':'Exam Guide'},true);
    await store.load();
    expect(calls,0);
    expect(store.contains('guide:exam'),isTrue);
    expect(store.pending,isEmpty);
  });

  test('separate controls cannot lose bookmarks or replay an older save over removal',()async{
    SharedPreferences.setMockInitialValues({});
    final delayed=Completer<void>(),started=Completer<void>();var calls=0;
    final client=MockClient((request)async{
      final body=jsonDecode(request.body) as Map<String,dynamic>;
      if(calls++==0){started.complete();await delayed.future;}
      return _json({'data':{...body,'account_id':'91'}});
    });
    final a=SavedResourceStore(api:_api(client),userId:'91');
    final b=SavedResourceStore(api:_api(client),userId:'91');
    final resource={'resource_key':'course:CIT411:material','resource_type':'course_material','title':'CIT411','route':'/courses/CIT411'};
    final saving=a.setSaved(resource,true);await started.future;
    final removing=b.setSaved(resource,false);delayed.complete();await Future.wait([saving,removing]);
    final cached=jsonDecode((await SharedPreferences.getInstance()).getString(a.slot)!) as Map;
    expect(cached['items'],isEmpty);expect(cached['pending'],isEmpty);expect(calls,2);
    final guestA=SavedResourceStore(api:_api(client)),guestB=SavedResourceStore(api:_api(client));
    await guestA.setSaved(resource,true);
    await guestB.setSaved({...resource,'resource_key':'second'},true);
    await guestA.load();expect(guestA.items.length,2);
  });
  test('a different account response cannot replace or acknowledge queued bookmarks',()async{
    SharedPreferences.setMockInitialValues({});
    final client=MockClient((request)async=>_json({'data':{'account_id':'other','items':[],'saved':true,'resource_key':'my-resource'}}));
    final store=SavedResourceStore(api:_api(client),userId:'owner');
    await store.setSaved({'resource_key':'my-resource','resource_type':'guide','title':'My guide'},true);
    await store.load();expect(store.contains('my-resource'),isTrue);expect(store.pending,isNotEmpty);
  });
}