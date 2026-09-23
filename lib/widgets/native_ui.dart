import 'package:flutter/material.dart';

const nuGreen=Color(0xff006341),nuDeep=Color(0xff00452f),nuGold=Color(0xffffcf30),nuRed=Color(0xfff31e35),nuMint=Color(0xffe9f8f2);
bool nuIsDark(BuildContext context)=>Theme.of(context).brightness==Brightness.dark;
Color nuInk(BuildContext context)=>Theme.of(context).colorScheme.onSurface;
Color nuMuted(BuildContext context)=>Theme.of(context).colorScheme.onSurfaceVariant;
Color nuTint(BuildContext context)=>Theme.of(context).colorScheme.primaryContainer;
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
 'pas-status'=>Icons.fact_check_rounded,'tma-archive'||'past-questions'=>Icons.inventory_2_rounded,
 'study-planner'=>Icons.event_note_rounded,'exam-practice.html'||'tma-service'=>Icons.quiz_rounded,
 'ai-course-tutor'||'student-advisor'=>Icons.forum_rounded,'ai-exam-coach'=>Icons.psychology_rounded,
 'ai-result-analytics'||'ai-result-analytics-auto'||'ai-result-analytics-dashboard'||'transcript-analyzer'||'gpa-rescue'=>Icons.insights_rounded,
 'graduation'||'graduation-predictor'=>Icons.workspace_premium_rounded,
 'smart-eligibility-finder'||'eligibility_checker'=>Icons.rule_rounded,'admission-requirements'=>Icons.checklist_rounded,
 'programmes'=>Icons.account_tree_rounded,'study-centres'=>Icons.location_city_rounded,
 'project-topic-generator'||'topic-generator'=>Icons.manage_search_rounded,
 'generate-project-slip'||'generate-seminar-slip'=>Icons.print_rounded,'project-seminar'||'projects'=>Icons.folder_copy_rounded,
 'business-plan'||'gst302'=>Icons.business_center_rounded,'turnitin'=>Icons.plagiarism_rounded,
 'dashboard'||'student-success-hub'=>Icons.dashboard_rounded,'my-account'=>Icons.person_rounded,'cart'=>Icons.shopping_bag_rounded,
 'career-hub'||'career-services'=>Icons.work_outline_rounded,'scholarships'=>Icons.savings_rounded,
 'fos'=>Icons.science_rounded,'foas'=>Icons.eco_rounded,'foa'=>Icons.palette_rounded,'fol'=>Icons.balance_rounded,
 'foms'=>Icons.business_rounded,'foss'=>Icons.groups_rounded,'foe'=>Icons.cast_for_education_rounded,'fohs'=>Icons.health_and_safety_rounded,'foc'=>Icons.computer_rounded,
 'search'=>Icons.search_rounded,'glossary'=>Icons.abc_rounded,'about-noun'||'about'=>Icons.info_rounded,
 'faqs'=>Icons.help_outline_rounded,'file-resizer'=>Icons.photo_size_select_large_rounded,'support'||'contact'=>Icons.support_agent_rounded,
 'premium'=>Icons.stars_rounded,'guides'=>Icons.explore_rounded,'noun-student-resource-centre'=>Icons.local_library_rounded,
 'editorial-policy'||'corrections'||'sources'||'advertising'=>Icons.policy_rounded,'privacy-policy'=>Icons.privacy_tip_rounded,'terms-of-use'=>Icons.gavel_rounded,
 'notes'=>Icons.sticky_note_2_rounded,'timer'=>Icons.timer_rounded,'quiz'=>Icons.psychology_rounded,_=>Icons.widgets_rounded};
