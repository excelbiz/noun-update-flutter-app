import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noun_update_student_app/core/api_client.dart';

class MemorySession extends SessionStore {
 String? access='old-access',refresh='old-refresh';
 @override Future<String?> readAccessToken()async=>access;
 @override Future<String?> readRefreshToken()async=>refresh;
 @override Future<void> saveTokens({required String accessToken,required String refreshToken})async{access=accessToken;refresh=refreshToken;}
 @override Future<void> clear()async{access=null;refresh=null;}
}
http.Response reply(Map<String,dynamic> data,[int status=200])=>http.Response(jsonEncode(status==200?{'data':data}:{'error':{'message':'Expired','code':'LOGIN_REQUIRED'}}),status);
void main(){
 test('central renewal uses the central route and replays an idempotent write once',()async{
  final session=MemorySession();var refreshes=0,writes=0;
  final api=ApiClient(sessionStore:session,client:MockClient((r)async{
   expect(r.url.path,'/api/central/index.php');
   if(r.url.queryParameters['route']=='/auth/refresh'){
    refreshes++;expect(jsonDecode(r.body)['refresh_token'],'old-refresh');
    return reply({'access_token':'new-access','refresh_token':'new-refresh'});
   }
   writes++;expect(r.headers['Idempotency-Key'],'order-123');
   expect(jsonDecode(r.body),{'plan_id':'semester'});
   return r.headers['Authorization']=='Bearer old-access'?reply({},401):reply({'ok':true});
  }));
  expect((await api.postJson('/premium/purchase',{'plan_id':'semester'},idempotencyKey:'order-123'))['data']['ok'],isTrue);
  expect(refreshes,1);expect(writes,2);expect(session.refresh,'new-refresh');
 });
 test('public content failures never trigger account token renewal',()async{
  var calls=0;final api=ApiClient(sessionStore:MemorySession(),client:MockClient((r)async{calls++;expect(r.headers.containsKey('Authorization'),isFalse);return reply({},401);}));
  await expectLater(api.getJson('/posts/news'),throwsA(isA<ApiException>()));expect(calls,1);
 });
 test('logout during renewal cannot restore the old login',()async{
  final waiting=Completer<void>(),started=Completer<void>();final session=MemorySession();
  final api=ApiClient(sessionStore:session,client:MockClient((r)async{
   if(r.url.queryParameters['route']=='/auth/refresh'){started.complete();await waiting.future;return reply({'access_token':'late-access','refresh_token':'late-refresh'});}
   return reply({},401);
  }));
  final pending=expectLater(api.getJson('/workspace'),throwsA(isA<ApiException>()));
  await started.future;await api.clearSession();waiting.complete();await pending;
  expect(session.access,isNull);expect(session.refresh,isNull);
 });
 test('a delayed rejected renewal cannot erase a newer sign-in',()async{
  final waiting=Completer<void>(),started=Completer<void>();final session=MemorySession();
  final api=ApiClient(sessionStore:session,client:MockClient((r)async{
   if(r.url.queryParameters['route']=='/auth/refresh'){started.complete();await waiting.future;}
   return reply({},401);
  }));
  final pending=expectLater(api.getJson('/workspace'),throwsA(isA<ApiException>()));
  await started.future;await api.saveSession(accessToken:'second-account',refreshToken:'second-refresh');waiting.complete();await pending;
  expect(session.access,'second-account');expect(session.refresh,'second-refresh');
 });
 test('expired or offline logout still removes local credentials',()async{
  final session=MemorySession();final api=ApiClient(sessionStore:session,client:MockClient((r)async=>reply({},401)));
  expect(await api.signOut(),isFalse);expect(await api.hasSession(),isFalse);expect(session.refresh,isNull);
 });
 test('overlapping protected reads share one renewal',()async{
  final gate=Completer<void>(),started=Completer<void>();final session=MemorySession();var refreshes=0;
  final api=ApiClient(sessionStore:session,client:MockClient((r)async{
   if(r.url.queryParameters['route']=='/auth/refresh'){refreshes++;if(!started.isCompleted)started.complete();await gate.future;return reply({'access_token':'new-access','refresh_token':'new-refresh'});}
   return r.headers['Authorization']=='Bearer old-access'?reply({},401):reply({'ok':true});
  }));
  final first=api.getJson('/workspace'),second=api.getJson('/saved-resources');await started.future;
  await Future<void>.delayed(Duration.zero);gate.complete();await Future.wait([first,second]);expect(refreshes,1);
 });
}
