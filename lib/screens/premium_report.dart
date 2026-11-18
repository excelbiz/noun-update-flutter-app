import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PremiumAnalyticsReport {
  static String _pct(dynamic value) => value is num ? '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%' : '-';
  static String _time(dynamic value) {
    if (value is! num || value <= 0) return '-';
    final seconds = value.round();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${seconds}s';
  }

  static Future<Uint8List> build(List<Map<String, dynamic>> datasets) async {
    final doc = pw.Document(
      title: 'NOUN Update Premium Analytics',
      author: 'NOUN Update Educational Consultant',
      subject: 'Premium Mock and POP performance analytics',
    );
    final generated = DateTime.now();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .7))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('NOUN UPDATE', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
            pw.Text('Premium Analytics', style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Independent student-support platform - nounupdate.com', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
          ]),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text('Performance Report', style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Generated ${generated.day}/${generated.month}/${generated.year}. This report uses completed practice attempts returned by the NOUN Update analytics service.'),
          pw.SizedBox(height: 18),
          for (final data in datasets) ..._section(data),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: .5), borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Text('Analytics is a Premium insight layer. It does not alter examination results, Mock scores, POP scores or academic records.', style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static List<pw.Widget> _section(Map<String, dynamic> data) {
    final mock = '${data['source']}' == 'mock';
    final title = mock ? 'Mock e-Exam Analytics' : 'POP Exam Practice Analytics';
    if (data['source_available'] != true || data['account_linked'] == false || data['has_data'] != true) {
      final message = data['source_available'] != true
          ? 'Analytics source is not connected.'
          : data['account_linked'] == false
              ? 'No matching practice account was found.'
              : 'No completed practice attempts are available yet.';
      return [pw.Text(title, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 5), pw.Text(message), pw.SizedBox(height: 18)];
    }
    final summary = Map<String, dynamic>.from(data['summary'] as Map? ?? const {});
    final courses = (data['courses'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final difficulty = (data['difficulty'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final metrics = <List<String>>[
      ['Attempts', '${summary['attempts'] ?? 0}'],
      ['Courses', '${summary['courses'] ?? 0}'],
      ['Average', _pct(summary['average_percentage'])],
      ['Best', _pct(summary['best_percentage'])],
      if (mock) ['Practice time', _time(summary['total_time_seconds'])],
      if (mock) ['Avg. pace', summary['seconds_per_question'] is num ? '${summary['seconds_per_question']} sec/question' : '-'],
      if (!mock) ['Answer coverage', _pct(summary['answer_coverage_percentage'])],
    ];
    return [
      pw.Text(title, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(headers: const ['Metric', 'Value'], data: metrics, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), cellStyle: const pw.TextStyle(fontSize: 9), cellPadding: const pw.EdgeInsets.all(5)),
      if (difficulty.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        pw.Text('Performance by difficulty', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(headers: const ['Difficulty', 'Attempts', 'Average', 'Best'], data: [for (final d in difficulty) ['${d['difficulty']}'.toUpperCase(), '${d['attempts'] ?? 0}', _pct(d['average_percentage']), _pct(d['best_percentage'])]], headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), cellStyle: const pw.TextStyle(fontSize: 8), cellPadding: const pw.EdgeInsets.all(4)),
      ],
      if (courses.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        pw.Text('Course performance', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          headers: mock ? const ['Course', 'Attempts', 'Average', 'Best', 'Avg. time'] : const ['Course', 'Attempts', 'Average', 'Best'],
          data: [for (final c in courses.take(20)) mock ? ['${c['course_code']}', '${c['attempts'] ?? 0}', _pct(c['average_percentage']), _pct(c['best_percentage']), _time(c['average_time_seconds'])] : ['${c['course_code']}', '${c['attempts'] ?? 0}', _pct(c['average_percentage']), _pct(c['best_percentage'])]],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.all(4),
        ),
      ],
      pw.SizedBox(height: 20),
    ];
  }
}
