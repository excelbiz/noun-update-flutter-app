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
    final imageOpacity=switch(t.skin){AppSkin.minimalAcademic=>dark?.14:.10,AppSkin.elegantEditorial=>dark?.20:.16,AppSkin.productivityDashboard=>dark?.22:.14,_=>dark?.42:.26};
    final alignment=switch(t.skin){AppSkin.studentFriendly||AppSkin.friendlyModern=>Alignment.topRight,AppSkin.futureTech=>Alignment.centerRight,_=>Alignment.topCenter};
    final overlay=switch(t.skin){
      AppSkin.smartCampus=>dark?[t.background.withValues(alpha:.72),t.background.withValues(alpha:.97)]:[t.background.withValues(alpha:.78),t.background.withValues(alpha:.98)],
      AppSkin.premiumDark=>dark?[const Color(0xdd020b08),const Color(0xf705100c)]:[const Color(0xd9eee5cc),const Color(0xf9f7f0df)],
      AppSkin.glassmorphism=>dark?[t.background.withValues(alpha:.48),t.background.withValues(alpha:.78)]:[t.background.withValues(alpha:.66),t.background.withValues(alpha:.88)],
      AppSkin.studentFriendly=>dark?[const Color(0xb514271e),const Color(0xf014271e)]:[const Color(0xc8f9fcf4),const Color(0xf8f9fcf4)],
      AppSkin.minimalAcademic=>dark?[const Color(0xef191e19),const Color(0xff191e19)]:[const Color(0xf2f6f5ef),const Color(0xfff6f5ef)],
      AppSkin.elegantEditorial=>dark?[const Color(0xe4211e16),const Color(0xfa211e16)]:[const Color(0xeaf6f0df),const Color(0xfdf6f0df)],
      AppSkin.productivityDashboard=>dark?[const Color(0xdf0b1e22),const Color(0xfa0b1e22)]:[const Color(0xe3eef4f6),const Color(0xfceef4f6)],
      AppSkin.friendlyModern=>dark?[const Color(0xc9232a20),const Color(0xf5232a20)]:[const Color(0xd8f8f7eb),const Color(0xfbf8f7eb)],
      AppSkin.futureTech=>dark?[const Color(0xb8021710),const Color(0xf2021710)]:[const Color(0xcbe7f8ef),const Color(0xf4e7f8ef)],
      AppSkin.boldPremium=>dark?[const Color(0xd0061d16),const Color(0xfa061d16)]:[const Color(0xe3f3f6f3),const Color(0xfcf3f6f3)],
      _=>[t.background,t.background],
    };
    return Material(color:t.background,child:Stack(fit:StackFit.expand,children:[
      Opacity(opacity:imageOpacity,child:ExcludeSemantics(child:Image.asset(t.backdropAsset,fit:BoxFit.cover,alignment:alignment,cacheWidth:768))),
      DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:overlay))),
      if(t.skin==AppSkin.glassmorphism)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_GlassOrbs()))),
      if(t.skin==AppSkin.futureTech)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_LightPaths()))),
      if(t.skin==AppSkin.productivityDashboard)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_DashboardGrid()))),
      if(t.skin==AppSkin.elegantEditorial)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_EditorialRule()))),
      if(t.skin==AppSkin.boldPremium)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_BoldBands()))),
      if(t.skin==AppSkin.studentFriendly||t.skin==AppSkin.friendlyModern)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_SoftBubbles()))),
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
    final editorial=t.skin==AppSkin.elegantEditorial;
    final minimal=t.skin==AppSkin.minimalAcademic;
    final path=login?t.loginAsset:t.heroAsset;
    final alignment=switch(t.skin){AppSkin.studentFriendly||AppSkin.friendlyModern=>Alignment.centerRight,AppSkin.futureTech=>Alignment.topRight,AppSkin.elegantEditorial=>Alignment.center, _=>Alignment.centerRight};
    final label=switch(t.skin){
      AppSkin.smartCampus=>'CAMPUS · CONNECT · SUCCEED',AppSkin.premiumDark=>'FOCUS · EXCEL · ADVANCE',AppSkin.glassmorphism=>'CLEAR · CALM · LEARN',
      AppSkin.studentFriendly=>'LEARN · GROW · BELONG',AppSkin.minimalAcademic=>'READ · THINK · MASTER',AppSkin.elegantEditorial=>'READ · REFLECT · ACHIEVE',
      AppSkin.productivityDashboard=>'PLAN · TRACK · COMPLETE',AppSkin.friendlyModern=>'LEARN · SHARE · GROW',AppSkin.futureTech=>'DISCOVER · BUILD · ADVANCE',AppSkin.boldPremium=>'AMBITION · ACTION · RESULTS',_=>'LEARN · PLAN · SUCCEED'};
    final overlay=switch(t.skin){
      AppSkin.premiumDark=>[const Color(0xff07120e).withValues(alpha:.98),const Color(0xff14251d).withValues(alpha:.78),Colors.transparent],
      AppSkin.glassmorphism=>[const Color(0xff0b4c3d).withValues(alpha:.88),const Color(0xff2a7060).withValues(alpha:.50),Colors.transparent],
      AppSkin.studentFriendly=>[const Color(0xff14533b).withValues(alpha:.92),const Color(0xff519273).withValues(alpha:.52),Colors.transparent],
      AppSkin.minimalAcademic=>[const Color(0xff27352d).withValues(alpha:.96),const Color(0xff56665d).withValues(alpha:.70),Colors.transparent],
      AppSkin.elegantEditorial=>[const Color(0xff2f291e).withValues(alpha:.96),const Color(0xff66583b).withValues(alpha:.66),Colors.transparent],
      AppSkin.productivityDashboard=>[const Color(0xff073b3f).withValues(alpha:.96),const Color(0xff286879).withValues(alpha:.62),Colors.transparent],
      AppSkin.friendlyModern=>[const Color(0xff35553a).withValues(alpha:.94),const Color(0xff789268).withValues(alpha:.54),Colors.transparent],
      AppSkin.futureTech=>[const Color(0xff002a22).withValues(alpha:.98),const Color(0xff00694a).withValues(alpha:.58),Colors.transparent],
      AppSkin.boldPremium=>[const Color(0xff063c2b).withValues(alpha:.98),const Color(0xff7a5d16).withValues(alpha:.58),Colors.transparent],
      _=>[const Color(0xff002c20).withValues(alpha:.96),const Color(0xff003524).withValues(alpha:.60),Colors.transparent],
    };
    final border=t.skin==AppSkin.futureTech?t.primary.withValues(alpha:.55):t.skin==AppSkin.glassmorphism?Colors.white.withValues(alpha:.52):t.gold.withValues(alpha:.42);
    return Container(margin:const EdgeInsets.only(bottom:16),decoration:BoxDecoration(
      borderRadius:BorderRadius.circular(t.radius),border:Border.all(color:border),
      boxShadow:switch(t.skin){AppSkin.futureTech=>[BoxShadow(color:t.primary.withValues(alpha:.22),blurRadius:20)],AppSkin.boldPremium=>[BoxShadow(color:t.gold.withValues(alpha:.16),blurRadius:16)],_=>[]}),
      child:ClipRRect(borderRadius:BorderRadius.circular(t.radius-1),child:Stack(children:[
        Positioned.fill(child:ExcludeSemantics(child:Image.asset(path,fit:BoxFit.cover,alignment:alignment,cacheWidth:960))),
        Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.centerLeft,end:Alignment.centerRight,colors:overlay,stops:const [0,.58,1])))),
        if(t.skin==AppSkin.futureTech)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_LightPaths()))),
        if(t.skin==AppSkin.productivityDashboard)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_DashboardGrid(hero:true)))),
        if(t.skin==AppSkin.glassmorphism)const Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_GlassOrbs(hero:true)))),
        if(login)const Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xcc00271c)])))),
        Padding(padding:EdgeInsets.all(minimal?24:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(login?'YOUR ACADEMIC JOURNEY':label,style:TextStyle(color:t.skin==AppSkin.futureTech?t.primary:const Color(0xffffdb8b),fontSize:10,letterSpacing:1.7,fontWeight:FontWeight.w800)),
          SizedBox(height:login?74:12),
          FractionallySizedBox(widthFactor:login?.94:t.skin==AppSkin.elegantEditorial?.70:.63,child:Text(title,style:TextStyle(fontFamily:editorial?'NUReading':null,fontSize:login?28:24,height:1.15,fontWeight:FontWeight.w800,color:Colors.white))),
          const SizedBox(height:12),FractionallySizedBox(widthFactor:t.skin==AppSkin.friendlyModern?.78:.72,child:Text(subtitle,style:const TextStyle(fontSize:12,height:1.5,color:Color(0xffe5f2e9)))),
          if(action!=null)Padding(padding:const EdgeInsets.only(top:16),child:action),
          if(login)const SizedBox(height:24),
        ])),
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
    final dashboard=t.skin==AppSkin.productivityDashboard;
    final friendly=t.skin==AppSkin.studentFriendly||t.skin==AppSkin.friendlyModern;
    final saturated=bold&&grid;
    final fill=saturated?Color.lerp(tone,Colors.black,.25)!:Color.lerp(t.surface,tone,dark ? .18:.13)!;
    final ink=saturated?Colors.white:t.ink;
    final radius=BorderRadius.circular(t.radius);
    final content=Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
      _SkinGlyph(icon:icon,tone:tone,flat:t.skin==AppSkin.minimalAcademic,size:40),
      const SizedBox(height:10),Text(title,style:TextStyle(color:ink,fontWeight:FontWeight.w800,fontSize:14,height:1.2)),
      const SizedBox(height:6),Text(subtitle,style:TextStyle(color:ink.withValues(alpha:.85),fontSize:11,height:1.35)),
    ]);
    return Container(margin:EdgeInsets.only(bottom:grid?0:10),decoration:BoxDecoration(borderRadius:radius,
      gradient:LinearGradient(begin:dashboard?Alignment.centerLeft:Alignment.topLeft,end:Alignment.bottomRight,colors:[fill.withValues(alpha:glass ? .72:1),Color.lerp(fill,t.gold,glass ? .16:bold?.10:.04)!.withValues(alpha:glass ? .66:1)]),
      border:Border.all(color:glass?Colors.white.withValues(alpha:.40):t.skin==AppSkin.futureTech?t.primary.withValues(alpha:.48):friendly?t.primary.withValues(alpha:.16):tone.withValues(alpha:.13)),
      boxShadow:[if(!dark&&t.skin!=AppSkin.minimalAcademic)BoxShadow(color:t.primary.withValues(alpha:friendly?.10:.06),blurRadius:friendly?14:9,offset:const Offset(0,3))]),
      child:Material(color:Colors.transparent,child:InkWell(borderRadius:radius,onTap:onTap,child:Padding(padding:EdgeInsets.all(grid?16:14),child:grid?content:Row(children:[
        _SkinGlyph(icon:icon,tone:tone,flat:t.skin==AppSkin.minimalAcademic,size:44),
        const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:ink,fontSize:14,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,style:TextStyle(color:ink.withValues(alpha:.8),fontSize:11,height:1.35))])),
        trailing??Icon(Icons.chevron_right,color:ink,size:20),
      ])))));
  }
}

