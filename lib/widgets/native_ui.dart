import 'package:flutter/material.dart';

const nuGreen=Color(0xff006341),nuDeep=Color(0xff00452f),nuGold=Color(0xffffcf30),nuRed=Color(0xfff31e35),nuMint=Color(0xffe9f8f2);
String naira(dynamic kobo)=>'₦${((num.tryParse('$kobo')??0)/100).toStringAsFixed(2)}';
Map<String,dynamic> unpack(Map<String,dynamic> r)=>Map<String,dynamic>.from(r['data'] as Map);
List<Map<String,dynamic>> records(dynamic x)=>(x as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
Future<T?> pushNu<T>(BuildContext context,Widget page)=>Navigator.of(context).push<T>(MaterialPageRoute(builder:(_)=>page));
void nuMessage(BuildContext context,Object message)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$message')));
class BrandLogo extends StatelessWidget {
 const BrandLogo({super.key,this.size=42});final double size;
 @override Widget build(BuildContext context)=>Image.asset('assets/images/noun_update_logo.png',width:size,height:size,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.school_rounded,size:size,color:nuGold));
}
IconData serviceIcon(String id)=>switch(id){
 'fees'||'fee-check'||'wallet'=>Icons.account_balance_wallet_rounded,'courses'||'course-materials'=>Icons.menu_book_rounded,
 'course-summary'||'study-hub'=>Icons.lightbulb_rounded,'exam-summary'=>Icons.description_rounded,'calendar'=>Icons.calendar_month_rounded,
 'mock'=>Icons.desktop_windows_rounded,'result'=>Icons.bar_chart_rounded,'cgpa-calculator'=>Icons.calculate_rounded,
 'personalized-timetable'=>Icons.more_time_rounded,'marketplace'=>Icons.shopping_cart_rounded,'news'=>Icons.campaign_rounded,
 'notes'=>Icons.sticky_note_2_rounded,'timer'=>Icons.timer_rounded,'quiz'=>Icons.psychology_rounded,_=>Icons.school_rounded};
Color serviceColour(String id)=>switch(id){'course-summary'||'study-hub'||'result'||'marketplace'=>nuGold,'courses'||'course-materials'||'mock'||'personalized-timetable'||'exam-summary'=>nuRed,_=>nuGreen};
class GlossIcon extends StatelessWidget {
 const GlossIcon(this.icon,{super.key,this.color=nuGreen,this.size=56,this.label});
 final IconData icon;final Color color;final double size;final String? label;
 @override Widget build(BuildContext context)=>ExcludeSemantics(child:Container(
  width:size,height:size,decoration:BoxDecoration(borderRadius:BorderRadius.circular(size*.24),
   gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(color,Colors.white,.24)!,color,Color.lerp(color,Colors.black,.27)!]),
   border:Border.all(color:Colors.white.withValues(alpha:.7),width:1.3),
   boxShadow:[BoxShadow(color:color.withValues(alpha:.20),blurRadius:7,offset:const Offset(0,5)),BoxShadow(color:Colors.white.withValues(alpha:.8),blurRadius:1,offset:const Offset(-1,-1))]),
  child:ClipRRect(borderRadius:BorderRadius.circular(size*.22),child:Stack(alignment:Alignment.center,children:[
   Positioned(top:1,left:2,right:2,child:Container(height:size*.40,decoration:BoxDecoration(borderRadius:BorderRadius.circular(size*.2),gradient:LinearGradient(colors:[Colors.white.withValues(alpha:.18),Colors.white.withValues(alpha:0)],begin:Alignment.topCenter,end:Alignment.bottomCenter)))),
   if(label!=null)Text(label!,style:TextStyle(fontSize:size*.48,fontWeight:FontWeight.w800,color:Colors.white,shadows:const [Shadow(color:Color(0x55000000),offset:Offset(1,2),blurRadius:2)]))
   else ...[Transform.translate(offset:const Offset(1.7,2.7),child:Icon(icon,size:size*.58,color:Color.lerp(color,Colors.black,.50))),Transform.translate(offset:const Offset(.7,1.3),child:Icon(icon,size:size*.58,color:const Color(0xffd5e9df))),Icon(icon,size:size*.58,color:Colors.white)],
  ]))));
}
String serviceCaption(String id)=>switch(id){'fees'=>'Check school fees and breakdown','cgpa-calculator'=>'Calculate your CGPA instantly','personalized-timetable'=>'Create your study schedule','result'=>'Check your exam results','courses'=>'Access study materials','calendar'=>'View important dates and events','marketplace'=>'Buy and sell study essentials','mock'=>'Practise with past questions','news'=>'Stay informed on campus news','course-summary'=>'Understand every unit','exam-summary'=>'Focus your revision',_=>'Explore student resources'};
String serviceLabel(String id,String fallback)=>switch(id){'courses'=>'Course Materials','news'=>'News & Updates','mock'=>'Mock e-Exam',_=>fallback};
class LearningBanner extends StatelessWidget {
 const LearningBanner({super.key});
 @override Widget build(BuildContext context)=>NuPanel(color:nuMint,padding:14,child:Row(children:[
  const GlossIcon(Icons.school_rounded,size:60),const SizedBox(width:14),
  const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Smarter Tools\nBrighter Tomorrow',style:TextStyle(color:nuDeep,fontSize:17,fontWeight:FontWeight.w800,height:1.15)),SizedBox(height:7),Text('Access essential academic tools in one place.',style:TextStyle(fontSize:11,height:1.3))])),
 ]));
}
class StudentHero extends StatelessWidget {
 const StudentHero({super.key,this.title='Welcome back!',this.subtitle='Stay informed, stay on track and be exam-ready always.',this.height=255});
 final String title,subtitle;final double height;
 @override Widget build(BuildContext context)=>SizedBox(height:height,child:Stack(fit:StackFit.expand,children:[
  Image.asset('assets/images/student-hero.webp',fit:BoxFit.cover,alignment:Alignment.centerRight),
  const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xbb003f2b),Color(0x00003f2b)],stops:[0,.75]))),
  Align(alignment:Alignment.centerLeft,child:FractionallySizedBox(widthFactor:.52,child:Padding(padding:const EdgeInsets.fromLTRB(18,10,0,10),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:Colors.white,height:1.12)),const SizedBox(height:10),Text(subtitle,style:const TextStyle(fontSize:12,color:Colors.white,height:1.4))])))),
 ]));
}
class NuTitle extends StatelessWidget {const NuTitle(this.title,{super.key,this.subtitle,this.trailing});final String title;final String? subtitle;final Widget? trailing;
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:16,bottom:10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:Color(0xff101d18))),if(subtitle!=null)Padding(padding:const EdgeInsets.only(top:5),child:Text(subtitle!,style:const TextStyle(fontSize:13,color:Color(0xff687787))))])),if(trailing!=null)trailing!]));}
class NuPanel extends StatelessWidget {const NuPanel({required this.child,super.key,this.color=Colors.white,this.padding=16});final Widget child;final Color color;final double padding;
 @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:12),padding:EdgeInsets.all(padding),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(18),border:Border.all(color:Color.lerp(color,nuGreen,.10)!),boxShadow:const [BoxShadow(color:Color(0x06003422),blurRadius:12,offset:Offset(0,4))]),child:Material(color:Colors.transparent,child:child));}
