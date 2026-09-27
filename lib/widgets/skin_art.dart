import 'package:flutter/material.dart';
import '../core/skin_theme.dart';

/// Decorative artwork only. Data, text, actions and navigation stay native.
class SkinBackdrop extends StatelessWidget {
  const SkinBackdrop({super.key, required this.child});
  final Widget child;
  @override Widget build(BuildContext context) {
    final t=SkinTokens.of(context);
    if(!t.skin.isPremium)return Material(color:Theme.of(context).scaffoldBackgroundColor,child:child);
    final dark=Theme.of(context).brightness==Brightness.dark;
    final glass=t.skin==AppSkin.glassmorphism;
    return Material(color:t.background,child:Stack(fit:StackFit.expand,children:[
      ExcludeSemantics(child:Image.asset(t.backdropAsset,fit:BoxFit.cover,alignment:Alignment.topCenter,cacheWidth:768)),
      DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
        colors:[t.background.withValues(alpha:glass?(dark ? .58:.86):.94),t.background.withValues(alpha:glass?(dark ? .70:.92):.985)]))),
      if(t.skin==AppSkin.futureTech)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_LightPaths()))),
      child,
    ]));
  }
}

/// Shared by the real dashboard, study pages, sign-in and skin previews.
class SkinHero extends StatelessWidget {
  const SkinHero({super.key,required this.title,required this.subtitle,this.action,this.login=false});
  final String title,subtitle;final Widget? action;final bool login;
  @override Widget build(BuildContext context){
    final t=SkinTokens.of(context);
    final friendly=t.skin==AppSkin.friendlyModern;
    final minimal=t.skin==AppSkin.minimalAcademic;
    final editorial=t.skin==AppSkin.elegantEditorial;
    final path=login?t.loginAsset:t.heroAsset;
    return Container(margin:const EdgeInsets.only(bottom:16),decoration:BoxDecoration(
      borderRadius:BorderRadius.circular(t.radius),border:Border.all(color:const Color(0xffcda84b).withValues(alpha:.45)),
      boxShadow: t.skin==AppSkin.futureTech?[const BoxShadow(color:Color(0x3045e9a0),blurRadius:18)]:[]),
      child:ClipRRect(borderRadius:BorderRadius.circular(t.radius-1),child:Stack(children:[
        Positioned.fill(child:ExcludeSemantics(child:Image.asset(path,fit:BoxFit.cover,alignment:login?Alignment.topCenter:Alignment.centerRight,cacheWidth:960))),
        Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.centerLeft,end:Alignment.centerRight,
          colors:[const Color(0xff002c20).withValues(alpha:.96),const Color(0xff003524).withValues(alpha:friendly ? .72:.60),Colors.transparent],stops:const [0,.58,1])))),
        if(login)const Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xcc00271c)])))),
        Padding(padding:EdgeInsets.all(minimal?24:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(login?'YOUR ACADEMIC JOURNEY':'LEARN · PLAN · SUCCEED',style:const TextStyle(color:Color(0xffffdb8b),fontSize:10,letterSpacing:1.7,fontWeight:FontWeight.w700)),
          SizedBox(height:login?74:12),
          FractionallySizedBox(widthFactor:login ? .94:.63,child:Text(title,style:TextStyle(fontFamily:editorial?'NUReading':null,fontSize:login?28:24,height:1.15,fontWeight:FontWeight.w800,color:Colors.white))),
          const SizedBox(height:12),FractionallySizedBox(widthFactor:.72,child:Text(subtitle,style:const TextStyle(fontSize:12,height:1.5,color:Color(0xffe5f2e9)))),
          if(action!=null)Padding(padding:const EdgeInsets.only(top:16),child:action),
          if(login)const SizedBox(height:24),
        ]),),
      ])));
  }
}