Color serviceColour(String id)=>switch(id){'course-summary'||'study-hub'||'result'||'marketplace'=>nuGold,'courses'||'course-materials'||'mock'||'personalized-timetable'||'exam-summary'=>nuRed,_=>nuGreen};
class GlossIcon extends StatelessWidget {
 const GlossIcon(this.icon,{super.key,this.color=nuGreen,this.size=56,this.label});
 final IconData icon;final Color color;final double size;final String? label;
 @override Widget build(BuildContext context)=>ExcludeSemantics(child:Container(
  width:size,height:size,decoration:BoxDecoration(borderRadius:BorderRadius.circular(size*.24),
   gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color.lerp(color,Colors.white,.24)!,color,Color.lerp(color,Colors.black,.27)!]),
   border:Border.all(color:Colors.white.withValues(alpha:.7),width:1.3),
   boxShadow:[BoxShadow(color:color.withValues(alpha:.20),blurRadius:7,offset:Offset(0,5)),BoxShadow(color:Colors.white.withValues(alpha:.8),blurRadius:1,offset:Offset(-1,-1))]),
  child:ClipRRect(borderRadius:BorderRadius.circular(size*.22),child:Stack(alignment:Alignment.center,children:[
   Positioned(top:1,left:2,right:2,child:Container(height:size*.40,decoration:BoxDecoration(borderRadius:BorderRadius.circular(size*.2),gradient:LinearGradient(colors:[Colors.white.withValues(alpha:.18),Colors.white.withValues(alpha:0)],begin:Alignment.topCenter,end:Alignment.bottomCenter)))),
   if(label!=null)Text(label!,style:TextStyle(fontSize:size*.48,fontWeight:FontWeight.w800,color:Colors.white,shadows:[Shadow(color:Color(0x55000000),offset:Offset(1,2),blurRadius:2)]))
   else ...[Transform.translate(offset:Offset(1.7,2.7),child:Icon(icon,size:size*.58,color:Color.lerp(color,Colors.black,.50))),Transform.translate(offset:Offset(.7,1.3),child:Icon(icon,size:size*.58,color:Color(0xffd5e9df))),Icon(icon,size:size*.58,color:Colors.white)],
  ]))));
}
String serviceCaption(String id)=>switch(id){'fees'=>'Check school fees and breakdown','cgpa-calculator'=>'Calculate your CGPA instantly','personalized-timetable'=>'Create your study schedule','result'=>'Check your exam results','courses'=>'Access study materials','calendar'=>'View important dates and events','marketplace'=>'Buy and sell study essentials','mock'=>'Practise with past questions','news'=>'Stay informed on campus news','course-summary'=>'Understand every unit','exam-summary'=>'Focus your revision',_=>'Explore student resources'};
String serviceLabel(String id,String fallback)=>switch(id){'courses'=>'Course Materials','news'=>'News & Updates','mock'=>'Mock e-Exam',_=>fallback};
class LearningBanner extends StatelessWidget {
 const LearningBanner({super.key});
 @override Widget build(BuildContext context)=>ServiceHero(title:'Your academic toolkit',subtitle:'Plan your semester, find resources and manage your studies.',icon:Icons.handyman_rounded);
}
class StudentHero extends StatelessWidget {
 const StudentHero({super.key,this.title='Welcome back!',this.subtitle='Your resources, academic updates and study progress in one place.',this.height=255});
 final String title,subtitle;final double height;
 @override Widget build(BuildContext context)=>SizedBox(height:height,child:Stack(fit:StackFit.expand,children:[
  Image.asset('assets/images/student-hero.webp',cacheWidth:1024,fit:BoxFit.cover,alignment:Alignment.centerRight),
  DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xbb003f2b),Color(0x00003f2b)],stops:[0,.75]))),
  Align(alignment:Alignment.centerLeft,child:FractionallySizedBox(widthFactor:.52,child:Padding(padding:EdgeInsets.fromLTRB(18,10,0,10),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:Colors.white,height:1.12)),SizedBox(height:10),Text(subtitle,style:TextStyle(fontSize:12,color:Colors.white,height:1.4))])))),
 ]));
}
class NuTitle extends StatelessWidget {const NuTitle(this.title,{super.key,this.subtitle,this.trailing});final String title;final String? subtitle;final Widget? trailing;
 @override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.only(top:16,bottom:10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:nuInk(context))),if(subtitle!=null)Padding(padding:EdgeInsets.only(top:5),child:Text(subtitle!,style:TextStyle(fontSize:13,color:nuMuted(context))))])),if(trailing!=null)trailing!]));}
