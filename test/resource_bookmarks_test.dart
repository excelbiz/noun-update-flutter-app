import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/screens/native_tools.dart';
import 'package:noun_update_student_app/widgets/resource_bookmark.dart';

class LibraryApi extends ApiClient {
 final paths=<String>[];
 @override Future<Map<String,dynamic>> getJson(String path)async{
  paths.add(path);
  if(path.startsWith('/materials'))return {'data':{'items':[{'id':3,'course_code':'CIT411','title':'Computer Networks'}]}};
  if(path=='/study/CIT411')return {'data':{'sections':[]}};
  throw const ApiException('Unexpected request');
 }
}
void main(){
 setUp(()=>SharedPreferences.setMockInitialValues({}));
 for(final summary in [false,true]){
  testWidgets('individual ${summary?'summary':'material'} bookmark stays free and reopens natively',(tester)async{
   final api=LibraryApi();
   await tester.pumpWidget(MaterialApp(theme:buildAppTheme(),home:MaterialLibrary(api:api,summaries:summary)));
   await tester.pumpAndSettle();
   await tester.tap(find.byTooltip('Save resource'));await tester.pumpAndSettle();
   expect(find.byTooltip('Remove bookmark'),findsOneWidget);
   final cached=jsonDecode((await SharedPreferences.getInstance()).getString('nu-saved-resources-guest')!) as Map;
   final item=(cached['items'] as List).single as Map;
   expect(item['resource_type'],summary?'course_summary':'course_material');
   expect(item['route'],summary?'/course-summary/CIT411':'/courses/CIT411');
   expect(api.paths.every((p)=>p.startsWith('/materials')),isTrue);
   await tester.tap(find.text('CIT411'));await tester.pumpAndSettle();
   expect(find.byType(summary?NativeSummary:NativeStudy),findsOneWidget);
   // Merely opening a summary/bookmark must never initiate a purchase.
   expect(api.paths.any((p)=>p.startsWith('/course-summary')),isFalse);
  });
 }
 testWidgets('saved material resolves current metadata and opens its native study screen',(tester)async{
  final api=LibraryApi();
  await tester.pumpWidget(MaterialApp(theme:buildAppTheme(),home:SavedMaterialPage(api:api,code:'CIT411')));
  await tester.pumpAndSettle();expect(find.byType(NativeStudy),findsOneWidget);
  expect(find.text('CIT411 · Computer Networks'),findsOneWidget);
  expect(find.byType(ResourceBookmarkButton),findsOneWidget);
 });
}
