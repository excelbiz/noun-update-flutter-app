import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/api_client.dart';
import 'package:noun_update_student_app/core/app_theme.dart';
import 'package:noun_update_student_app/screens/native_timetable.dart';

class _TimetableApi extends ApiClient {
  _TimetableApi({this.mismatch=false});
  final bool mismatch;

  @override
  Future<Map<String,dynamic>> getJson(String path) async {
    expect(path,contains('/timetable?courses='));
    return {'data':{
      'current_period':'2026_2',
      'source_period':mismatch?'2026_1':'2026_2',
      'period_mismatch':mismatch,
      'items':[
        {
          'course_code':'CIT411','course_title':'Internet Programming','day':'Day 2',
          'date':'2026-10-20','time':'9:00 am','exam_type':'POP',
          'exam_datetime':'2026-10-20T09:00:00+01:00','is_past':false,
        },
        {
          'course_code':'GST302','course_title':'Business Creation and Growth','day':'Day 5',
          'date':'2026-10-23','time':'8:00 am','exam_type':'CBT',
          'exam_datetime':'2026-10-23T08:00:00+01:00','is_past':false,
        },
      ],
      'missing_courses':['CIT999'],
      'next_exam':{
        'course_code':'CIT411','course_title':'Internet Programming','day':'Day 2',
        'date':'2026-10-20','time':'9:00 am','exam_type':'POP',
        'exam_datetime':'2026-10-20T09:00:00+01:00','is_past':false,
      },
    }};
  }
}

void main(){
  test('timetable snapshot exposes verified next exam summary',()async{
    final snapshot=await TimetableSnapshot.fetch(_TimetableApi(),['CIT411','GST302','CIT999']);
    expect(snapshot.currentPeriod,'2026_2');
    expect(snapshot.periodMismatch,isFalse);
    expect(snapshot.items,hasLength(2));
    expect(snapshot.missingCourses,['CIT999']);
    expect(snapshot.nextExam?.courseCode,'CIT411');
    expect(snapshot.nextExamSummary,'CIT411 · 2026-10-20 · 9:00 am');
  });

  testWidgets('native timetable renders matched exams and missing course warning',(tester)async{
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:buildAppTheme(),home:NativeTimetable(
      api:_TimetableApi(),courses:const ['CIT411','GST302','CIT999'],onManageCourses:(){},
    )));
    await tester.pumpAndSettle();
    expect(find.text('2026_2 Exam Timetable'),findsOneWidget);
    expect(find.text('CIT411'),findsWidgets);
    expect(find.text('GST302'),findsOneWidget);
    expect(find.text('POP'),findsWidgets);
    expect(find.text('CBT'),findsOneWidget);
    expect(find.text('CIT999'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('native timetable warns when imported period is stale',(tester)async{
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:buildAppTheme(),home:NativeTimetable(
      api:_TimetableApi(mismatch:true),courses:const ['CIT411'],onManageCourses:(){},
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('different academic period'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
