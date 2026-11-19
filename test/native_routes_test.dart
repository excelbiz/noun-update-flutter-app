import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/native_routes.dart';
import 'package:noun_update_student_app/core/offline_materials.dart';

void main() {
  test('unknown, website and remote redirect IDs are not executable routes', () {
    for (final id in ['https://nounupdate.com/mock','/mock','//nounupdate.com',
      'https://example.test','javascript:alert(1)','mock','quizly','new-remote-tool']) {
      expect(serviceIdFromInternalAction(id),isNull,reason:id);
    }
    expect(studentRoute('course-summary'),StudentRoute.courseSummary);
    expect(studentRoute('exam-summary'),StudentRoute.examSummary);
    expect(studentRoute('personalised-timetable'),StudentRoute.timetable);
  });

  test('production student screens cannot launch fallback web pages', () {
    final files = Directory('lib').listSync(recursive:true).whereType<File>();
    for (final file in files.where((f)=>f.path.endsWith('.dart'))) {
      final source=file.readAsStringSync();
      expect(source, isNot(contains('NativeSiteService')), reason:file.path);
      expect(source, isNot(contains('launchUrl(')), reason:file.path);
      // Authorisation UI, not student service content, is provider-hosted.
      if(!file.path.endsWith('/native_tools.dart')) {
        expect(source, isNot(contains('WebViewWidget(')), reason:file.path);
      }
    }
    final portal=File('lib/screens/live_portal.dart').readAsStringSync();
    expect(portal,isNot(contains("s['url']")));
    expect(portal,isNot(contains("s['path']")));
  });

  test('only canonical public course PDFs may be saved offline', () {
    expect(OfflineMaterials.idFor('/materials/38/pdf'),'38');
    for(final path in ['/download?ticket=abc','/materials/../pdf','/materials/12/pdf?token=abc',
      'https://nounupdate.com/api/v1/materials/12/pdf','/materials/0001/pdf']){
      expect(OfflineMaterials.idFor(path),isNull,reason:path);
    }
  });
}
