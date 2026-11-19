import 'package:flutter/material.dart';

class GlassHero extends StatelessWidget {
  const GlassHero({super.key,required this.title,required this.subtitle,this.icon,this.artwork});
  final String title,subtitle;
  final IconData? icon;
  final Widget? artwork;

  @override Widget build(BuildContext context)=>ClipRRect(
    borderRadius:BorderRadius.circular(15),
    child:DecoratedBox(decoration:const BoxDecoration(gradient:LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xff008746),Color(0xff00452f),Color(0xff03291e)])),
      child:Stack(children:[
        const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_GreenRibbons(gold:true)))),
        Padding(padding:const EdgeInsets.fromLTRB(15,15,12,16),child:Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(color:Colors.white,fontWeight:FontWeight.w800,height:1.16)),
            const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Color(0xffe3fbeb),fontSize:12,height:1.35)),
          ])),
          if(artwork!=null||icon!=null)...[const SizedBox(width:10),
            SizedBox(width:72,height:66,child:artwork??Icon(icon,size:46,color:const Color(0xffb2fbc2)))],
        ])),
      ])));
}

class GlassLineIcon extends StatelessWidget {
  const GlassLineIcon(this.icon,{super.key,this.tone,this.size=37});
  final IconData icon;
  final Color? tone;
  final double size;
  @override Widget build(BuildContext context){
    final s=Theme.of(context).colorScheme;
    final dark=s.brightness==Brightness.dark;
    final colour=tone??s.primary;
    return ExcludeSemantics(child:Container(width:size,height:size,
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(10),
        gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[
          Color.lerp(s.surface,colour,dark ? .25 : .12)!,Color.lerp(s.surface,colour,dark ? .12 : .05)!,
        ]),border:Border.all(color:colour.withValues(alpha:.22))),
      child:Icon(icon,size:size*.61,color:dark?Color.lerp(colour,Colors.white,.32):colour)));
  }
}

class GlassRow extends StatelessWidget {
  const GlassRow({super.key,required this.icon,required this.title,this.subtitle,this.onTap,this.end,this.tone});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? end;
  final Color? tone;
  @override Widget build(BuildContext context){
    final s=Theme.of(context).colorScheme;
    final radius=BorderRadius.circular(12);
    return Padding(padding:const EdgeInsets.only(bottom:7),child:Material(
      color:s.surface,shape:RoundedRectangleBorder(borderRadius:radius,side:BorderSide(color:s.outlineVariant)),
      clipBehavior:Clip.antiAlias,child:ListTile(
        minTileHeight:54,contentPadding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
        leading:GlassLineIcon(icon,tone:tone),
        title:Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800)),
        subtitle:subtitle==null?null:Text(subtitle!,style:TextStyle(fontSize:12,height:1.35,color:s.onSurfaceVariant)),
        trailing:end??(onTap==null?null:Icon(Icons.chevron_right_rounded,size:19,color:s.onSurfaceVariant)),
        onTap:onTap,
      )));
  }
}

class GlassProgress extends StatelessWidget {
  const GlassProgress({super.key,required this.value});
  final double value;
  @override Widget build(BuildContext context){
    final scheme=Theme.of(context).colorScheme;
    final percent='${(value*100).round()}%';
    return Semantics(label:'$percent of units marked as read',child:SizedBox.square(dimension:35,
      child:ExcludeSemantics(child:Stack(alignment:Alignment.center,children:[
        SizedBox.expand(child:CircularProgressIndicator(value:value,strokeWidth:3,
          backgroundColor:scheme.primaryContainer,color:scheme.primary)),
        Text(percent,style:TextStyle(color:scheme.onSurface,fontSize:9,fontWeight:FontWeight.w800)),
      ]))));
  }
}

