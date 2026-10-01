import 'package:flutter/material.dart';

/// Fine academic outlines drawn at a shared 24-unit size for this skin.
class BoldLineIcon extends StatelessWidget {
  const BoldLineIcon(this.id, {super.key, this.size = 24, this.color = Colors.white});
  final String id;
  final double size;
  final Color color;
  static bool supports(String id) => const {'my-courses', 'fees', 'courses', 'past-questions',
    'exam-summary', 'personalized-timetable', 'study-hub', 'cgpa-calculator', 'result',
    'tools', 'mock', 'course-summary', 'pas-status', 'past-paper'}.contains(id);
  @override Widget build(BuildContext context) => ExcludeSemantics(child: SizedBox(
    width: size, height: size, child: CustomPaint(painter: _BoldLinePainter(id, color))));
}

class _BoldLinePainter extends CustomPainter {
  const _BoldLinePainter(this.id, this.color);
  final String id;
  final Color color;
  @override void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final ink = Paint()..color = color..style = PaintingStyle.stroke
      ..strokeWidth = 1.45..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    void path(Path p) => canvas.drawPath(p, ink);
    void line(double x, double y, double x2, double y2) => canvas.drawLine(Offset(x, y), Offset(x2, y2), ink);
    void box(double x, double y, double w, double h, [double radius = 1.7]) => canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radius)), ink);
    void sheet() {
      path(Path()..moveTo(5, 2.5)..lineTo(14, 2.5)..lineTo(19, 7.5)..lineTo(19, 21.5)
        ..lineTo(5, 21.5)..close());
      path(Path()..moveTo(14, 2.5)..lineTo(14, 7.5)..lineTo(19, 7.5));
    }
    void textLines() {for (final y in [11.0, 14.5, 18.0]) {line(8, y, 16, y);}}
    switch (id) {
      case 'my-courses':
        path(Path()..moveTo(12, 5)..quadraticBezierTo(7.5, 2, 2.5, 4)..lineTo(2.5, 20)
          ..quadraticBezierTo(8, 18, 12, 21)..quadraticBezierTo(16, 18, 21.5, 20)
          ..lineTo(21.5, 4)..quadraticBezierTo(16.5, 2, 12, 5)..lineTo(12, 21));
        line(5.5, 7, 5.5, 16); line(18.5, 7, 18.5, 16);
      case 'fees':
        box(3, 6, 18, 15, 2);
        path(Path()..moveTo(3, 8)..lineTo(3, 4.5)..lineTo(17, 2.5)..lineTo(17, 6));
        box(14, 11, 7, 6, 1); canvas.drawCircle(const Offset(16.5, 14), .6, Paint()..color = color);
      case 'courses':
        path(Path()..moveTo(2.5, 8)..lineTo(2.5, 4.5)..lineTo(9, 4.5)..lineTo(11.5, 7)
          ..lineTo(21.5, 7)..lineTo(21.5, 10));
        path(Path()..moveTo(4, 9.5)..lineTo(22, 9.5)..lineTo(19, 20)..lineTo(2, 20)..close());
      case 'past-questions':
        box(3.5, 2.5, 17, 19, 3);
        path(Path()..moveTo(8.5, 8.5)..cubicTo(8.5, 4, 16.5, 4, 15.5, 9)
          ..cubicTo(15, 11, 12, 11, 12, 14));
        canvas.drawCircle(const Offset(12, 17.5), .8, Paint()..color = color);
      case 'exam-summary':
        box(3.5, 3, 17, 18);
        for (final y in [7.5, 12.0, 16.5]) {box(6.5, y - 1, 2, 2, .3); line(11, y, 17.5, y);}
      case 'personalized-timetable':
        box(3, 4.5, 18, 17); line(7, 2.5, 7, 7); line(17, 2.5, 17, 7); line(3, 9, 21, 9);
        for (final y in [12.5, 17.0]) {for (final x in [7.0, 12.0, 17.0]) {line(x, y, x, y + .6);}}
      case 'study-hub':
        canvas.drawCircle(const Offset(12, 6), 3, ink);
        canvas.drawCircle(const Offset(4.5, 8), 2.2, ink); canvas.drawCircle(const Offset(19.5, 8), 2.2, ink);
        path(Path()..moveTo(7, 21)..lineTo(7, 16.5)..cubicTo(7, 11, 17, 11, 17, 16.5)..lineTo(17, 21)..close());
        path(Path()..moveTo(5, 20)..lineTo(1.5, 20)..lineTo(1.5, 16)..quadraticBezierTo(1.5, 12, 6, 13));
        path(Path()..moveTo(19, 20)..lineTo(22.5, 20)..lineTo(22.5, 16)..quadraticBezierTo(22.5, 12, 18, 13));
      case 'cgpa-calculator':
        box(4, 2, 16, 20, 2); box(7, 5, 10, 4, .5);
        for (final y in [13.0, 17.5]) {for (final x in [7.0, 11.5, 16.0]) {box(x, y, 1.3, 1.3, .2);}}
      case 'result':
        path(Path()..moveTo(16, 21)..lineTo(4, 21)..lineTo(4, 3)..lineTo(17, 3)..lineTo(17, 11));
        canvas.drawCircle(const Offset(10, 10), 3.5, ink); line(12.5, 12.5, 15, 15);
        line(7, 17, 10, 17); box(15.5, 16, 5.5, 5.5, 1);
        path(Path()..moveTo(17, 18.5)..lineTo(18, 19.5)..lineTo(20, 17.5));
      case 'tools':
        for (var i = 0; i < 4; i++) {
          canvas.save(); canvas.translate(12, 12); canvas.rotate(i * 1.5707963267948966);
          path(Path()..moveTo(-1, -1)..lineTo(-1, -7)..cubicTo(-1, -12, -10, -10, -8, -5)
            ..quadraticBezierTo(-6, -1, -1, -1)..close());
          canvas.restore();
        }
      case 'mock':
        sheet(); line(8, 11, 15, 11); line(8, 14.5, 15, 14.5); line(8, 18, 13, 18);
      default:
        sheet(); textLines();
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _BoldLinePainter oldDelegate) =>
    oldDelegate.id != id || oldDelegate.color != color;
}