class NuPanel extends StatelessWidget {const NuPanel({required this.child,super.key,this.color=Colors.white,this.padding=16});final Widget child;final Color color;final double padding;
 @override Widget build(BuildContext context)=>Container(margin:EdgeInsets.only(bottom:12),padding:EdgeInsets.all(padding),decoration:BoxDecoration(color:nuIsDark(context)?(color==Colors.white?Theme.of(context).colorScheme.surfaceContainerLow:Color.lerp(Theme.of(context).colorScheme.surface,color,.10)):color,borderRadius:BorderRadius.circular(18),border:Border.all(color:Theme.of(context).colorScheme.outlineVariant),boxShadow:[BoxShadow(color:Color(0x06003422),blurRadius:12,offset:Offset(0,4))]),child:Material(color:Colors.transparent,child:child));}
class NuPage extends StatelessWidget {const NuPage({super.key,required this.title,required this.child,this.actions});final String title;final Widget child;final List<Widget>? actions;
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:nuDeep,appBar:AppBar(backgroundColor:nuDeep,foregroundColor:Colors.white,title:Row(children:[BrandLogo(size:30),SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOUN Update',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,color:Color(0xffc9e9dc)))]))]),actions:actions),body:ClipRRect(borderRadius:BorderRadius.vertical(top:Radius.circular(24)),child:ColoredBox(color:Theme.of(context).scaffoldBackgroundColor,child:SafeArea(top:false,child:child))));}
class NativeUnavailable extends StatelessWidget {const NativeUnavailable(this.title,{super.key});final String title;
 @override Widget build(BuildContext context)=>NuPage(title:title,child:Center(child:Padding(padding:EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[GlossIcon(serviceIcon(title)),SizedBox(height:24),Text('$title is not connected yet',textAlign:TextAlign.center,style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),SizedBox(height:12),Text('This service will become available here when its app integration is enabled. You can continue using the other app tools.',textAlign:TextAlign.center),SizedBox(height:20),OutlinedButton(onPressed:()=>Navigator.pop(context),child:Text('Back to tools'))]))));}
class AsyncError extends StatelessWidget {const AsyncError(this.error,this.retry,{super.key});final Object error;final VoidCallback retry;
 @override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.cloud_off_rounded,size:36,color:Theme.of(context).colorScheme.primary),SizedBox(height:12),Text('$error',textAlign:TextAlign.center),TextButton(onPressed:retry,child:Text('Try again'))]));}
class GreenBanner extends StatelessWidget {const GreenBanner({super.key,required this.title,required this.text,required this.icon,this.action});final String title,text;final IconData icon;final Widget? action;
 @override Widget build(BuildContext context)=>Container(padding:EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:LinearGradient(colors:[nuDeep,nuGreen,Color(0xff149269)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:Colors.white,height:1.13)),SizedBox(height:9),Text(text,style:TextStyle(color:Color(0xffd8f7e8),fontSize:13)),if(action!=null)Padding(padding:EdgeInsets.only(top:12),child:action)])),SizedBox(width:10),ToolArtwork(icon:icon)]));}

class PhotoBanner extends StatelessWidget {
 const PhotoBanner({super.key,required this.title,required this.text,required this.onTap});
 final String title,text;final VoidCallback onTap;
 @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(16),child:SizedBox(height:MediaQuery.textScalerOf(context).scale(14)>18?250:176,child:Stack(fit:StackFit.expand,children:[
  Image.asset('assets/images/student-hero.webp',cacheWidth:1024,fit:BoxFit.cover,alignment:Alignment.topRight),
  DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xf000472f),Color(0xa0005039),Color(0x0000472f)],stops:[0,.48,1]))),
  Padding(padding:EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('STUDENT PLANNER',style:TextStyle(fontSize:8,letterSpacing:1,color:nuGold,fontWeight:FontWeight.w800)),SizedBox(height:6),FractionallySizedBox(widthFactor:.64,child:Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,height:1.08,color:Colors.white))),SizedBox(height:7),FractionallySizedBox(widthFactor:.62,child:Text(text,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,color:Colors.white))),Spacer(),FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:nuGold,foregroundColor:nuDeep,minimumSize:Size(0,30),padding:EdgeInsets.symmetric(horizontal:13),textStyle:TextStyle(fontFamily:Theme.of(context).textTheme.bodyMedium?.fontFamily,fontSize:10,fontWeight:FontWeight.w800)),onPressed:onTap,icon:Icon(Icons.arrow_forward,size:14),label:Text('View academic calendar'))])),
 ])));
}

