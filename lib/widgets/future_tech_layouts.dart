import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/skin_theme.dart';
import '../core/study_state_store.dart';
import 'native_ui.dart';

const techNeon=Color(0xff33e799),techGold=Color(0xffffd858);
TextStyle techText(BuildContext c,{double size=13,Color? color,FontWeight weight=FontWeight.w400})=>
 TextStyle(fontFamily:'NUSans',fontSize:size,height:1.22,fontWeight:weight,color:color??SkinTokens.of(c).ink);
Color techTone(String id)=>switch(id){'my-courses'||'result'=>const Color(0xffd8273b),
 'course-summary'||'fees'=>const Color(0xff0aaf70),'exam-summary'||'cgpa-calculator'=>const Color(0xffe38717),
 'pas-status'||'mock'=>const Color(0xff7137d7),'project-topic-generator'=>const Color(0xffe9b21c),
 _=>const Color(0xff367fde)};
IconData techIcon(String id)=>switch(id){'my-courses'=>Icons.menu_book_rounded,'course-summary'=>Icons.article_rounded,
 'exam-summary'=>Icons.assignment_rounded,'past-questions'=>Icons.help_rounded,'courses'=>Icons.folder_rounded,
 'study-hub'=>Icons.school_rounded,_=>serviceIcon(id)};