class _LightPaths extends CustomPainter {
  const _LightPaths();
  @override void paint(Canvas c,Size s){
    final p=Paint()..style=PaintingStyle.stroke..strokeWidth=.8..color=const Color(0xff46bd88).withValues(alpha:.18);
    for(var i=0;i<5;i++){final x=s.width*(.18+i*.21);c.drawPath(Path()..moveTo(x,0)..lineTo(x-55,s.height*.42)..lineTo(x+35,s.height),p);}
    final dot=Paint()..color=const Color(0xff72efb5).withValues(alpha:.24);
    for(var i=0;i<6;i++)c.drawCircle(Offset(s.width*(.12+i*.17),s.height*(.16+(i%3)*.25)),1.8,dot);
  }
  @override bool shouldRepaint(covariant _LightPaths oldDelegate)=>false;
}
class _DashboardGrid extends CustomPainter {
  const _DashboardGrid({this.hero=false});final bool hero;
  @override void paint(Canvas c,Size s){final p=Paint()..style=PaintingStyle.stroke..strokeWidth=.55..color=Colors.white.withValues(alpha:hero?.08:.055);final step=hero?28.0:38.0;for(double x=0;x<s.width;x+=step)c.drawLine(Offset(x,0),Offset(x,s.height),p);for(double y=0;y<s.height;y+=step)c.drawLine(Offset(0,y),Offset(s.width,y),p);}
  @override bool shouldRepaint(covariant _DashboardGrid oldDelegate)=>hero!=oldDelegate.hero;
}
class _GlassOrbs extends CustomPainter {
  const _GlassOrbs({this.hero=false});final bool hero;
  @override void paint(Canvas c,Size s){final a=Paint()..color=const Color(0xffbdf5df).withValues(alpha:hero?.10:.12);final b=Paint()..color=const Color(0xffffd77c).withValues(alpha:hero?.08:.07);c.drawCircle(Offset(s.width*.88,s.height*.16),hero?75:120,a);c.drawCircle(Offset(s.width*.10,s.height*.72),hero?60:95,b);}
  @override bool shouldRepaint(covariant _GlassOrbs oldDelegate)=>hero!=oldDelegate.hero;
}
class _EditorialRule extends CustomPainter {
  const _EditorialRule();
  @override void paint(Canvas c,Size s){final p=Paint()..color=const Color(0xff8a7040).withValues(alpha:.10)..strokeWidth=.7;for(double y=44;y<s.height;y+=52)c.drawLine(Offset(18,y),Offset(s.width-18,y),p);}
  @override bool shouldRepaint(covariant _EditorialRule oldDelegate)=>false;
}
class _BoldBands extends CustomPainter {
  const _BoldBands();
  @override void paint(Canvas c,Size s){final p=Paint()..color=const Color(0xffffcf30).withValues(alpha:.055);for(var i=-2;i<7;i++){final path=Path()..moveTo(i*95.0,-20)..lineTo(i*95.0+55,-20)..lineTo(i*95.0-120,s.height+20)..lineTo(i*95.0-175,s.height+20)..close();c.drawPath(path,p);}}
  @override bool shouldRepaint(covariant _BoldBands oldDelegate)=>false;
}
class _SoftBubbles extends CustomPainter {
  const _SoftBubbles();
  @override void paint(Canvas c,Size s){final p=Paint()..color=const Color(0xff73b88b).withValues(alpha:.055);for(final d in [(Offset(.86,.12),44.0),(Offset(.10,.35),26.0),(Offset(.91,.72),62.0),(Offset(.18,.88),38.0)])c.drawCircle(Offset(s.width*d.$1.dx,s.height*d.$1.dy),d.$2,p);}
  @override bool shouldRepaint(covariant _SoftBubbles oldDelegate)=>false;
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
 @override Widget build(BuildContext context){final t=SkinTokens.of(context);return ExcludeSemantics(child:Stack(fit:StackFit.expand,children:[
  Opacity(opacity:t.skin==AppSkin.minimalAcademic?.20:.42,child:Image.asset(t.backdropAsset,cacheWidth:768,fit:BoxFit.cover,alignment:Alignment.topCenter)),
  DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color.lerp(const Color(0xff003425),t.primary,.20)!.withValues(alpha:.92),Color.lerp(const Color(0xff003728),t.gold,.12)!.withValues(alpha:.78)]))),
 ]));}
}

/// Bounded vector relief, not a bitmap per icon or an animated 3D scene.
class _SkinGlyph extends StatelessWidget {
 const _SkinGlyph({required this.icon,required this.tone,required this.flat,required this.size});
 final IconData icon;final Color tone;final bool flat;final double size;
 @override Widget build(BuildContext context){
  if(flat)return SizedBox(width:size,height:size,child:Icon(icon,color:SkinTokens.of(context).primary,size:size*.65));
  return ExcludeSemantics(child:Container(width:size,height:size,decoration:BoxDecoration(
   borderRadius:BorderRadius.circular(size*.23),
   gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(tone,Colors.white,.32)!,tone,Color.lerp(tone,Colors.black,.30)!]),
   border:Border.all(color:Colors.white.withValues(alpha:.45)),
   boxShadow:[BoxShadow(color:tone.withValues(alpha:.22),blurRadius:5,offset:const Offset(0,3))]),
   child:Stack(alignment:Alignment.center,children:[
    Transform.translate(offset:const Offset(1.5,2),child:Icon(icon,size:size*.63,color:Color.lerp(tone,Colors.black,.55))),
    Icon(icon,size:size*.63,color:const Color(0xfff7f8e9)),
   ])));
 }
}
