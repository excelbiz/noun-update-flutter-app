import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';
import 'native_tools.dart';
import 'native_account.dart';
import 'native_notifications.dart';
import 'appearance_settings.dart';
import 'student_workspace.dart';

String _money(dynamic v)=>naira(v);
Map<String,dynamic> _data(Map<String,dynamic> v)=>unpack(v);
List<Map<String,dynamic>> _items(dynamic v)=>records(v);
String _key()=>List.generate(24,(_)=>math.Random.secure().nextInt(256).toRadixString(16).padLeft(2,'0')).join();

class LivePortal extends StatefulWidget {
 const LivePortal({this.apiClient,this.serviceBundle,super.key});
 final ApiClient? apiClient;final AssetBundle? serviceBundle;
 @override State<LivePortal> createState()=>_LivePortalState();
}
class _LivePortalState extends State<LivePortal> with WidgetsBindingObserver {
 late final ApiClient api;
 StudentWorkspace workspace=StudentWorkspace('guest');
 Future<void> _workspace(String scope)async{final next=StudentWorkspace(scope);await next.load();if(mounted)setState(()=>workspace=next);}
 void _courses()=>pushNu(context,MyCoursesPage(workspace:workspace,openResource:(id,label)=>_service({'id':id,'label':label}))).then((_) {if(mounted)setState((){});});
 void _setup()=>pushNu(context,StudentSetup(workspace:workspace)).then((_) {if(mounted)setState((){});});
 void _unavailable(String title)=>pushNu(context,NuPage(title:title,child:ListView(padding:EdgeInsets.all(20),children:[NuTitle(title),NuPanel(child:Text('This feature is not connected yet. It will become available after its account API is enabled.'))])));
 Widget _row(String title,String subtitle,IconData icon,VoidCallback tap)=>ListTile(leading:Icon(icon,color:Theme.of(context).colorScheme.primary),title:Text(title),subtitle:Text(subtitle),trailing:Icon(Icons.chevron_right),onTap:tap);

