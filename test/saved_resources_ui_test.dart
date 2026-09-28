import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/screens/native_saved_resources.dart';
import 'package:noun_update_student_app/screens/student_workspace.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('My Courses can save a course hub locally for a guest',(tester)async{
    SharedPreferences.setMockInitialValues({});
    final workspace=StudentWorkspace('guest',api:ApiClient())..courses=['CIT411'];

    await tester.pumpWidget(MaterialApp(
      theme:buildAppTheme(),
      home:MyCoursesPage(workspace:workspace,openResource:(_,__){}),
    ));
    await tester.pumpAndSettle();

    final save=find.byTooltip('Save course hub').first;
    expect(save,findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove saved course').first,findsOneWidget);
    final prefs=await SharedPreferences.getInstance();
    final cached=jsonDecode(prefs.getString('nu-saved-resources-guest')!) as Map<String,dynamic>;
    final items=List<Map<String,dynamic>>.from((cached['items'] as List).map((e)=>Map<String,dynamic>.from(e as Map)));
    expect(items.single['resource_key'],'course:CIT411');
    expect(items.single['resource_type'],'course_hub');
    expect(items.single['course_code'],'CIT411');
    expect(items.single['route'],'/courses');
  });

  testWidgets('Saved Resources reopens a validated slash route as an app service id',(tester)async{
    SharedPreferences.setMockInitialValues({
      'nu-saved-resources-guest':jsonEncode({
        'items':[
          {
            'resource_key':'course:CIT411',
            'resource_type':'course_hub',
            'title':'CIT411 Course Hub',
            'course_code':'CIT411',
            'route':'/courses',
            'saved_at':'2026-09-28T18:00:00Z',
          }
        ],
        'pending':[],
      }),
    });
    Map<String,dynamic>? opened;

    await tester.pumpWidget(MaterialApp(
      theme:buildAppTheme(),
      home:NativeSavedResourcesPage(
        api:ApiClient(),
        userId:null,
        onOpen:(item)=>opened=item,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('CIT411 Course Hub'),findsOneWidget);
    await tester.tap(find.text('CIT411 Course Hub'));
    await tester.pump();

    expect(opened,isNotNull);
    expect(opened!['route'],'courses');
    expect(opened!['course_code'],'CIT411');
  });
}
