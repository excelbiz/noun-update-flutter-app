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
 const GlossIcon(this.icon,{super.key,this.color=nuGreen,this.size=56});final IconData icon;final Color color;final double size;
 @override Widget build(BuildContext context)=>ExcludeSemantics(child:Container(width:size,height:size,decoration:BoxDecoration(borderRadius:BorderRadius.circular(size*.24),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(color,Colors.white,.2)!,color,Color.lerp(color,Colors.black,.25)!]),border:Border.all(color:Colors.white.withValues(alpha:.55),width:1.5),boxShadow:[BoxShadow(color:color.withValues(alpha:.24),blurRadius:7,offset:const Offset(0,5)),BoxShadow(color:Colors.white.withValues(alpha:.8),blurRadius:1,offset:const Offset(-1,-1))]),child:Icon(icon,size:size*.58,color:Colors.white,shadows:const [Shadow(color:Color(0x55000000),offset:Offset(1,3),blurRadius:3)])));
}
class NuTitle extends StatelessWidget {const NuTitle(this.title,{super.key,this.subtitle,this.trailing});final String title;final String? subtitle;final Widget? trailing;
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:20,bottom:12),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:Color(0xff101d18))),if(subtitle!=null)Padding(padding:const EdgeInsets.only(top:5),child:Text(subtitle!,style:const TextStyle(fontSize:13,color:Color(0xff687787))))])),if(trailing!=null)trailing!]));}
class NuPanel extends StatelessWidget {const NuPanel({required this.child,super.key,this.color=Colors.white,this.padding=16});final Widget child;final Color color;final double padding;
 @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:12),padding:EdgeInsets.all(padding),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(18),border:Border.all(color:Color.lerp(color,nuGreen,.10)!),boxShadow:const [BoxShadow(color:Color(0x06003422),blurRadius:12,offset:Offset(0,4))]),child:Material(color:Colors.transparent,child:child));}
class NuPage extends StatelessWidget {const NuPage({super.key,required this.title,required this.child,this.actions});final String title;final Widget child;final List<Widget>? actions;
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:nuDeep,appBar:AppBar(backgroundColor:nuDeep,foregroundColor:Colors.white,title:Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),actions:actions),body:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(24)),child:ColoredBox(color:const Color(0xfff8faf9),child:SafeArea(top:false,child:child))));}
class NativeUnavailable extends StatelessWidget {const NativeUnavailable(this.title,{super.key});final String title;
 @override Widget build(BuildContext context)=>NuPage(title:title,child:Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[GlossIcon(serviceIcon(title)),const SizedBox(height:24),Text('$title is not connected yet',textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:12),const Text('This service will become available here when its app integration is enabled. You can continue using the other app tools.',textAlign:TextAlign.center),const SizedBox(height:20),OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('Back to tools'))]))));}
class AsyncError extends StatelessWidget {const AsyncError(this.error,this.retry,{super.key});final Object error;final VoidCallback retry;
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_rounded,size:36,color:nuGreen),const SizedBox(height:12),Text('$error',textAlign:TextAlign.center),TextButton(onPressed:retry,child:const Text('Try again'))]));}
class GreenBanner extends StatelessWidget {const GreenBanner({super.key,required this.title,required this.text,required this.icon,this.action});final String title,text;final IconData icon;final Widget? action;
 @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[nuDeep,nuGreen,Color(0xff149269)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:Colors.white,height:1.13)),const SizedBox(height:9),Text(text,style:const TextStyle(color:Color(0xffd8f7e8),fontSize:13)),if(action!=null)Padding(padding:const EdgeInsets.only(top:12),child:action)])),const SizedBox(width:10),Icon(icon,size:64,color:nuGold,shadows:const [Shadow(color:Color(0x66000000),offset:Offset(0,5),blurRadius:8)])]));}
