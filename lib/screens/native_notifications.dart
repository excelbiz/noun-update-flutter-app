import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/notification_preferences.dart';
import '../core/notification_service.dart';
import '../widgets/native_ui.dart';
import 'native_tools.dart';

class NativeNotifications extends StatefulWidget {
 const NativeNotifications({super.key,required this.api,required this.onArticle,this.userId});
 final ApiClient api;final void Function(Map<String,dynamic>) onArticle;final String? userId;
 @override State<NativeNotifications> createState()=>_NativeNotificationsState();
}
class _NativeNotificationsState extends State<NativeNotifications>{
 List<Map<String,dynamic>> rows=[];Set<String> read={};String filter='All';bool unreadOnly=false;bool loading=true;Object? error;
 late final NotificationPreferences preferences;
 String get slot=>'nu-read-notices-${widget.userId??'guest'}';
 @override void initState(){super.initState();preferences=NotificationPreferences(api:widget.api,userId:widget.userId)..load();load();}
 @override void dispose(){preferences.dispose();super.dispose();}
 String category(String text){final t=text.toLowerCase();if(t.contains('tma'))return 'TMAs';if(t.contains('result'))return 'Results';if(t.contains('exam'))return 'Exams';if(t.contains('fee')||t.contains('payment'))return 'Fees';return 'General';}
 Future<void> load()async{try{
  final prefs=await SharedPreferences.getInstance();final fetched=<Map<String,dynamic>>[];Object? failure;
  await Future.wait(['news','guides','scholarships','career','blog'].map((source)async{
   try{final d=unpack(await widget.api.getJson('/posts/$source'));for(final p in records(d['items'])){fetched.add({'key':'$source:${p['id']}','title':p['title'],'text':p['excerpt']??'Read the published update.','date':p['published_at'],'category':category('${p['title']}'),'article':p});}}catch(e){failure=e;}
  }));
  fetched.sort((a,b)=>'${b['date']}'.compareTo('${a['date']}'));
  if(mounted)setState((){rows=fetched;read=(prefs.getStringList(slot)??[]).toSet();loading=false;error=failure;});
 }catch(e){if(mounted)setState((){loading=false;error=e;});}}
 Future<void> mark(Iterable<String> keys)async{setState(()=>read.addAll(keys));await (await SharedPreferences.getInstance()).setStringList(slot,read.toList());}
 Future<void> changePreference(Future<void> Function() action)async{try{await action();if(mounted&&preferences.syncPending)nuMessage(context,'Saved on this device. Notification choices will sync when you reconnect.');}catch(_){if(mounted)nuMessage(context,preferences.syncPending?'Saved on this device. Notification choices will sync when you reconnect.':'Notification preference could not be saved.');}}
 String displayDate(Object? value){final d=DateTime.tryParse('$value');if(d==null)return 'Published update';final months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];return '${d.day} ${months[d.month-1]} ${d.year}';}
 String group(Map<String,dynamic> r){final date=DateTime.tryParse('${r['date']}');if(date==null)return 'Earlier';final now=DateTime.now(),today=DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);if(!date.isBefore(today))return 'Today';if(now.difference(date).inDays<7)return 'This week';return 'Earlier';}
 Widget preferencePanel()=>ListenableBuilder(listenable:preferences,builder:(context,_){
  Widget categorySwitch(String title,String subtitle,bool value,Future<void> Function(bool) change)=>SwitchListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text(title),subtitle:Text(subtitle,style:TextStyle(fontSize:11)),value:value,onChanged:preferences.enabled?(v)=>changePreference(()=>change(v)):null);
  return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Push notification preferences',style:TextStyle(fontWeight:FontWeight.w800)),SizedBox(height:3),Text(preferences.syncPending?'Saved locally · account sync pending':widget.userId==null?'Saved on this device':'Synced with your NOUN Update account',style:TextStyle(fontSize:11,color:nuMuted(context)))])),Icon(Icons.tune_rounded,color:Theme.of(context).colorScheme.primary)]),
   SwitchListTile(contentPadding:EdgeInsets.zero,title:Text('Allow NOUN Update notifications'),subtitle:Text('Master switch for the categories below.',style:TextStyle(fontSize:11)),value:preferences.enabled,onChanged:(v)=>changePreference(()=>preferences.change(enabled:v))),
   categorySwitch('TMA updates','TMA openings, deadlines and material changes',preferences.tmas,(v)=>preferences.change(tmas:v)),
   categorySwitch('Examination updates','Timetable and examination notices',preferences.exams,(v)=>preferences.change(exams:v)),
   categorySwitch('Result updates','Result-related notices',preferences.results,(v)=>preferences.change(results:v)),
   categorySwitch('Fees & registration','Fee, payment and registration notices',preferences.fees,(v)=>preferences.change(fees:v)),
   categorySwitch('General updates','Other important NOUN Update announcements',preferences.general,(v)=>preferences.change(general:v)),
   OutlinedButton.icon(onPressed:!preferences.enabled?null:()async{final granted=await NotificationService.requestPermission();if(context.mounted)nuMessage(context,granted?'Device notifications are allowed.':'Notification permission was not granted. You can change this later in your device settings.');},icon:Icon(Icons.notifications_active_outlined),label:Text('Allow on this device')),
  ]));
 });
 @override Widget build(BuildContext context){final shown=rows.where((r)=>(filter=='All'||r['category']==filter)&&(!unreadOnly||!read.contains(r['key']))).toList();return RefreshIndicator(onRefresh:()async{await Future.wait([load(),preferences.load()]);},child:ListView(key:PageStorageKey('notifications'),physics:AlwaysScrollableScrollPhysics(),padding:EdgeInsets.all(16),children:[
  NuTitle('Your inbox',subtitle:'Published updates from NOUN Update'),preferencePanel(),NuPanel(child:Row(children:[GlossIcon(Icons.notifications_active_outlined,size:44),SizedBox(width:14),Expanded(child:Text('${rows.where((r)=>!read.contains(r['key'])).length} unread updates',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)))])),Material(color:Colors.transparent,child:SwitchListTile(contentPadding:EdgeInsets.zero,title:Text('Unread only'),value:unreadOnly,onChanged:(v)=>setState(()=>unreadOnly=v))),Align(alignment:Alignment.centerRight,child:TextButton(onPressed:rows.isEmpty?null:()=>mark(rows.map((r)=>'${r['key']}')),child:Text('Mark all read',style:TextStyle(fontSize:10)))),
  SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final c in ['All','TMAs','Exams','Results','Fees','General'])Padding(padding:EdgeInsets.only(right:6),child:ChoiceChip(showCheckmark:false,label:Text(c,style:TextStyle(fontSize:11)),selected:filter==c,onSelected:(_)=>setState(()=>filter=c)))])),
  if(loading)Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator())),
  if(error!=null)AsyncError('Some updates could not load.',load),
  for(final g in ['Today','This week','Earlier'])if(shown.any((r)=>group(r)==g))...[
   NuTitle(g),for(final r in shown.where((r)=>group(r)==g))NuPanel(padding:12,child:InkWell(onTap:(){mark(['${r['key']}']);widget.onArticle(Map<String,dynamic>.from(r['article'] as Map));},child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[GlossIcon(switch(r['category']){'TMAs'=>Icons.assignment_rounded,'Exams'=>Icons.calendar_month_rounded,'Results'=>Icons.bar_chart_rounded,'Fees'=>Icons.account_balance_wallet_rounded,_=>Icons.campaign_rounded},color:r['category']=='Exams'?nuRed:r['category']=='Results'?nuGold:nuGreen,size:45),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r['title']}',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:nuInk(context))),SizedBox(height:5),Text('${r['text']}',maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11,height:1.35)),SizedBox(height:6),Text(displayDate(r['date']),style:TextStyle(fontSize:9,color:nuMuted(context)))])),SizedBox(width:7),if(!read.contains(r['key']))Padding(padding:EdgeInsets.only(top:4),child:Icon(Icons.circle,color:nuRed,size:8))else Icon(Icons.chevron_right,color:nuMuted(context),size:16)]))),
  ],if(!loading&&shown.isEmpty)Padding(padding:EdgeInsets.symmetric(vertical:30),child:Text('No published updates in this category yet.',textAlign:TextAlign.center)),
  NuPanel(color:nuMint,child:ListTile(contentPadding:EdgeInsets.zero,leading:GlossIcon(Icons.calendar_month,size:40),title:Text('Academic dates & deadlines',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700)),subtitle:Text('TMAs, registration and examinations',style:TextStyle(fontSize:11)),onTap:()=>pushNu(context,NativeCalendar(widget.api)))),
 ]));}
}
