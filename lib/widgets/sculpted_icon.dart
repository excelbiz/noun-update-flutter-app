import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Sculpted vector icons: consistent depth without downloaded image packs.
class SculptedIcon extends StatelessWidget {
  const SculptedIcon(this.kind, {this.size = 62, this.accent = const Color(0xff0a7450), super.key});
  final String kind;
  final double size;
  final Color accent;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: SizedBox.square(
    dimension: size, child: CustomPaint(painter: _Sculpture(kind, accent))));
}
class _Sculpture extends CustomPainter {
  _Sculpture(this.kind, this.accent);
  final String kind;
  final Color accent;
  static const gold = Color(0xffefbc4d), ink = Color(0xff073f30);
  Paint fill(Color color) => Paint()..color = color;
  Path poly(List<Offset> points) => Path()..addPolygon(points, true);
  void slab(Canvas c, Rect r, Color color, {double radius = 8, double depth = 5}) {
    c.drawRRect(RRect.fromRectAndRadius(r.translate(0,depth), Radius.circular(radius)), fill(Color.lerp(color,ink,.4)!));
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color.lerp(color,Colors.white,.35)!,color,Color.lerp(color,ink,.15)!]).createShader(r));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(.7),Radius.circular(radius)),Paint()
      ..style=PaintingStyle.stroke..strokeWidth=1.1..color=Colors.white.withValues(alpha:.42));
  }
  void line(Canvas c, Offset a, Offset b, Color color, [double width = 3]) => c.drawLine(a,b,
    Paint()..color=color..strokeWidth=width..strokeCap=StrokeCap.round);
  @override
  void paint(Canvas c, Size size) {
    c.save();c.scale(size.width/80,size.height/80);
    c.drawOval(const Rect.fromLTWH(15,65,53,8),Paint()..color=ink.withValues(alpha:.15)
      ..maskFilter=const MaskFilter.blur(BlurStyle.normal,5));
    switch(kind) {
      case 'book':
        slab(c,const Rect.fromLTWH(16,14,47,49),accent,radius:7);
        slab(c,const Rect.fromLTWH(23,17,39,43),const Color(0xfffff4d7),radius:4,depth:3);
        slab(c,const Rect.fromLTWH(16,12,43,44),accent,radius:6,depth:2);
        line(c,const Offset(24,16),const Offset(24,53),Colors.white.withValues(alpha:.4),2);
        line(c,const Offset(32,27),const Offset(49,27),gold,4);
        line(c,const Offset(32,35),const Offset(46,35),Colors.white.withValues(alpha:.8),2);
        c.drawPath(poly([const Offset(46,11),const Offset(53,11),const Offset(53,26),const Offset(49.5,23),const Offset(46,26)]),fill(gold));
      case 'document':
        slab(c,const Rect.fromLTWH(18,11,43,52),const Color(0xfff5f5e9),radius:7);
        c.drawPath(poly([const Offset(49,11),const Offset(61,23),const Offset(49,23)]),fill(gold));
        for(var y=29.0;y<=45;y+=8)line(c,Offset(27,y),Offset(y==45?40:50,y),accent,3);
        c.drawCircle(const Offset(57,55),12,fill(ink));c.drawCircle(const Offset(57,52),12,fill(gold));
        line(c,const Offset(51,52),const Offset(55,56),ink,2.5);line(c,const Offset(55,56),const Offset(63,48),ink,2.5);
      case 'wallet':
        slab(c,const Rect.fromLTWH(14,22,52,37),accent,radius:10);
        slab(c,const Rect.fromLTWH(21,13,35,16),gold,radius:4,depth:2);
        slab(c,const Rect.fromLTWH(13,29,53,32),accent);
        slab(c,const Rect.fromLTWH(48,38,20,15),gold,radius:5,depth:2);
        c.drawCircle(const Offset(55,45),2,fill(ink));line(c,const Offset(23,49),const Offset(34,49),Colors.white.withValues(alpha:.65),2);
      case 'calendar':
        slab(c,const Rect.fromLTWH(14,16,52,47),const Color(0xfffff9e9),radius:9);
        slab(c,const Rect.fromLTWH(14,16,52,15),accent,radius:6,depth:1);
        for(final x in [27.0,53.0])line(c,Offset(x,12),Offset(x,21),gold,5);
        for(var y=39.0;y<57;y+=10)for(var x=25.0;x<60;x+=13)c.drawCircle(Offset(x,y),2.5,fill(accent.withValues(alpha:.6)));
        slab(c,const Rect.fromLTWH(45,44,13,13),gold,radius:4,depth:2);
      case 'cap':
        slab(c,const Rect.fromLTWH(23,32,35,23),accent,radius:7,depth:4);
        final p=poly([const Offset(7,28),const Offset(40,44),const Offset(73,28),const Offset(40,12)]);
        c.drawPath(p.shift(const Offset(0,5)),fill(ink));c.drawPath(p,fill(accent));
        line(c,const Offset(40,28),const Offset(66,34),gold,2);line(c,const Offset(66,34),const Offset(66,53),gold,2);
        c.drawCircle(const Offset(66,55),3,fill(gold));
      case 'chart':
        slab(c,const Rect.fromLTWH(12,57,57,7),const Color(0xffe2e9df),radius:3,depth:3);
        slab(c,const Rect.fromLTWH(18,38,12,20),accent,radius:3);slab(c,const Rect.fromLTWH(35,28,12,30),gold,radius:3);
        slab(c,const Rect.fromLTWH(52,14,12,44),accent,radius:3);
        line(c,const Offset(17,25),const Offset(37,15),const Color(0xffc85643),3);line(c,const Offset(37,15),const Offset(34,24),const Color(0xffc85643),3);
      case 'building':
        slab(c,const Rect.fromLTWH(13,56,55,8),accent,radius:3);
        for(final x in [22.0,37.0,52.0])slab(c,Rect.fromLTWH(x,29,7,28),const Color(0xfffff1cf),radius:2,depth:2);
        final p=poly([const Offset(10,28),const Offset(40,11),const Offset(70,28)]);
        c.drawPath(p.shift(const Offset(0,4)),fill(ink));c.drawPath(p,fill(accent));c.drawCircle(const Offset(40,22),3,fill(gold));
      case 'shield':
        final p=Path()..moveTo(40,10)..lineTo(65,20)..lineTo(61,45)..quadraticBezierTo(56,61,40,68)..quadraticBezierTo(23,60,18,45)..lineTo(15,20)..close();
        c.drawPath(p.shift(const Offset(2,3)),fill(ink));c.drawPath(p,Paint()..shader=LinearGradient(colors:[Color.lerp(accent,Colors.white,.25)!,accent]).createShader(const Rect.fromLTWH(15,10,50,58)));
        line(c,const Offset(28,37),const Offset(37,46),gold,5);line(c,const Offset(37,46),const Offset(53,29),gold,5);
      case 'people':
        slab(c,const Rect.fromLTWH(13,39,28,22),accent,radius:12);c.drawCircle(const Offset(27,28),11,fill(accent));
        slab(c,const Rect.fromLTWH(37,41,29,22),gold,radius:12);c.drawCircle(const Offset(51,30),11,fill(gold));
        c.drawCircle(const Offset(48,26),3,fill(Colors.white.withValues(alpha:.5)));
      case 'news':
        slab(c,const Rect.fromLTWH(12,17,56,44),const Color(0xfffff8e5),radius:6);
        slab(c,const Rect.fromLTWH(19,25,19,20),accent,radius:4,depth:2);
        for(var y=26.0;y<54;y+=8)line(c,Offset(44,y),Offset(59,y),accent,2);
        line(c,const Offset(20,53),const Offset(35,53),gold,3);
      case 'quiz':
        slab(c,const Rect.fromLTWH(17,13,47,49),accent,radius:12);slab(c,const Rect.fromLTWH(26,9,28,10),gold,radius:4,depth:2);
        for(var y=30.0;y<56;y+=11){line(c,Offset(25,y),Offset(28,y+3),gold,2);line(c,Offset(28,y+3),Offset(33,y-3),gold,2);line(c,Offset(40,y),Offset(54,y),Colors.white.withValues(alpha:.8),2);}
      case 'spark':
        final p=Path();for(var i=0;i<8;i++){
          final a=-math.pi/2+i*math.pi/4;final r=i.isEven?29.0:12.0;final x=40+math.cos(a)*r,y=38+math.sin(a)*r;
          if(i==0){p.moveTo(x,y);}else{p.lineTo(x,y);}
        }
        p.close();c.drawPath(p.shift(const Offset(2,5)),fill(ink));c.drawPath(p,Paint()..shader=LinearGradient(colors:[gold,accent]).createShader(const Rect.fromLTWH(10,10,60,60)));
        c.drawCircle(const Offset(61,15),4,fill(gold));
      default:
        c.drawCircle(const Offset(40,42),27,fill(ink));
        c.drawCircle(const Offset(40,38),27,Paint()..shader=RadialGradient(center:const Alignment(-.5,-.5),colors:[Color.lerp(accent,Colors.white,.5)!,accent]).createShader(const Rect.fromLTWH(13,11,54,54)));
        c.drawCircle(const Offset(40,38),21,Paint()..color=gold..style=PaintingStyle.stroke..strokeWidth=2);
        c.drawPath(poly([const Offset(49,23),const Offset(44,43),const Offset(31,53),const Offset(36,33)]),fill(gold));
    }
    c.restore();
  }
  @override
  bool shouldRepaint(covariant _Sculpture oldDelegate)=>oldDelegate.kind!=kind||oldDelegate.accent!=accent;
}