/// Semantic colours are consistent across skins; presentation is token-driven.
class SkinResourceCard extends StatelessWidget {
  const SkinResourceCard({super.key,required this.title,required this.subtitle,required this.icon,required this.tone,required this.onTap,this.trailing,this.grid=false});
  final String title,subtitle;final IconData icon;final Color tone;final VoidCallback onTap;final Widget? trailing;final bool grid;
  @override Widget build(BuildContext context){
    final t=SkinTokens.of(context),dark=Theme.of(context).brightness==Brightness.dark;
    final glass=t.skin==AppSkin.glassmorphism;
    final bold=t.skin==AppSkin.boldPremium||t.skin==AppSkin.elegantEditorial;
    final saturated=bold&&grid;
    final fill=saturated?Color.lerp(tone,Colors.black,.25)!:Color.lerp(t.surface,tone,dark ? .18:.13)!;
    final ink=saturated?Colors.white:t.ink;
    final radius=BorderRadius.circular(t.radius);
    final content=Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(icon,size:grid?30:26,color:saturated?const Color(0xffffdd87):dark?Color.lerp(tone,Colors.white,.65):Color.lerp(tone,Colors.black,.25)),
      const SizedBox(height:10),Text(title,style:TextStyle(color:ink,fontWeight:FontWeight.w800,fontSize:14,height:1.2)),
      const SizedBox(height:6),Text(subtitle,style:TextStyle(color:ink.withValues(alpha:.85),fontSize:11,height:1.35)),
    ]);
    return Container(margin:EdgeInsets.only(bottom:grid?0:10),decoration:BoxDecoration(borderRadius:radius,
      gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[fill.withValues(alpha:glass ? .78:1),Color.lerp(fill,t.gold,glass ? .18:.04)!.withValues(alpha:glass ? .72:1)]),
      border:Border.all(color:glass?Colors.white.withValues(alpha:.35):t.skin==AppSkin.futureTech?const Color(0xff38b986).withValues(alpha:.4):tone.withValues(alpha:.13)),
      boxShadow: [if(!dark&&t.skin!=AppSkin.minimalAcademic)BoxShadow(color:t.primary.withValues(alpha:.06),blurRadius:9,offset:const Offset(0,3))]),
      child:Material(color:Colors.transparent,child:InkWell(borderRadius:radius,onTap:onTap,child:Padding(padding:EdgeInsets.all(grid?16:14),child:grid?content:Row(children:[
        Container(width:43,height:46,decoration:BoxDecoration(color:tone.withValues(alpha:dark ? .25:.1),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:dark?Color.lerp(tone,Colors.white,.65):Color.lerp(tone,Colors.black,.3),size:27)),
        const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:ink,fontSize:14,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,style:TextStyle(color:ink.withValues(alpha:.8),fontSize:11,height:1.35))])),
        trailing??Icon(Icons.chevron_right,color:ink,size:20),
      ])))));
  }
}

class _LightPaths extends CustomPainter {
  const _LightPaths();
  @override void paint(Canvas c,Size s){
    final p=Paint()..style=PaintingStyle.stroke..strokeWidth=.7..color=const Color(0xff46bd88).withValues(alpha:.18);
    for(var i=0;i<4;i++){final x=s.width*(.35+i*.2);c.drawPath(Path()..moveTo(x,0)..lineTo(x-70,s.height*.45)..lineTo(x+45,s.height),p);}
  }
  @override bool shouldRepaint(covariant _LightPaths oldDelegate)=>false;
}

Color skinServiceColour(String id)=>switch(id){
 'exam-summary'||'result'||'personalized-timetable'=>const Color(0xffbb2642),
 'course-summary'||'study-hub'=>const Color(0xff7960b0),
 'past-questions'||'cgpa-calculator'=>const Color(0xffc39424),
 'courses'||'course-materials'||'mock'=>const Color(0xff3488ba),
 _=>const Color(0xff17845a),
};
class SkinHeaderArt extends StatelessWidget {
 const SkinHeaderArt({super.key});
 @override Widget build(BuildContext context)=>ExcludeSemantics(child:Stack(fit:StackFit.expand,children:[
  Image.asset(SkinTokens.of(context).backdropAsset,cacheWidth:768,fit:BoxFit.cover,alignment:Alignment.topCenter),
  const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xe6003425),Color(0xb3003728)]))),
 ]));
}
