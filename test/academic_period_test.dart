import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/academic_period.dart';

void main() {
  test('January through June use first session', () {
    for (var month=1; month<=6; month++) {
      final period=AcademicPeriod.forDate(DateTime(2027,month,15));
      expect(period.sessionKey,'2027_1');
      expect(period.semesterLabel,'First Semester');
    }
  });

  test('July through December use second session', () {
    for (var month=7; month<=12; month++) {
      final period=AcademicPeriod.forDate(DateTime(2027,month,15));
      expect(period.sessionKey,'2027_2');
      expect(period.semesterLabel,'Second Semester');
    }
  });

  test('year changes automatically', () {
    expect(AcademicPeriod.forDate(DateTime(2026,12,31)).displayLabel,'2026_2 · Second Semester');
    expect(AcademicPeriod.forDate(DateTime(2027,1,1)).displayLabel,'2027_1 · First Semester');
  });
}