class GlassAction extends StatelessWidget {
  const GlassAction({super.key,required this.label,required this.onPressed,this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override Widget build(BuildContext context){
    final border=BorderRadius.circular(14);
    return DecoratedBox(decoration:BoxDecoration(borderRadius:border,gradient:onPressed==null?null:
      const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xff00863b),Color(0xff005234)])),
      child:FilledButton(onPressed:onPressed,style:FilledButton.styleFrom(
        backgroundColor:Colors.transparent,shadowColor:Colors.transparent,foregroundColor:Colors.white,
        minimumSize:const Size(double.infinity,48),shape:RoundedRectangleBorder(borderRadius:border)),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          if(icon!=null)...[Icon(icon,size:18),const SizedBox(width:8)],
          Flexible(child:Text(label,textAlign:TextAlign.center)),
        ])));
  }
}

class GlassWaves extends StatelessWidget {
  const GlassWaves({super.key,this.gold=false});
  final bool gold;
  @override Widget build(BuildContext context)=>IgnorePointer(child:CustomPaint(painter:_GreenRibbons(gold:gold)));
}
class _GreenRibbons extends CustomPainter {
  const _GreenRibbons({required this.gold});
  final bool gold;
  @override void paint(Canvas canvas,Size size){
    final w=size.width,h=size.height;
    final path=Path()..moveTo(0,h*.72)..quadraticBezierTo(w*.43,h*1.03,w,h*.53)..lineTo(w,h)..lineTo(0,h)..close();
    canvas.drawPath(path,Paint()..color=const Color(0x2825d17c));
    final edge=Path()..moveTo(w*.18,h)..quadraticBezierTo(w*.74,h*.93,w,h*.54)
      ..lineTo(w,h*.66)..quadraticBezierTo(w*.8,h*.96,w*.45,h)..close();
    canvas.drawPath(edge,Paint()..color=(gold?const Color(0xfff4c833):const Color(0xff22a46b)).withValues(alpha:gold ? .80 : .38));
  }
  @override bool shouldRepaint(_GreenRibbons oldDelegate)=>oldDelegate.gold!=gold;
}

class BookStackArt extends StatelessWidget {
  const BookStackArt({super.key});
  @override Widget build(BuildContext context)=>const ExcludeSemantics(child:CustomPaint(painter:_BookStackPainter()));
}
class _BookStackPainter extends CustomPainter {
  const _BookStackPainter();
  @override void paint(Canvas canvas,Size size){
    canvas.save();canvas.scale(size.width/100,size.height/90);
    final p=Paint();
    for(var i=0;i<3;i++){
      final y=53.0+11*i,x=i.isOdd?19.0:10.0,w=i.isOdd?65.0:77.0;
      final c=[const Color(0xff139760),const Color(0xfff4b93c),const Color(0xff175b43)][i];
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,11),const Radius.circular(3)),p..color=c);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+6,y+2,w-8,7),const Radius.circular(2)),p..color=const Color(0xfffff4d8));
      canvas.drawLine(Offset(x+10,y+5),Offset(x+w-4,y+5),p..color=const Color(0xffdfd4b3)..strokeWidth=.6);
    }
    final cap=Path()..moveTo(25,34)..lineTo(71,31)..lineTo(69,48)..quadraticBezierTo(49,58,28,47)..close();
    canvas.drawPath(cap,p..color=const Color(0xff0b2522));
    final top=Path()..moveTo(6,30)..lineTo(51,13)..lineTo(95,27)..lineTo(51,44)..close();
    canvas.drawPath(top,p..color=const Color(0xff092e27));
    canvas.drawPath(top,p..color=const Color(0xff8accac)..style=PaintingStyle.stroke..strokeWidth=1.4);
    p.style=PaintingStyle.fill;
    canvas.drawLine(const Offset(54,29),const Offset(84,36),p..color=const Color(0xffffce48)..strokeWidth=2);
    canvas.drawLine(const Offset(84,36),const Offset(84,50),p);
    canvas.drawOval(const Rect.fromLTWH(81,48,6,10),p);
    canvas.restore();
  }
  @override bool shouldRepaint(_BookStackPainter oldDelegate)=>false;
}