 List<Map<String,dynamic>> services=[];
 Map<String,dynamic>? profile,wallet;
 int tab=0;bool busy=false;String search='',category='news';
 String? accountError,pendingReference;
 late Future<Map<String,dynamic>> feed;
 final amount=TextEditingController(text:'1000');
 @override void initState(){super.initState();api=widget.apiClient??ApiClient();WidgetsBinding.instance.addObserver(this);feed=_feed();_loadServices();_workspace('guest');_loadAccount();}
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);amount.dispose();super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&profile!=null)_loadAccount();}
 Future<Map<String,dynamic>> _feed()=>api.getJson('/posts/$category').then(unpack);
 Future<void> _loadServices()async{
  final rows=records(jsonDecode(await (widget.serviceBundle??rootBundle).loadString('assets/data/services.json')));
  if(mounted)setState(()=>services=rows.where((s)=>s['id']!='quizly').toList());
  try{final d=unpack(await api.getJson('/services'));if(mounted)setState(()=>services=records(d['items']).where((s)=>s['id']!='quizly').toList());}catch(_){/* Retain bundled directory. */}
 }
 Future<void> _loadAccount()async{try{
  if(await SessionStore().readAccessToken()==null)return;
  final b=unpack(await api.getJson('/app/bootstrap'));final p=b['profile']==null?null:Map<String,dynamic>.from(b['profile'] as Map);
  final prefs=await SharedPreferences.getInstance();
  if(p!=null&&workspace.scope!='${p['id']}')await _workspace('${p['id']}');
  if(mounted)setState((){profile=p;wallet=b['wallet']==null?null:Map<String,dynamic>.from(b['wallet'] as Map);pendingReference=p==null?null:prefs.getString('nu_pending_${p['id']}');accountError=null;});
 }catch(e){if(mounted)setState((){accountError='$e';if(e is ApiException&&e.statusCode==401){profile=null;wallet=null;}});}}
 Future<void> _run(Future<void> Function() action)async{if(busy)return;setState(()=>busy=true);try{await action();}catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>busy=false);}}
 Future<void> _login()async{final ok=await pushNu<bool>(context,NativeAuth(api));if(ok==true)await _loadAccount();}
  Future<void> _fund() async {
    if(profile==null)return;
    final naira=int.tryParse(amount.text.trim());
    if(naira==null||naira<1)throw ApiException('Enter a whole-naira amount.');
    final prefs=await SharedPreferences.getInstance();final slot='nu_fund_${profile!['id']}';
    String key=prefs.getString('${slot}_key')??_key();
    final oldAmount=prefs.getInt('${slot}_amount');
    if(oldAmount!=null&&oldAmount!=naira)key=_key();
    // Persist before networking so retry after an app close retains the same key.
    await prefs.setString('${slot}_key',key);await prefs.setInt('${slot}_amount',naira);
    final d=_data(await api.postJson('/wallet/fund',{'amount_kobo':naira*100},idempotencyKey:key));
    final ref=d['reference'] as String;
    await prefs.setString('nu_pending_${profile!['id']}',ref);
    if(mounted)setState(()=>pendingReference=ref);
    if(d['status']=='credited'){await _recheck();return;}
    if(mounted)await pushNu(context,NativeCheckout(d['authorization_url'] as String));
    await _recheck();
  }
  Future<void> _recheck() async {
    final ref=pendingReference;if(ref==null||profile==null)return;
    final d=_data(await api.postJson('/wallet/fund/$ref/verify',{}));
    if(d['status']=='credited'){
      final prefs=await SharedPreferences.getInstance();
      await prefs.remove('nu_pending_${profile!['id']}');await prefs.remove('nu_fund_${profile!['id']}_key');await prefs.remove('nu_fund_${profile!['id']}_amount');
      if(mounted)setState(()=>pendingReference=null);
    }else if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Payment is not confirmed yet. Recheck this payment; do not pay again.')));}
    await _loadAccount();
  }
 void _service(Map<String,dynamic> s){
  final id='${s['id']}',title='${s['id']=='courses'?'Course Materials':s['label']}';
  if(id=='wallet'){setState(()=>tab=4);return;}
  if(['news','guides','scholarships','career','blog'].contains(id)){setState((){tab=3;category=id;feed=_feed();});return;}
  final Widget page=switch(id){
   'courses'||'course-materials'||'study-hub'=>MaterialLibrary(api:api,userId:profile?['id']?.toString()),
   'course-summary'=>MaterialLibrary(api:api,userId:profile?['id']?.toString(),summaries:true),
   'exam-summary'=>ExamShop(api:api,signedIn:profile!=null,onWallet:(){Navigator.pop(context);setState(()=>tab=4);}),
   'calendar'=>NativeCalendar(api),'fees'||'fee-check'=>NativeFees(api),'cgpa-calculator'=>NativeCgpa(),
   _=>NativeUnavailable(title),
  };
  pushNu(context,page).then((_)=>_loadAccount());
 }
 Widget _grid(List<Map<String,dynamic>> entries,{bool compact=false})=>LayoutBuilder(builder:(context,box){
  final scale=MediaQuery.textScalerOf(context).scale(14)/14;
  final columns=compact?(box.maxWidth>=350&&scale<1.3?5:4):(box.maxWidth>=330&&scale<1.3?3:2);
  return GridView.builder(shrinkWrap:true,physics:NeverScrollableScrollPhysics(),itemCount:entries.length,
   gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:compact?8:10,mainAxisSpacing:12,mainAxisExtent:(compact?100:154)+math.max(0,scale-1)*70),
   itemBuilder:(c,i){final s=entries[i],id='${s['id']}';return Material(color:compact?Colors.transparent:Color.lerp(Theme.of(context).colorScheme.surface,serviceColour(id),nuIsDark(context) ? 0.13 : 0.055),borderRadius:BorderRadius.circular(16),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>_service(s),child:Padding(padding:EdgeInsets.all(compact?2:8),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[GlossIcon(serviceIcon(id),color:serviceColour(id),size:compact?46:50),SizedBox(height:10),Text(compact&&id=='personalized-timetable'?'Timetable':serviceLabel(id,'${s['label']}'),textAlign:TextAlign.center,maxLines:3,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:compact?9:12,fontWeight:FontWeight.w800,color:nuInk(context),height:1.15)),if(!compact)...[SizedBox(height:5),Text(serviceCaption(id),textAlign:TextAlign.center,maxLines:3,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,height:1.25))]]))));});
 });
 Widget _home()=>RefreshIndicator(onRefresh:()async{await _loadAccount();if(mounted)setState(()=>feed=_feed());},child:ListView(key:PageStorageKey('home'),padding:EdgeInsets.fromLTRB(20,20,20,28),children:[
  Text('YOUR STUDENT DASHBOARD',style:TextStyle(fontSize:11,letterSpacing:1.5,fontWeight:FontWeight.w700,color:Theme.of(context).colorScheme.primary)),
  NuTitle('${DateTime.now().hour<12?'Good morning':DateTime.now().hour<18?'Good afternoon':'Good evening'}${(workspace.details['Name']??profile?['name']??'').toString().isEmpty?'':', ${workspace.details['Name']??profile?['name']}'}',subtitle:[workspace.details['Programme'],workspace.details['Level'],workspace.details['Semester']].whereType<String>().where((v)=>v.isNotEmpty).join(' · ')),
  if(workspace.details.isEmpty)NuPanel(padding:0,child:_row('Make it your semester','Set up your student details',Icons.person_outline,_setup)),
  NuPanel(color:nuDeep,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('YOUR NEXT STEP',style:TextStyle(color:nuGold,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.4)),SizedBox(height:14),Text(workspace.courses.isEmpty?'Bring your courses together.':'Build a little progress today.',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w800)),SizedBox(height:10),Text(workspace.courses.isEmpty?'Add your registered courses to organise your study resources.':'${workspace.courses.length} courses saved. Choose a course and open its study resources.',style:TextStyle(color:Colors.white70,height:1.5)),SizedBox(height:18),FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:nuGold,foregroundColor:nuDeep),onPressed:_courses,icon:Icon(Icons.arrow_forward),label:Text(workspace.courses.isEmpty?'Add My Courses':'Open My Courses'))])),
  NuPanel(padding:0,child:_row('Next examination','No verified personal timetable is available yet.',Icons.event_outlined,()=>_service({'id':'personalized-timetable','label':'Personalised Timetable'}))),
  NuTitle('Continue Studying'),NuPanel(padding:0,child:_row('Choose your next chapter','Open your course library to begin a study session.',Icons.auto_stories_outlined,()=>setState(()=>tab=1))),
  NuTitle('Your wallet'),NuPanel(padding:0,child:_row(wallet==null?'Sign in to view your balance':naira(wallet!['balance_kobo']),'One account across NOUN Update',Icons.account_balance_wallet_outlined,()=>setState(()=>tab=4))),
  NuTitle('My Courses',subtitle:'${workspace.courses.length} registered courses saved on this device'),
  if(workspace.courses.isNotEmpty)Wrap(spacing:8,children:[for(final c in workspace.courses.take(6))ActionChip(label:Text(c),onPressed:_courses)]),
  NuTitle('Quick access'),_grid([for(final id in ['fees','calendar','courses','exam-summary'])...services.where((s)=>s['id']==id).take(1)],compact:true),
  NuTitle('Latest updates'),_news(compact:true),
 ]));
 Widget _study()=>ListView(key:PageStorageKey('study'),padding:EdgeInsets.all(20),children:[
  NuTitle('Study smarter',subtitle:'Your courses. Your pace. Your next step.'),
  ServiceHero(title:'Make room for understanding',subtitle:'Start with a course, then choose how you want to learn.',icon:Icons.menu_book_rounded),
  NuTitle('Continue Studying'),NuPanel(child:Text('Your course resources are ready to explore. Reading progress synchronisation is not yet connected.')),
  NuPanel(padding:0,child:_row('My Courses','${workspace.courses.length} courses · open your course hubs',Icons.school_outlined,_courses)),
  NuTitle('Your study library'),_grid(services.where((s)=>['courses','course-summary','exam-summary','past-questions','mock','study-hub','pop-practice'].contains(s['id'])).toList()),
  NuTitle('Your collection'),NuPanel(padding:0,child:Column(children:[_row('Saved resources','Bookmarks and reading lists',Icons.bookmark_border,()=>_unavailable('Saved resources')),_row('Downloads','Offline study resources',Icons.download_outlined,()=>_unavailable('Downloads'))])),
  NuPanel(padding:0,child:_row('Focus timer','Make time for one focused session',Icons.timer_outlined,()=>pushNu(context,FocusTimer()))),
 ]);
 Widget _tools(){
  final rows=services.where((s)=>'${s['label']} ${s['group']}'.toLowerCase().contains(search.toLowerCase())&&!['news','guides','scholarships','career','blog','wallet'].contains(s['id'])).toList();
  final pinned=rows.where((s)=>workspace.pins.contains(s['id'])).toList();
  Widget tool(Map<String,dynamic> s)=>NuPanel(padding:0,child:ListTile(leading:GlossIcon(serviceIcon('${s['id']}'),color:serviceColour('${s['id']}'),size:42),title:Text(serviceLabel('${s['id']}','${s['label']}')),subtitle:Text(serviceCaption('${s['id']}')),onTap:()=>_service(s),trailing:IconButton(tooltip:workspace.pins.contains(s['id'])?'Unpin tool':'Pin tool',icon:Icon(workspace.pins.contains(s['id'])?Icons.push_pin:Icons.push_pin_outlined),onPressed:()=>_run(()async{final old=Set<String>.from(workspace.pins);if(!workspace.pins.add('${s['id']}'))workspace.pins.remove(s['id']);try{await workspace.save();}catch(_){workspace.pins=old;rethrow;}if(mounted)setState((){});})))) ;
  final groups=rows.map((s)=>'${s['group']??'Academic tools'}').toSet();
  return ListView(key:PageStorageKey('tools'),padding:EdgeInsets.all(20),children:[NuTitle('Tools',subtitle:'Useful shortcuts for every stage of your semester.'),TextField(onChanged:(v)=>setState(()=>search=v),decoration:InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Find a tool')),NuTitle('Pinned tools',subtitle:'Tap the pin beside any tool to keep it here.'),if(pinned.isEmpty)NuPanel(child:Text('Your favourite tools will appear here.')),for(final s in pinned)tool(s),for(final group in groups)...[NuTitle(group),for(final s in rows.where((s)=>'${s['group']??'Academic tools'}'==group&&!workspace.pins.contains(s['id'])))tool(s)],if(rows.isEmpty)NuPanel(child:Text('No tools match your search.'))]);
 }
 Widget _updates()=>ListView(key:PageStorageKey('updates'),padding:EdgeInsets.all(20),children:[NuTitle('Updates',subtitle:'Stay informed. Know what matters.'),Wrap(spacing:8,runSpacing:6,children:[for(final c in [('news','News'),('guides','Guides'),('scholarships','Scholarships'),('career','Careers')])ChoiceChip(label:Text(c.$2),selected:category==c.$1,onSelected:(_)=>setState((){category=c.$1;feed=_feed();}))]),SizedBox(height:18),_news()]);
 Widget _news({bool compact=false})=>FutureBuilder<Map<String,dynamic>>(future:feed,builder:(context,s){
  if(s.hasError)return AsyncError('Updates could not load. Please try again.',()=>setState(()=>feed=_feed()));
  if(!s.hasData)return Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));
  final rows=records(s.data!['items']);if(rows.isEmpty)return NuPanel(child:Text('No published updates in this category yet.'));
  return Column(children:[for(final r in compact?rows.take(3):rows)NuPanel(padding:0,child:ListTile(contentPadding:EdgeInsets.all(14),leading:GlossIcon(Icons.campaign_rounded,size:44),title:Text('${r['title']}',maxLines:3,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w700,fontSize:14)),subtitle:Text('${r['published_at']}',style:TextStyle(fontSize:11)),onTap:()=>pushNu(context,ArticlePage(api:api,item:r))))]);
 });
 Widget _notifications()=>NativeNotifications(api:api,userId:profile?['id']?.toString(),onArticle:(r)=>pushNu(context,ArticlePage(api:api,item:r)));
 Widget _profile()=>ListView(key:PageStorageKey('profile'),padding:EdgeInsets.all(20),children:[NuTitle('Profile',subtitle:'Your student life, organised.'),NuPanel(padding:0,child:Column(children:[_row('Student details',workspace.details['Programme']??'Programme, level, centre and semester',Icons.badge_outlined,_setup),_row('My Courses','${workspace.courses.length} registered courses',Icons.school_outlined,_courses)])),
  if(profile==null)...[SizedBox(height:20),Center(child:BrandLogo(size:100)),NuTitle('One account. One balance.',subtitle:'Sign in to access your central wallet, purchases and saved study progress.'),FilledButton(onPressed:_login,child:Text('Sign in')),OutlinedButton(onPressed:()=>pushNu<bool>(context,NativeAuth(api,initialMode:'register')).then((ok){if(ok==true)_loadAccount();}),child:Text('Create an account'))]
  else ...[
   NuPanel(child:Row(children:[GlossIcon(Icons.person_rounded,size:64),SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${profile!['name']}',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('${profile!['email']}',style:TextStyle(fontSize:12))])),IconButton(tooltip:'Edit profile',onPressed:()=>pushNu(context,NativeProfile(api:api,name:'${profile!['name']}')).then((_)=>_loadAccount()),icon:Icon(Icons.edit_outlined))])),
   if(accountError!=null)AsyncError(accountError!,_loadAccount),
   CentralWalletCard(balance:wallet==null?'—':naira(wallet!['balance_kobo']),onFund:_fundDialog,onTools:()=>setState(()=>tab=2),onHistory:()=>pushNu(context,NuPage(title:'Wallet history',child:ListView(padding:EdgeInsets.all(18),children:[for(final t in records(wallet?['transactions']))NuPanel(child:ListTile(title:Text('${t['title']}'),subtitle:Text('${t['created_at']}'),trailing:Text(naira(t['amount_kobo'])))),if(records(wallet?['transactions']).isEmpty)Text('No wallet transactions yet.')])))),
   NuTitle('My tools & purchases'),NuPanel(padding:0,child:Column(children:[for(final t in [('course-summary','Course Summary','Understand your course, unit by unit'),('exam-summary','Exam Summary','Focused resources for revision'),('study-hub','Study Hub','Your materials, notes and progress')])ListTile(leading:GlossIcon(serviceIcon(t.$1),color:serviceColour(t.$1),size:38),title:Text(t.$2,style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),subtitle:Text(t.$3,style:TextStyle(fontSize:10)),trailing:Icon(Icons.chevron_right,size:18),onTap:()=>_service({'id':t.$1,'label':t.$2}))])),
   if(pendingReference!=null)NuPanel(child:Column(children:[Text('A payment is awaiting confirmation.'),SelectableText(pendingReference!,style:TextStyle(fontSize:11)),TextButton(onPressed:busy?null:()=>_run(_recheck),child:Text('Recheck payment'))])),
   NuTitle('My account'),NuPanel(padding:0,child:Column(children:[ListTile(leading:Icon(Icons.description_outlined,color:Theme.of(context).colorScheme.primary),title:Text('My Exam Summaries'),trailing:Icon(Icons.chevron_right),onTap:()=>pushNu(context,OrdersPage(api:api))),ListTile(leading:Icon(Icons.person_outline,color:Theme.of(context).colorScheme.primary),title:Text('Profile details'),trailing:Icon(Icons.chevron_right),onTap:()=>pushNu(context,NativeProfile(api:api,name:'${profile!['name']}')).then((_)=>_loadAccount()))])),
   OutlinedButton(onPressed:busy?null:()=>_run(()async{await api.postJson('/auth/logout',{});await SessionStore().clear();await _workspace('guest');if(mounted)setState((){profile=null;wallet=null;pendingReference=null;});}),child:Text('Sign out')),
  ],NuTitle('Library & membership'),NuPanel(padding:0,child:Column(children:[_row('Saved items','Your reading list',Icons.bookmark_border,()=>_unavailable('Saved items')),_row('Downloads','Manage offline resources',Icons.download_outlined,()=>_unavailable('Downloads')),_row('Premium','Membership and benefits',Icons.workspace_premium_outlined,()=>_unavailable('Premium'))])),NuTitle('Preferences'),NuPanel(padding:0,child:ListTile(leading:Icon(Icons.tune_rounded),title:Text('Appearance & settings'),subtitle:Text('Fonts, colours, display mode and connection'),trailing:Icon(Icons.chevron_right),onTap:()=>pushNu(context,AppearanceSettings(api:api)))),NuPanel(padding:0,child:Column(children:[_row('Notifications','Updates and notification preferences',Icons.notifications_outlined,()=>pushNu(context,NuPage(title:'Notifications',child:_notifications()))),_row('Security','Account and session information',Icons.lock_outline,()=>pushNu(context,NuPage(title:'Security',child:ListView(padding:EdgeInsets.all(20),children:[NuTitle('Your account security'),NuPanel(child:Text('Your login token is stored in secure device storage. Website passwords and payment keys are never stored in the app. Sign out from Profile to end your session.'))]))))])),NuTitle('Help & support'),NuPanel(child:SelectableText('NOUN Update Educational Consultant\ninfo@nounupdate.com\nWhatsApp: +234 916 627 2869\n\nIndependent student support. Not an official arm of the National Open University of Nigeria.')),
 ]);
 Future<void> _fundDialog()async{await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text('Add funds'),content:TextField(controller:amount,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:InputDecoration(labelText:'Amount (₦)')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text('Cancel')),FilledButton(onPressed:(){Navigator.pop(c);_run(_fund);},child:Text('Continue'))]));}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:nuDeep,appBar:AppBar(backgroundColor:nuDeep,foregroundColor:Colors.white,title:Row(children:[BrandLogo(size:38),SizedBox(width:10),Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOUN Update',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('Your academic companion',style:TextStyle(fontSize:9,color:Color(0xffc9e9dc)))])))]),actions:[IconButton(tooltip:'Search tools',onPressed:()=>setState(()=>tab=2),icon:Icon(Icons.search)),IconButton(tooltip:'Refresh',onPressed:()=>_run(()async{await _loadAccount();if(mounted)setState(()=>feed=_feed());}),icon:Icon(Icons.refresh,size:21)),IconButton(tooltip:'Notifications',onPressed:()=>pushNu(context,NuPage(title:'Notifications',child:_notifications())),icon:Icon(Icons.notifications_none_rounded))]),
 body:ClipRRect(borderRadius:BorderRadius.vertical(top:Radius.circular(25)),child:ColoredBox(color:Theme.of(context).scaffoldBackgroundColor,child:Column(children:[if(busy)LinearProgressIndicator(minHeight:2),Expanded(child:SafeArea(top:false,child:switch(tab){0=>_home(),1=>_study(),2=>_tools(),3=>_updates(),_=>_profile()}))]))),
 bottomNavigationBar:NavigationBar(height:64,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded,color:Theme.of(context).colorScheme.primary),label:'Home'),NavigationDestination(icon:Icon(Icons.menu_book_outlined),label:'Study'),NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Tools'),NavigationDestination(icon:Icon(Icons.newspaper_outlined),label:'Updates'),NavigationDestination(icon:Icon(Icons.person_outline_rounded),label:'Profile')]));
}
class ArticlePage extends StatelessWidget {
 const ArticlePage({required this.api,required this.item,super.key});final ApiClient api;final Map<String,dynamic> item;
 @override Widget build(BuildContext context)=>NuPage(title:'NOUN Update',child:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/posts/${item['category']}/${item['id']}').then(unpack),builder:(c,s){if(s.hasError)return Center(child:Text('This article could not load. Please reopen it.'));if(!s.hasData)return Center(child:CircularProgressIndicator());final d=s.data!;return ListView(padding:EdgeInsets.all(22),children:[if(d['image_url']!=null)ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.network('${d['image_url']}',cacheWidth:960,errorBuilder:(_,__,___)=>SizedBox.shrink())),NuTitle('${d['title']}',subtitle:'${d['published_at']}'),SelectableText('${d['content_text']}',style:TextStyle(fontSize:16,height:1.7))]);}));
}
class ExamShop extends StatefulWidget {
  const ExamShop({required this.api,required this.signedIn,required this.onWallet,super.key});
  final ApiClient api;final bool signedIn;final VoidCallback onWallet;
  @override
  State<ExamShop> createState()=>_ExamShopState();
}
class _ExamShopState extends State<ExamShop> {
  List<Map<String,dynamic>> rows=[];final selected=<int>{};String query='';int page=1;bool more=false,busy=false;String? error;
  Map<String,dynamic>? pendingQuote;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load({bool next=false})async{
    if(busy)return;setState(()=>busy=true);
    try{final p=next?page+1:1;final d=_data(await widget.api.getJson('/exam-summaries?q=${Uri.encodeQueryComponent(query)}&page=$p'));
      if(mounted)setState((){rows=next?[...rows,..._items(d['items'])]:_items(d['items']);page=p;more=d['has_more']==true;error=null;});
    }catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _checkout()async{
    if(!widget.signedIn){widget.onWallet();return;}if(busy)return;setState(()=>busy=true);
    try{
      pendingQuote??=_data(await widget.api.postJson('/exam-summaries/quote',{'file_ids':selected.toList()}));
      if(!mounted)return;final q=pendingQuote!;
      final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text('Review Exam Summary order'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        for(final i in _items(q['items']))Padding(padding:EdgeInsets.only(bottom:8),child:Text('${i['name']} · ${_money(i['price_kobo'])}')),
        Divider(),Text('Subtotal: ${_money(q['subtotal_kobo'])}'),Text('Service charge: ${_money(q['fee_kobo'])}'),SizedBox(height:10),Text('Total: ${_money(q['total_kobo'])}',style:TextStyle(fontWeight:FontWeight.w800)),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text('Pay from wallet'))]));
      if(yes!=true)return;
      final order=_data(await widget.api.postJson('/exam-summaries/purchase',{'quote_id':q['quote_id']},idempotencyKey:'app-${q['quote_id']}'));
      pendingQuote=null;selected.clear();
      if(mounted)await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>OrderPage(api:widget.api,id:'${order['id']}')));
    }catch(e){if(e is ApiException&&e.code=='QUOTE_EXPIRED')pendingQuote=null;if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>NuPage(title:'Exam Summary',child:Column(children:[
    Padding(padding:EdgeInsets.all(18),child:TextField(onChanged:(v)=>query=v,onSubmitted:(_)=>_load(),decoration:InputDecoration(hintText:'Search a course or summary',prefixIcon:Icon(Icons.search),suffixIcon:IconButton(onPressed:()=>_load(),icon:Icon(Icons.arrow_forward))))),
    if(busy)LinearProgressIndicator(),if(error!=null)Padding(padding:EdgeInsets.all(14),child:Text(error!,style:TextStyle(color:Colors.red))),
    Expanded(child:ListView(children:[for(final r in rows)CheckboxListTile(value:selected.contains((r['id'] as num).toInt()),onChanged:busy?null:(v)=>setState((){pendingQuote=null;final id=(r['id'] as num).toInt();if(v==true){selected.add(id);}else{selected.remove(id);}}),title:Text(r['name'] as String),subtitle:Text(_money(r['price_kobo'])),secondary:GlossIcon(Icons.description_rounded,size:44,color:nuRed)),
      if(more)TextButton(onPressed:busy?null:()=>_load(next:true),child:Text('Load more')),if(rows.isEmpty&&!busy)TextButton(onPressed:()=>_load(),child:Text('No summaries loaded. Retry'))])),
    SafeArea(top:false,child:Padding(padding:EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[FilledButton(onPressed:busy||selected.isEmpty?null:_checkout,child:Text(widget.signedIn?'Review ${selected.length} selected':'Sign in to purchase')),TextButton(onPressed:widget.onWallet,child:Text('Open central wallet'))]))),
  ]));
}
class OrdersPage extends StatelessWidget {
  const OrdersPage({required this.api,super.key});final ApiClient api;
  @override
  Widget build(BuildContext context)=>NuPage(title:'My Exam Summaries',child:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/orders').then(_data),builder:(context,s){
    if(s.hasError)return Center(child:Text('Unable to load purchases. Please reopen this page.'));if(!s.hasData)return Center(child:CircularProgressIndicator());final rows=_items(s.data!['items']);
    if(rows.isEmpty)return Center(child:Text('No central-wallet purchases yet.'));
    return ListView(children:[for(final r in rows)ListTile(leading:GlossIcon(Icons.description_rounded,size:46,color:nuRed),title:Text('Order #${r['id']}'),subtitle:Text('${r['created_at']}'),trailing:Text(_money(r['total_kobo'])),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>OrderPage(api:api,id:'${r['id']}'))))]);
  }));
}
class OrderPage extends StatelessWidget {
  const OrderPage({required this.api,required this.id,super.key});final ApiClient api;final String id;
  @override
  Widget build(BuildContext context)=>NuPage(title:'Order #$id',child:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/orders/$id').then(_data),builder:(context,s){
    if(s.hasError)return Center(child:Text('Unable to load this order. Please reopen it.'));if(!s.hasData)return Center(child:CircularProgressIndicator());
    return ListView(padding:EdgeInsets.all(20),children:[Text('Your Exam Summaries',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),SizedBox(height:18),for(final r in _items(s.data!['items']))Card(child:ListTile(title:Text(r['name'] as String),trailing:IconButton(tooltip:'Download',icon:Icon(Icons.download),onPressed:()async{try{final d=_data(await api.postJson('/downloads/${r['id']}',{}));if(context.mounted)await pushNu(context,NativePdf(api:api,path:d['url'] as String,title:r['name'] as String));}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}})))]);
  }));
}