class CentralWalletCard extends StatelessWidget {
 const CentralWalletCard({super.key,required this.balance,required this.onFund,required this.onHistory,required this.onTools});
 final String balance;final VoidCallback onFund,onHistory,onTools;
 @override Widget build(BuildContext context)=>Container(padding:EdgeInsets.all(14),decoration:BoxDecoration(borderRadius:BorderRadius.circular(17),gradient:LinearGradient(colors:[Color(0xff003f2e),Color(0xff007146)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[GlossIcon(Icons.account_balance_wallet_rounded,size:52),SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Central Wallet',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:Colors.white)),FittedBox(fit:BoxFit.scaleDown,child:Text(balance,style:TextStyle(fontSize:27,fontWeight:FontWeight.w800,color:Colors.white))),Text('One wallet. More possibilities.',style:TextStyle(fontSize:10,color:Color(0xffd9f5e8)))]))]),
  SizedBox(height:14),Wrap(spacing:7,runSpacing:6,children:[FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:nuGold,foregroundColor:nuDeep,minimumSize:Size(0,36),padding:EdgeInsets.symmetric(horizontal:10),textStyle:TextStyle(fontFamily:Theme.of(context).textTheme.bodyMedium?.fontFamily,fontSize:11,fontWeight:FontWeight.w800)),onPressed:onFund,icon:Icon(Icons.add_circle,size:16),label:Text('Add funds')),OutlinedButton.icon(style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:BorderSide(color:Color(0xff39a680)),minimumSize:Size(0,36),padding:EdgeInsets.symmetric(horizontal:10),textStyle:TextStyle(fontFamily:Theme.of(context).textTheme.bodyMedium?.fontFamily,fontSize:11)),onPressed:onHistory,icon:Icon(Icons.receipt_long,size:16),label:Text('History')),TextButton(style:TextButton.styleFrom(foregroundColor:Colors.white,textStyle:TextStyle(fontFamily:Theme.of(context).textTheme.bodyMedium?.fontFamily,fontSize:11)),onPressed:onTools,child:Text('Use with tools →'))]),
 ]));
}

/// Lightweight vector artwork: no image requests, animation controller or bitmap files.
class ToolArtwork extends StatelessWidget {
 const ToolArtwork({super.key,required this.icon});
 final IconData icon;
 @override Widget build(BuildContext context)=>ExcludeSemantics(child:SizedBox(width:86,height:86,child:Stack(alignment:Alignment.center,children:[
  Transform.rotate(angle:-.15,child:Container(width:66,height:73,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(14),border:Border.all(color:Theme.of(context).colorScheme.outlineVariant)))),
  Positioned(top:5,right:3,child:Icon(Icons.auto_awesome_rounded,size:17,color:nuGold)),
  Transform.rotate(angle:.07,child:GlossIcon(icon,size:54)),
  Positioned(bottom:0,left:2,child:GlossIcon(Icons.check_rounded,color:nuGold,size:24)),
 ])));
}
class ServiceHero extends StatelessWidget {
 const ServiceHero({super.key,required this.title,required this.subtitle,required this.icon});
 final String title,subtitle;final IconData icon;
 @override Widget build(BuildContext context)=>NuPanel(color:nuMint,child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:nuInk(context))),SizedBox(height:8),Text(subtitle,style:TextStyle(fontSize:12,color:nuMuted(context),height:1.45))])),SizedBox(width:12),ToolArtwork(icon:icon)]));
}