class NuPage extends StatelessWidget {const NuPage({super.key,required this.title,required this.child,this.actions});final String title;final Widget child;final List<Widget>? actions;
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:nuDeep,appBar:AppBar(backgroundColor:nuDeep,foregroundColor:Colors.white,title:Row(children:[const BrandLogo(size:30),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('NOUN Update',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:Color(0xffc9e9dc)))]))]),actions:actions),body:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(24)),child:ColoredBox(color:const Color(0xfff8faf9),child:SafeArea(top:false,child:child))));}
class NativeUnavailable extends StatelessWidget {const NativeUnavailable(this.title,{super.key});final String title;
 @override Widget build(BuildContext context)=>NuPage(title:title,child:Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[GlossIcon(serviceIcon(title)),const SizedBox(height:24),Text('$title is not connected yet',textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:12),const Text('This service will become available here when its app integration is enabled. You can continue using the other app tools.',textAlign:TextAlign.center),const SizedBox(height:20),OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('Back to tools'))]))));}
class AsyncError extends StatelessWidget {const AsyncError(this.error,this.retry,{super.key});final Object error;final VoidCallback retry;
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_rounded,size:36,color:nuGreen),const SizedBox(height:12),Text('$error',textAlign:TextAlign.center),TextButton(onPressed:retry,child:const Text('Try again'))]));}
class GreenBanner extends StatelessWidget {const GreenBanner({super.key,required this.title,required this.text,required this.icon,this.action});final String title,text;final IconData icon;final Widget? action;
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[nuDeep,nuGreen,Color(0xff149269)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:Colors.white,height:1.13)),const SizedBox(height:9),Text(text,style:const TextStyle(color:Color(0xffd8f7e8),fontSize:13)),if(action!=null)Padding(padding:const EdgeInsets.only(top:12),child:action)])),const SizedBox(width:10),Icon(icon,size:64,color:nuGold,shadows:const [Shadow(color:Color(0x66000000),offset:Offset(0,5),blurRadius:8)])]));}

class PhotoBanner extends StatelessWidget {
 const PhotoBanner({super.key,required this.title,required this.text,required this.onTap});
 final String title,text;final VoidCallback onTap;
 @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(16),child:SizedBox(height:MediaQuery.textScalerOf(context).scale(14)>18?250:176,child:Stack(fit:StackFit.expand,children:[
  Image.asset('assets/images/student-hero.webp',fit:BoxFit.cover,alignment:Alignment.topRight),
  const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xf000472f),Color(0xa0005039),Color(0x0000472f)],stops:[0,.48,1]))),
  Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('STUDENT PLANNER',style:TextStyle(fontSize:8,letterSpacing:1,color:nuGold,fontWeight:FontWeight.w800)),const SizedBox(height:6),FractionallySizedBox(widthFactor:.64,child:Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,height:1.08,color:Colors.white))),const SizedBox(height:7),FractionallySizedBox(widthFactor:.62,child:Text(text,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:Colors.white))),const Spacer(),FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:nuGold,foregroundColor:nuDeep,minimumSize:const Size(0,30),padding:const EdgeInsets.symmetric(horizontal:13),textStyle:const TextStyle(fontSize:10,fontWeight:FontWeight.w800)),onPressed:onTap,icon:const Icon(Icons.arrow_forward,size:14),label:const Text('View academic calendar'))])),
 ])));
}
