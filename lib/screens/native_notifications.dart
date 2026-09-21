import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';
import 'native_tools.dart';

class NativeNotifications extends StatefulWidget {
 const NativeNotifications({super.key,required this.api,required this.onArticle,this.userId});
 final ApiClient api;final void Function(Map<String,dynamic>) onArticle;final String? userId;
 @override State<NativeNotifications> createState()=>_NativeNotificationsState();
}
class _NativeNotificationsState extends State<NativeNotifications>{
 List<Map<String,dynamic>> rows=[];Set<String> read={};String filter='All';bool loading=true;Object? error;
 String get slot=>'nu-read-notices-${widget.userId??'guest'}';
 @override void initState(){super.initState();load();}
 String category(String text){final t=text.toLowerCase();if(t.contains('tma'))return 'TMAs';if(t.contains('result'))return 'Results';if(t.contains('exam'))return 'Exams';if(t.contains('fee')||t.contains('payment'))return 'Fees';return 'General';}
 Future<void> load()async{try{
  final prefs=await SharedPreferences.getInstance();final fetched=<Map<String,dynamic>>[];Object? failure;
  for(final source in ['news','guides','scholarships','career','blog']){
   try{final d=unpack(await widget.api.getJson('/posts/$source'));for(final p in records(d['items'])){fetched.add({'key':'$source:${p['id']}','title':p['title'],'text':p['excerpt']??'Read the published update.','date':p['published_at'],'category':category('${p['title']}'),'article':p});}}catch(e){failure=e;}
  }
  fetched.sort((a,b)=>'${b['date']}'.compareTo('${a['date']}'));
  if(mounted)setState((){rows=fetched;read=(prefs.getStringList(slot)??[]).toSet();loading=false;error=failure;});
 }catch(e){if(mounted)setState((){loading=false;error=e;});}}
 Future<void> mark(Iterable<String> keys)async{setState(()=>read.addAll(keys));await (await SharedPreferences.getInstance()).setStringList(slot,read.toList());}
 String group(Map<String,dynamic> r){final date=DateTime.tryParse('${r['date']}');if(date==null)return 'Earlier';final now=DateTime.now(),today=DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);if(!date.isBefore(today))return 'Today';if(now.difference(date).inDays<7)return 'This week';return 'Earlier';}
 @override Widget build(BuildContext context){final shown=rows.where((r)=>filter=='All'||r['category']==filter).toList();return RefreshIndicator(onRefresh:load,child:ListView(key:const PageStorageKey('notifications'),physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(16),children:[
  NuTitle('Notifications',subtitle:'Published updates from NOUN Update',trailing:TextButton(onPressed:rows.isEmpty?null:()=>mark(rows.map((r)=>'${r['key']}')),child:const Text('Mark all read',style:TextStyle(fontSize:10)))),
  SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final c in ['All','TMAs','Exams','Results','Fees','General'])Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(showCheckmark:false,label:Text(c,style:const TextStyle(fontSize:11)),selected:filter==c,onSelected:(_)=>setState(()=>filter=c)))])),
  if(loading)const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator())),
  if(error!=null)AsyncError('Some updates could not load.',load),
  for(final g in ['Today','This week','Earlier'])if(shown.any((r)=>group(r)==g))...[
   NuTitle(g),for(final r in shown.where((r)=>group(r)==g))NuPanel(padding:12,child:InkWell(onTap:(){mark(['${r['key']}']);widget.onArticle(Map<String,dynamic>.from(r['article'] as Map));},child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[GlossIcon(switch(r['category']){'TMAs'=>Icons.assignment_rounded,'Exams'=>Icons.calendar_month_rounded,'Results'=>Icons.bar_chart_rounded,'Fees'=>Icons.account_balance_wallet_rounded,_=>Icons.campaign_rounded},color:r['category']=='Exams'?nuRed:r['category']=='Results'?nuGold:nuGreen,size:45),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['title']}',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:Color(0xff18271e))),const SizedBox(height:5),Text('${r['text']}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,height:1.35)),const SizedBox(height:6),Text('${r['date']}',style:const TextStyle(fontSize:9,color:Colors.blueGrey))])),const SizedBox(width:7),if(!read.contains(r['key']))const Padding(padding:EdgeInsets.only(top:4),child:Icon(Icons.circle,color:nuRed,size:8))else const Icon(Icons.chevron_right,color:Colors.blueGrey,size:16)]))),
  ],if(!loading&&shown.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:30),child:Text('No published updates in this category yet.',textAlign:TextAlign.center)),
  NuPanel(color:nuMint,child:ListTile(contentPadding:EdgeInsets.zero,leading:const GlossIcon(Icons.calendar_month,size:40),title:const Text('Academic dates & deadlines',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700)),subtitle:const Text('TMAs, registration and examinations',style:TextStyle(fontSize:11)),onTap:()=>pushNu(context,NativeCalendar(widget.api)))),
 ]));}
}