class TechPanel extends StatelessWidget{
 const TechPanel({super.key,required this.child,this.onTap,this.padding=12,this.tone});
 final Widget child;final VoidCallback? onTap;final double padding;final Color? tone;
 @override Widget build(BuildContext c){final t=SkinTokens.of(c),dark=nuIsDark(c),accent=tone??t.primary;
  return Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),
   gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:dark?
    [Color.lerp(t.surface,accent,.12)!,t.surface,Color.lerp(t.background,accent,.08)!]:[t.surface,Color.lerp(t.surface,accent,.035)!]),
   border:Border.all(color:accent.withValues(alpha:dark?.36:.22)),
   boxShadow:[BoxShadow(color:accent.withValues(alpha:dark?.07:.04),blurRadius:12)]),
   child:Material(color:Colors.transparent,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),child:Padding(padding:EdgeInsets.all(padding),child:child))));
 }
}
class TechTopBar extends StatelessWidget implements PreferredSizeWidget{
 const TechTopBar({super.key,required this.page,required this.name,required this.onNotifications,required this.onSettings,this.scale=1});
 final int page;final String name;final double scale;final VoidCallback onNotifications,onSettings;
 @override Size get preferredSize=>Size.fromHeight(72+math.max(0.0,scale-1)*60);
 @override Widget build(BuildContext c){final t=SkinTokens.of(c);
  final title=switch(page){1=>'Study',2=>'Tools',3=>'Updates',_=>'Profile'};
  final subtitle=switch(page){1=>'Everything you need to excel',2=>'Helpful utilities for NOUN students',3=>'Stay informed. Stay ahead.',_=>'Your NOUN journey, organised'};
  return AppBar(backgroundColor:t.background,foregroundColor:t.ink,toolbarHeight:preferredSize.height,elevation:0,scrolledUnderElevation:0,titleSpacing:16,
   title:Row(children:[Container(width:39,height:39,decoration:BoxDecoration(shape:BoxShape.circle,color:page==0?t.ink:t.primary.withValues(alpha:.08),border:Border.all(color:t.primary.withValues(alpha:.45))),
    child:Icon(page==0?Icons.person:page==1?Icons.check_circle_outline:page==2?Icons.handyman_outlined:Icons.person_outline,color:page==0?t.heroSurface:t.primary,size:page==0?29:33)),
    const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     if(page==0)Text('Hello,',style:techText(c,size:10)),Text(page==0?'${name.isEmpty?'NOUN Student':name} 👋':title,maxLines:2,overflow:TextOverflow.ellipsis,style:techText(c,size:page==0?15:24,weight:FontWeight.w700)),
     const SizedBox(height:3),Text(page==0?'Keep going, greater things ahead!':subtitle,maxLines:2,style:techText(c,size:10,color:t.ink.withValues(alpha:.76))),
    ]))]),actions:[if(page==0||page==3)IconButton(tooltip:'Notifications',onPressed:onNotifications,icon:Icon(Icons.notifications_rounded,color:t.primary,size:22)),
    if(page==4)IconButton(tooltip:'Appearance & settings',onPressed:onSettings,icon:const Icon(Icons.settings_outlined,size:22))]);
 }
}
class TechNavigation extends StatelessWidget{
 const TechNavigation({super.key,required this.index,required this.onChanged,required this.onCourses});
 final int index;final ValueChanged<int> onChanged;final VoidCallback onCourses;
 @override Widget build(BuildContext c){final t=SkinTokens.of(c);
  Widget destination(int page,String label,IconData icon){final selected=index==page||(page==2&&index==3),tone=selected?(page==1?t.primary:nuIsDark(c)?techGold:t.gold):t.ink.withValues(alpha:.72);
   return Expanded(child:Semantics(button:true,selected:selected,label:label,child:InkWell(onTap:()=>onChanged(page),borderRadius:BorderRadius.circular(12),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:21,color:tone),const SizedBox(height:4),Text(label,style:techText(c,size:9,color:tone,weight:selected?FontWeight.w700:FontWeight.w400))]))));}
  return SafeArea(top:false,child:Container(height:70+math.max(0.0,MediaQuery.textScalerOf(c).scale(12)/12-1)*20,padding:const EdgeInsets.symmetric(horizontal:10),
   decoration:BoxDecoration(color:t.background,border:Border(top:BorderSide(color:t.primary.withValues(alpha:.28))),borderRadius:const BorderRadius.vertical(top:Radius.circular(18))),
   child:Row(children:[destination(0,'Home',Icons.home_rounded),destination(1,'Study',Icons.menu_book_outlined),
    Expanded(child:Center(child:Tooltip(message:'My Courses hub',child:Semantics(button:true,label:'My Courses hub',child:InkWell(onTap:onCourses,borderRadius:BorderRadius.circular(32),child:Container(width:56,height:56,
     decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[Color.lerp(t.heroSurface,techGold,.20)!,t.heroSurface]),border:Border.all(color:techGold,width:1.8),boxShadow:[BoxShadow(color:techGold.withValues(alpha:.24),blurRadius:10)]),
     child:Icon(Icons.school_rounded,size:28,color:t.primary))))))),destination(2,'Tools',Icons.grid_view_rounded),destination(4,'Profile',Icons.person_outline_rounded)])));
 }
}
class TechResourceRow extends StatelessWidget{
 const TechResourceRow({super.key,required this.id,required this.title,required this.caption,required this.onTap});
 final String id,title,caption;final VoidCallback onTap;
 @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:9),child:TechPanel(onTap:onTap,child:Row(children:[
  GlossIcon(techIcon(id),color:techTone(id),size:43),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(title,style:techText(c,size:14,weight:FontWeight.w700)),const SizedBox(height:5),Text(caption,style:techText(c,size:10,color:SkinTokens.of(c).ink.withValues(alpha:.78))),
  ])),const SizedBox(width:5),const Icon(Icons.chevron_right,size:21),])));
}
class TechResourceLayout extends StatelessWidget{
 const TechResourceLayout({super.key,required this.services,required this.study,required this.onOpen,required this.onCourses,required this.onSearch,required this.search,required this.onSearchChanged,required this.onTogglePin,required this.pinned,required this.onUpdates});
 final List<Map<String,dynamic>> services;final bool study;final void Function(Map<String,dynamic>) onOpen,onTogglePin;
 final VoidCallback onCourses,onSearch,onUpdates;final ValueChanged<String> onSearchChanged;final String search;final Set<String> pinned;
 @override Widget build(BuildContext c){
  final ids=study?['my-courses','course-summary','exam-summary','past-questions','courses','study-hub']:['fees','pas-status','personalized-timetable','result','cgpa-calculator','mock','project-topic-generator'];
  const captions={'my-courses':'View and manage all your courses','course-summary':'Key points and simplified notes','exam-summary':'Likely questions and exam focus','past-questions':'Access past questions & answers','courses':'Download study materials','study-hub':'Smart resources for better learning',
   'fees':'Check current school fees','pas-status':'Check your PAS clearance status','personalized-timetable':'Create and manage your study plan','result':'Check and track your results','cgpa-calculator':'Calculate your CGPA instantly','mock':'Practise with CBT-style questions','project-topic-generator':'Get research project topic ideas'};
  final rows=<Widget>[];
  for(final id in ids){if(id=='my-courses'){rows.add(TechResourceRow(id:id,title:'My Courses',caption:captions[id]!,onTap:onCourses));continue;}
   final found=services.where((s)=>s['id']==id);if(found.isEmpty)continue;final s=found.first;
   rows.add(TechResourceRow(id:id,title:serviceLabel(id,'${s['label']}'),caption:captions[id]!,onTap:()=>onOpen(s)));
  }
  return ListView(key:PageStorageKey(study?'study':'tools'),padding:const EdgeInsets.fromLTRB(16,7,16,24),children:[...rows,
   if(study)ClipRRect(borderRadius:BorderRadius.circular(12),child:ExcludeSemantics(child:Image.asset('assets/images/skins/study.webp',height:135,fit:BoxFit.cover,alignment:Alignment.bottomRight))),
   const SizedBox(height:14),Text(study?'Your library':'All tools',style:techText(c,size:16,weight:FontWeight.w700)),const SizedBox(height:10),
   if(!study)TextField(onChanged:onSearchChanged,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Find a tool')),
   for(final s in services.where((s)=>!ids.contains('${s['id']}')))Padding(padding:const EdgeInsets.only(top:9),child:TechPanel(padding:0,child:ListTile(
    leading:GlossIcon(serviceIcon('${s['id']}'),color:techTone('${s['id']}'),size:35),title:Text(serviceLabel('${s['id']}','${s['label']}')),onTap:()=>onOpen(s),
    trailing:IconButton(tooltip:pinned.contains('${s['id']}')?'Unpin tool':'Pin tool',onPressed:()=>onTogglePin(s),icon:Icon(pinned.contains('${s['id']}')?Icons.push_pin:Icons.push_pin_outlined,size:18))))),
   const SizedBox(height:12),OutlinedButton.icon(onPressed:onUpdates,icon:const Icon(Icons.campaign_outlined),label:const Text('News, guides & scholarships')),
  ]);
 }
}
class TechNotice extends StatelessWidget{
 const TechNotice({super.key,required this.feed,required this.onOpen});final Future<Map<String,dynamic>> feed;final void Function(Map<String,dynamic>) onOpen;
 @override Widget build(BuildContext c)=>FutureBuilder<Map<String,dynamic>>(future:feed,builder:(c,s){final rows=records(s.data?['items']);if(rows.isEmpty)return const SizedBox.shrink();final row=rows.first;
  return TechPanel(tone:const Color(0xffdc343b),onTap:()=>onOpen(row),child:Row(children:[const Icon(Icons.campaign_rounded,color:Color(0xffff5b66),size:33),const SizedBox(width:12),
   Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Latest Academic Alert',style:techText(c,size:10,color:nuIsDark(c)?techGold:SkinTokens.of(c).gold)),const SizedBox(height:4),Text('${row['title']}',maxLines:3,overflow:TextOverflow.ellipsis,style:techText(c,size:12,weight:FontWeight.w700))])),const Icon(Icons.chevron_right,size:20)]));});
}
class TechExamCard extends StatelessWidget{
 const TechExamCard({super.key,required this.summary,required this.onOpen,this.exam,this.centre});final String summary;final String? centre;final Map<String,dynamic>? exam;final VoidCallback onOpen;
 @override Widget build(BuildContext c){final date=DateTime.tryParse('${exam?['exam_datetime']}');
  return TechPanel(tone:const Color(0xffd83740),onTap:onOpen,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const GlossIcon(Icons.calendar_month_rounded,color:Color(0xffdf293b),size:43),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Next Exam',style:techText(c,size:10,color:nuIsDark(c)?techGold:SkinTokens.of(c).gold)),const SizedBox(height:4),
    Text(exam==null?summary:'${exam!['course_code']}',maxLines:3,overflow:TextOverflow.ellipsis,style:techText(c,size:exam==null?12:19,weight:FontWeight.w700)),
    if(exam!=null)Text('${exam!['course_title']}',style:techText(c,size:11)),
   ])),if(date!=null)Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:const Color(0xffdf293b),borderRadius:BorderRadius.circular(9)),child:Column(children:[
    Text('${date.day}',style:techText(c,size:24,color:Colors.white,weight:FontWeight.w700)),Text('${const ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][date.month-1]} ${date.year}',style:techText(c,size:8,color:Colors.white)),
   ])),]),if(exam!=null)...[const SizedBox(height:10),Wrap(spacing:12,runSpacing:6,children:[Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.schedule,size:13),const SizedBox(width:4),Text('${exam!['time']??''}',style:techText(c,size:10))]),if(centre?.isNotEmpty==true)Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.location_on_outlined,size:13),const SizedBox(width:4),Text('$centre',style:techText(c,size:10))])])]]));
 }
}
class TechStudyProgress extends StatefulWidget{
 const TechStudyProgress({super.key,required this.api,required this.courses,required this.balance,required this.onCourses,required this.onFund,this.userId,this.preview=false});
 final ApiClient api;final List<String> courses;final String balance;final String? userId;final bool preview;final VoidCallback onCourses,onFund;
 @override State<TechStudyProgress> createState()=>_TechStudyProgressState();
}
class _TechStudyProgressState extends State<TechStudyProgress>{
 String loadedKey='';int generation=0;double? progress,firstProgress;String? firstTitle;int complete=0;
 @override void initState(){super.initState();load();}
 @override void didUpdateWidget(covariant TechStudyProgress old){super.didUpdateWidget(old);if(loadedKey!='${widget.userId}|${widget.courses.join(',')}')load();}
 Future<void> load()async{loadedKey='${widget.userId}|${widget.courses.join(',')}';final request=++generation;progress=null;firstProgress=null;firstTitle=null;complete=0;final courses=List<String>.from(widget.courses);
  try{final results=await Future.wait(courses.map((code)async{final state=StudyStateStore(api:widget.api,courseCode:code,userId:widget.userId);
   if(widget.preview){final sample=unpack(await widget.api.getJson('/study/$code/state'));state.done=(sample['done'] as List? ?? []).whereType<num>().map((i)=>i.toInt()).toSet();}else{await state.load();}
   final data=unpack(await widget.api.getJson('/study/$code'));final indices=records(data['sections']).map((s)=>s['index']).whereType<num>().map((i)=>i.toInt()).toSet();
   return (data['course_title']?.toString(),indices.length,state.done.intersection(indices).length);
  }));if(!mounted||request!=generation)return;final units=results.fold(0,(n,r)=>n+r.$2),done=results.fold(0,(n,r)=>n+r.$3);
   setState((){progress=units==0?null:done/units;complete=results.where((r)=>r.$2>0&&r.$2==r.$3).length;
    if(results.isNotEmpty){firstTitle=results.first.$1;firstProgress=results.first.$2==0?null:results.first.$3/results.first.$2;}});
  }catch(_){/* Unknown progress is left unknown, rather than using display sample values. */}
 }
 @override Widget build(BuildContext c){final t=SkinTokens.of(c),large=MediaQuery.textScalerOf(c).scale(12)>16;
  Widget semester()=>TechPanel(onTap:widget.onCourses,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Semester Progress',style:techText(c,size:10,weight:FontWeight.w700)),const SizedBox(height:10),Row(children:[
   SizedBox(width:47,height:47,child:Stack(alignment:Alignment.center,children:[SizedBox.expand(child:CircularProgressIndicator(value:progress??0,strokeWidth:6,color:t.primary,backgroundColor:t.primary.withValues(alpha:.15))),Text(progress==null?'—':'${(progress!*100).round()}%',style:techText(c,size:13,weight:FontWeight.w700))])),
   const SizedBox(width:9),Expanded(child:Text(progress==null?'Open your courses':'$complete of ${widget.courses.length} courses completed',style:techText(c,size:9))),
  ])]));
  Widget wallet()=>TechPanel(onTap:widget.onFund,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const GlossIcon(Icons.account_balance_wallet_rounded,size:30),const SizedBox(width:7),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Wallet Balance',style:techText(c,size:9)),FittedBox(fit:BoxFit.scaleDown,child:Text(widget.balance,style:techText(c,size:18,weight:FontWeight.w700)))]))]),
   const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(minimumSize:const Size(0,29),padding:const EdgeInsets.symmetric(horizontal:8),textStyle:const TextStyle(fontSize:10)),onPressed:widget.onFund,child:Text(widget.balance=='—'?'Sign in':'Fund Wallet')))]));
  return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(large)...[semester(),const SizedBox(height:10),wallet()]else Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:semester()),const SizedBox(width:10),Expanded(child:wallet())]),
   Padding(padding:const EdgeInsets.only(top:14,bottom:9),child:Row(children:[Expanded(child:Text('Continue Studying',style:techText(c,size:16,weight:FontWeight.w700))),TextButton(onPressed:widget.onCourses,child:const Text('View All ›',style:TextStyle(fontSize:10)))])),
   TechPanel(onTap:widget.onCourses,child:Row(children:[const GlossIcon(Icons.bar_chart_rounded,color:Color(0xffb78a17),size:43),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(widget.courses.firstOrNull??'Add your courses',style:techText(c,size:12,weight:FontWeight.w700)),const SizedBox(height:4),Text(firstTitle??'Open your registered courses',style:techText(c,size:11,color:t.primary)),
    if(firstProgress!=null)...[const SizedBox(height:9),Row(children:[Expanded(child:LinearProgressIndicator(value:firstProgress,color:t.primary,backgroundColor:t.primary.withValues(alpha:.12),minHeight:4)),const SizedBox(width:7),Text('${(firstProgress!*100).round()}%',style:techText(c,size:9))])],
   ])),const SizedBox(width:10),Icon(Icons.play_circle_outline,size:38,color:t.primary)])),
  ]);
 }
}
class TechHomeLayout extends StatelessWidget{
 const TechHomeLayout({super.key,required this.services,required this.api,required this.courses,required this.balance,required this.feed,required this.examSummary,required this.onOpen,required this.onCourses,required this.onSearch,required this.onFund,required this.onExam,required this.onArticle,required this.extra,this.exam,this.centre,this.userId,this.preview=false});
 final List<Map<String,dynamic>> services;final List<String> courses;final ApiClient api;final Future<Map<String,dynamic>> feed;final String balance,examSummary;
 final Map<String,dynamic>? exam;final String? centre,userId;final bool preview;final void Function(Map<String,dynamic>) onOpen,onArticle;
 final VoidCallback onCourses,onSearch,onFund,onExam;final List<Widget> extra;
 @override Widget build(BuildContext c){final large=MediaQuery.textScalerOf(c).scale(12)>16;
  final quick=<({String title,IconData icon,Color tone,VoidCallback tap})>[(title:'My Courses',icon:Icons.menu_book_rounded,tone:const Color(0xff0b724b),tap:onCourses)];
  for(final id in ['result','fees','personalized-timetable']){final rows=services.where((s)=>s['id']==id);if(rows.isEmpty)continue;final row=rows.first;
   quick.add((title:switch(id){'result'=>'Results','fees'=>'Fees',_=>'Timetable'},icon:serviceIcon(id),tone:switch(id){'result'=>const Color(0xff276684),'fees'=>const Color(0xff9b7114),_=>const Color(0xff663b8a)},tap:()=>onOpen(row)));}
  Widget cell(int i)=>TechPanel(padding:9,onTap:quick[i].tap,child:Column(children:[GlossIcon(quick[i].icon,color:quick[i].tone,size:29),const SizedBox(height:6),Text(quick[i].title,style:techText(c,size:9),textAlign:TextAlign.center)]));
  return ListView(key:const PageStorageKey('home'),padding:const EdgeInsets.fromLTRB(16,6,16,24),children:[
   TechPanel(onTap:onSearch,padding:10,child:Row(children:[const Icon(Icons.search,size:18),const SizedBox(width:8),Expanded(child:Text('Search anything (courses, news, tools…)',style:techText(c,size:10)))])),const SizedBox(height:11),
   if(large)Wrap(spacing:9,runSpacing:9,children:[for(var i=0;i<quick.length;i++)SizedBox(width:(MediaQuery.sizeOf(c).width-41)/2,child:cell(i))])
   else Row(children:[for(var i=0;i<quick.length;i++)...[if(i>0)const SizedBox(width:9),Expanded(child:cell(i))]]),
   const SizedBox(height:12),TechExamCard(summary:examSummary,exam:exam,centre:centre,onOpen:onExam),const SizedBox(height:10),TechNotice(feed:feed,onOpen:onArticle),const SizedBox(height:11),
   TechStudyProgress(api:api,courses:courses,userId:userId,preview:preview,balance:balance,onCourses:onCourses,onFund:onFund),const SizedBox(height:16),...extra,
  ]);
 }
}
class TechWelcome extends StatelessWidget{
 const TechWelcome({super.key,required this.onLogin,required this.onRegister,required this.onGuest});final VoidCallback onLogin,onRegister,onGuest;
 @override Widget build(BuildContext c)=>Scaffold(backgroundColor:const Color(0xff00170f),body:LayoutBuilder(builder:(c,box){
  final scale=MediaQuery.textScalerOf(c).scale(14)/14,height=math.max(box.maxHeight,820+math.max(0.0,scale-1)*650);
  return SingleChildScrollView(child:SizedBox(height:height,child:Stack(children:[
   Positioned(top:0,left:0,right:0,height:height*.80,child:ExcludeSemantics(child:Image.asset('assets/images/skins/future-tech-campus.webp',fit:BoxFit.cover,alignment:Alignment.topCenter))),
   Positioned(top:height*.57,bottom:0,left:0,right:0,child:const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xf500170f),Color(0xff00170f)],stops:[0,.45,1])))),
   Positioned(top:height*.12,left:18,right:18,child:Center(child:Image.asset('assets/images/skins/editorial-emblem.webp',width:245,height:245,semanticLabel:'NOUN Update Educational Consultant'))),
   Positioned(top:height*.625,left:27,right:27,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('Your Complete',textAlign:TextAlign.center,style:techText(c,size:15,color:techGold,weight:FontWeight.w700)),Text('NOUN Companion',textAlign:TextAlign.center,style:techText(c,size:20,color:Colors.white,weight:FontWeight.w700)),
    const SizedBox(height:9),Text('Study · Track · Plan · Succeed',textAlign:TextAlign.center,style:techText(c,size:11,color:Colors.white)),const SizedBox(height:26),
    Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xffffed9b),Color(0xffffce3f),Color(0xffd7930b)]),border:Border.all(color:techGold),boxShadow:[BoxShadow(color:techGold.withValues(alpha:.22),blurRadius:14)]),
     child:FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.transparent,shadowColor:Colors.transparent,foregroundColor:const Color(0xff08251a),minimumSize:Size(0,46+math.max(0.0,scale-1)*25),shape:const StadiumBorder()),onPressed:onLogin,child:Row(children:[const SizedBox(width:20),Expanded(child:Text('Sign In',textAlign:TextAlign.center,style:techText(c,size:14,color:const Color(0xff08251a),weight:FontWeight.w700))),const Icon(Icons.chevron_right,size:24)]))),
    const SizedBox(height:13),OutlinedButton(style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Color(0xffbbdfcb)),shape:const StadiumBorder(),minimumSize:Size(0,43+math.max(0.0,scale-1)*25)),onPressed:onRegister,child:Text('Create Account',style:techText(c,size:12,color:Colors.white,weight:FontWeight.w700))),
    const SizedBox(height:26),Text('For National Open University Students',textAlign:TextAlign.center,style:techText(c,size:10,color:const Color(0xffd4e4da))),const SizedBox(height:18),
    ExcludeSemantics(child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(final color in [const Color(0xfff93445),techNeon])Container(width:27,height:4,margin:const EdgeInsets.symmetric(horizontal:3),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(4)))])),
   ])),Positioned(top:MediaQuery.paddingOf(c).top+8,left:8,child:IconButton(tooltip:'Back',onPressed:onGuest,icon:const Icon(Icons.arrow_back,color:Colors.white))),
  ])));
 }));
}
