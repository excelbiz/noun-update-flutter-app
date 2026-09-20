import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';
import 'native_tools.dart';
import 'native_account.dart';

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
 List<Map<String,dynamic>> services=[];
 Map<String,dynamic>? profile,wallet;
 int tab=0;bool busy=false;String search='',category='news';
 String? accountError,pendingReference;
 late Future<Map<String,dynamic>> feed;
 final amount=TextEditingController(text:'1000');
 @override void initState(){super.initState();api=widget.apiClient??ApiClient();WidgetsBinding.instance.addObserver(this);feed=_feed();_loadServices();_loadAccount();}
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);amount.dispose();super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&profile!=null)_loadAccount();}
 Future<Map<String,dynamic>> _feed()=>api.getJson('/posts/$category').then(unpack);
 Future<void> _loadServices()async{
  final rows=records(jsonDecode(await (widget.serviceBundle??rootBundle).loadString('assets/data/services.json')));
  if(mounted)setState(()=>services=rows.where((s)=>s['id']!='quizly').toList());
  try{final d=unpack(await api.getJson('/services'));if(mounted)setState(()=>services=records(d['items']).where((s)=>s['id']!='quizly').toList());}catch(_){/* Retain bundled directory. */}
 }
 Future<void> _loadAccount()async{try{
  if(await const SessionStore().readAccessToken()==null)return;
  final b=unpack(await api.getJson('/app/bootstrap'));final p=b['profile']==null?null:Map<String,dynamic>.from(b['profile'] as Map);
  final prefs=await SharedPreferences.getInstance();
  if(mounted)setState((){profile=p;wallet=b['wallet']==null?null:Map<String,dynamic>.from(b['wallet'] as Map);pendingReference=p==null?null:prefs.getString('nu_pending_${p['id']}');accountError=null;});
 }catch(e){if(mounted)setState((){accountError='$e';if(e is ApiException&&e.statusCode==401){profile=null;wallet=null;}});}}
 Future<void> _run(Future<void> Function() action)async{if(busy)return;setState(()=>busy=true);try{await action();}catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>busy=false);}}
 Future<void> _login()async{final ok=await pushNu<bool>(context,NativeAuth(api));if(ok==true)await _loadAccount();}
  Future<void> _fund() async {
    if(profile==null)return;
    final naira=int.tryParse(amount.text.trim());
    if(naira==null||naira<1)throw const ApiException('Enter a whole-naira amount.');
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
    }else if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Payment is not confirmed yet. Recheck this payment; do not pay again.')));}
    await _loadAccount();
  }
 void _service(Map<String,dynamic> s){
  final id='${s['id']}',title='${s['label']}';
  if(id=='wallet'){setState(()=>tab=4);return;}
  if(['news','guides','scholarships','career','blog'].contains(id)){setState((){tab=3;category=id;feed=_feed();});return;}
  final Widget page=switch(id){
   'courses'||'course-materials'||'study-hub'=>MaterialLibrary(api:api,userId:profile?['id']?.toString()),
   'course-summary'=>MaterialLibrary(api:api,userId:profile?['id']?.toString(),summaries:true),
   'exam-summary'=>ExamShop(api:api,signedIn:profile!=null,onWallet:(){Navigator.pop(context);setState(()=>tab=4);}),
   'calendar'=>NativeCalendar(api),'fee-check'=>NativeFees(api),'cgpa-calculator'=>const NativeCgpa(),
   _=>NativeUnavailable(title),
  };
  pushNu(context,page).then((_)=>_loadAccount());
 }
 Widget _grid(List<Map<String,dynamic>> entries,{bool compact=false})=>LayoutBuilder(builder:(context,box){
  final scale=MediaQuery.textScalerOf(context).scale(14)/14;
  final columns=compact?(box.maxWidth>=350&&scale<1.3?5:4):(box.maxWidth>=330&&scale<1.3?3:2);
  return GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:entries.length,
   gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:compact?8:10,mainAxisSpacing:12,mainAxisExtent:(compact?104:143)+math.max(0,scale-1)*70),
   itemBuilder:(c,i){final s=entries[i],id='${s['id']}';return Material(color:compact?Colors.transparent:Color.lerp(Colors.white,serviceColour(id),.055),borderRadius:BorderRadius.circular(16),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>_service(s),child:Padding(padding:EdgeInsets.all(compact?2:10),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[GlossIcon(serviceIcon(id),color:serviceColour(id),size:compact?44:52),const SizedBox(height:10),Text('${s['label']}',textAlign:TextAlign.center,maxLines:3,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:compact?10:12,fontWeight:FontWeight.w700,height:1.15))]))));});
 });
 Widget _home()=>ListView(padding:const EdgeInsets.fromLTRB(16,18,16,28),children:[
  TextField(readOnly:true,onTap:()=>setState(()=>tab=2),decoration:const InputDecoration(hintText:'Search courses, materials and tools',prefixIcon:Icon(Icons.search))),
  NuTitle('Welcome${profile==null?'':', ${profile!['name']}'} 👋',subtitle:'What would you like to achieve today?'),
  Row(children:[for(final entry in [('Study',Icons.menu_book_rounded,1),('Tools',Icons.apps_rounded,2),('Updates',Icons.notifications_rounded,3),('Wallet',Icons.account_balance_wallet_rounded,4)])Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:InkWell(onTap:()=>setState(()=>tab=entry.$3),child:NuPanel(padding:9,child:Column(children:[Icon(entry.$2,color:nuGreen,size:24),const SizedBox(height:7),FittedBox(child:Text(entry.$1,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700)))])))))]),
  GreenBanner(title:'Your next step\nstarts here.',text:'Keep your studies, academic dates and revision together.',icon:Icons.school_rounded,action:FilledButton(style:FilledButton.styleFrom(backgroundColor:nuGold,foregroundColor:nuDeep),onPressed:()=>pushNu(context,NativeCalendar(api)),child:const Text('Academic calendar'))),
  const NuTitle('Quick access',subtitle:'Your student essentials, all in one place'),
  _grid(services.where((s)=>['courses','course-summary','exam-summary','fee-check','calendar','mock','result','cgpa-calculator','personalized-timetable','wallet'].contains(s['id'])).take(10).toList(),compact:true),
  const NuTitle('Recommended for you'),
  Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:_recommend('Course Summary','Understand each unit',nuGold,()=>pushNu(context,MaterialLibrary(api:api,userId:profile?['id']?.toString(),summaries:true)))),const SizedBox(width:12),Expanded(child:_recommend('Exam Summary','Focus your revision',nuRed,()=>_service({'id':'exam-summary','label':'Exam Summary'})))]),
  const NuTitle('Latest updates'),_news(compact:true),
 ]);
 Widget _recommend(String title,String text,Color color,VoidCallback action)=>InkWell(onTap:action,child:NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[GlossIcon(Icons.auto_stories_rounded,color:color,size:45),const SizedBox(height:14),Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(text,style:const TextStyle(fontSize:11,color:Colors.black54))])));
 Widget _study()=>ListView(padding:const EdgeInsets.all(16),children:[const NuTitle('Study smarter',subtitle:'Your courses, notes and revision in one place.'),const GreenBanner(title:'A little progress.\nEvery day.',text:'Open your course to read modules, save notes and track your progress.',icon:Icons.menu_book_rounded),const NuTitle('Your study library'),_grid(services.where((s)=>['courses','course-summary','exam-summary'].contains(s['id'])).toList()),NuPanel(child:ListTile(leading:const GlossIcon(Icons.timer_rounded,size:45),title:const Text('Pomodoro focus'),subtitle:const Text('Make time for one focused session'),onTap:()=>pushNu(context,const FocusTimer())))]);
 Widget _tools(){final rows=services.where((s)=>'${s['label']} ${s['group']}'.toLowerCase().contains(search.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[const NuTitle('All your student tools'),const NuPanel(color:nuMint,child:Row(children:[Expanded(child:Text('Everything you need\nto stay ahead.',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:nuDeep))),GlossIcon(Icons.school_rounded,size:65)])),TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search tools, summaries and more')),const SizedBox(height:20),_grid(rows),if(rows.isEmpty)const Text('No tools match your search.')]);}
 Widget _news({bool compact=false})=>FutureBuilder<Map<String,dynamic>>(future:feed,builder:(context,s){
  if(s.hasError)return AsyncError('Updates could not load. Please try again.',()=>setState(()=>feed=_feed()));
  if(!s.hasData)return const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));
  final rows=records(s.data!['items']);if(rows.isEmpty)return const NuPanel(child:Text('No published updates in this category yet.'));
  return Column(children:[for(final r in compact?rows.take(3):rows)NuPanel(padding:0,child:ListTile(contentPadding:const EdgeInsets.all(14),leading:const GlossIcon(Icons.campaign_rounded,size:44),title:Text('${r['title']}',maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:14)),subtitle:Text('${r['published_at']}',style:const TextStyle(fontSize:11)),onTap:()=>pushNu(context,ArticlePage(api:api,item:r))))]);
 });
 Widget _notifications()=>ListView(padding:const EdgeInsets.all(16),children:[const NuTitle('Notifications',subtitle:'Published updates from NOUN Update'),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final c in ['news','guides','scholarships','career','blog'])Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(c[0].toUpperCase()+c.substring(1)),selected:category==c,onSelected:(_)=>setState((){category=c;feed=_feed();})))])),const SizedBox(height:16),NuPanel(color:nuMint,child:ListTile(contentPadding:EdgeInsets.zero,leading:const GlossIcon(Icons.calendar_month,size:42),title:const Text('Academic dates & deadlines'),subtitle:const Text('TMAs, registration and examinations'),onTap:()=>pushNu(context,NativeCalendar(api)))),_news()]);
 Widget _profile()=>ListView(padding:const EdgeInsets.all(16),children:[
  if(profile==null)...[const SizedBox(height:20),const Center(child:BrandLogo(size:100)),const NuTitle('One account. One balance.',subtitle:'Sign in to access your central wallet, purchases and saved study progress.'),FilledButton(onPressed:_login,child:const Text('Sign in')),OutlinedButton(onPressed:()=>pushNu<bool>(context,NativeAuth(api,initialMode:'register')).then((ok){if(ok==true)_loadAccount();}),child:const Text('Create an account'))]
  else ...[
   NuPanel(child:Row(children:[const GlossIcon(Icons.person_rounded,size:64),const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${profile!['name']}',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('${profile!['email']}',style:const TextStyle(fontSize:12))])),IconButton(tooltip:'Edit profile',onPressed:()=>pushNu(context,NativeProfile(api:api,name:'${profile!['name']}')).then((_)=>_loadAccount()),icon:const Icon(Icons.edit_outlined))])),
   if(accountError!=null)AsyncError(accountError!,_loadAccount),
   GreenBanner(title:wallet==null?'—':naira(wallet!['balance_kobo']),text:'CENTRAL WALLET\nShared with your website account',icon:Icons.account_balance_wallet_rounded,action:Wrap(spacing:8,children:[FilledButton(style:FilledButton.styleFrom(backgroundColor:nuGold,foregroundColor:nuDeep),onPressed:()=>_fundDialog(),child:const Text('Add funds')),TextButton(onPressed:()=>pushNu(context,NuPage(title:'Wallet history',child:ListView(padding:const EdgeInsets.all(18),children:[for(final t in records(wallet?['transactions']))NuPanel(child:ListTile(title:Text('${t['title']}'),subtitle:Text('${t['created_at']}'),trailing:Text(naira(t['amount_kobo'])))),if(records(wallet?['transactions']).isEmpty)const Text('No wallet transactions yet.')]))),child:const Text('History',style:TextStyle(color:Colors.white)))])),
   if(pendingReference!=null)NuPanel(child:Column(children:[const Text('A payment is awaiting confirmation.'),SelectableText(pendingReference!,style:const TextStyle(fontSize:11)),TextButton(onPressed:busy?null:()=>_run(_recheck),child:const Text('Recheck payment'))])),
   const NuTitle('My account'),NuPanel(padding:0,child:Column(children:[ListTile(leading:const Icon(Icons.description_outlined,color:nuGreen),title:const Text('My Exam Summaries'),trailing:const Icon(Icons.chevron_right),onTap:()=>pushNu(context,OrdersPage(api:api))),ListTile(leading:const Icon(Icons.person_outline,color:nuGreen),title:const Text('Profile details'),trailing:const Icon(Icons.chevron_right),onTap:()=>pushNu(context,NativeProfile(api:api,name:'${profile!['name']}')).then((_)=>_loadAccount()))])),
   OutlinedButton(onPressed:busy?null:()=>_run(()async{await api.postJson('/auth/logout',{});await const SessionStore().clear();if(mounted)setState((){profile=null;wallet=null;pendingReference=null;});}),child:const Text('Sign out')),
  ],const NuTitle('Help & support'),const NuPanel(child:SelectableText('NOUN Update Educational Consultant\ninfo@nounupdate.com\nWhatsApp: +234 916 627 2869\n\nIndependent student support. Not an official arm of the National Open University of Nigeria.')),
 ]);
 Future<void> _fundDialog()async{await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:const Text('Add funds'),content:TextField(controller:amount,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'Amount (₦)')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:(){Navigator.pop(c);_run(_fund);},child:const Text('Continue'))]));}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:nuDeep,appBar:AppBar(backgroundColor:nuDeep,foregroundColor:Colors.white,title:const Row(children:[BrandLogo(size:38),SizedBox(width:10),Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('NOUN Update',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('Learn at any place, at your pace.',style:TextStyle(fontSize:9,color:Color(0xffc9e9dc)))])))]),actions:[IconButton(tooltip:'Refresh',onPressed:()=>_run(()async{await _loadAccount();if(mounted)setState(()=>feed=_feed());}),icon:const Icon(Icons.refresh,size:21)),IconButton(tooltip:'Notifications',onPressed:()=>setState(()=>tab=3),icon:const Icon(Icons.notifications_none_rounded))]),
 body:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(25)),child:ColoredBox(color:const Color(0xfff8faf9),child:Column(children:[if(busy)const LinearProgressIndicator(minHeight:2),Expanded(child:SafeArea(top:false,child:switch(tab){0=>_home(),1=>_study(),2=>_tools(),3=>_notifications(),_=>_profile()}))]))),
 bottomNavigationBar:NavigationBar(height:74,backgroundColor:Colors.white,indicatorColor:nuMint,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded,color:nuGreen),label:'Home'),NavigationDestination(icon:Icon(Icons.menu_book_outlined),label:'Study'),NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Tools'),NavigationDestination(icon:Icon(Icons.notifications_none_rounded),label:'Notifications'),NavigationDestination(icon:Icon(Icons.person_outline_rounded),label:'Profile')]));
}
class ArticlePage extends StatelessWidget {
 const ArticlePage({required this.api,required this.item,super.key});final ApiClient api;final Map<String,dynamic> item;
 @override Widget build(BuildContext context)=>NuPage(title:'NOUN Update',child:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/posts/${item['category']}/${item['id']}').then(unpack),builder:(c,s){if(s.hasError)return const Center(child:Text('This article could not load. Please reopen it.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final d=s.data!;return ListView(padding:const EdgeInsets.all(22),children:[if(d['image_url']!=null)ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.network('${d['image_url']}',errorBuilder:(_,__,___)=>const SizedBox.shrink())),NuTitle('${d['title']}',subtitle:'${d['published_at']}'),SelectableText('${d['content_text']}',style:const TextStyle(fontSize:16,height:1.7))]);}));
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
      final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Review Exam Summary order'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        for(final i in _items(q['items']))Padding(padding:const EdgeInsets.only(bottom:8),child:Text('${i['name']} · ${_money(i['price_kobo'])}')),
        const Divider(),Text('Subtotal: ${_money(q['subtotal_kobo'])}'),Text('Service charge: ${_money(q['fee_kobo'])}'),const SizedBox(height:10),Text('Total: ${_money(q['total_kobo'])}',style:const TextStyle(fontWeight:FontWeight.w800)),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Pay from wallet'))]));
      if(yes!=true)return;
      final order=_data(await widget.api.postJson('/exam-summaries/purchase',{'quote_id':q['quote_id']},idempotencyKey:'app-${q['quote_id']}'));
      pendingQuote=null;selected.clear();
      if(mounted)await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>OrderPage(api:widget.api,id:'${order['id']}')));
    }catch(e){if(e is ApiException&&e.code=='QUOTE_EXPIRED')pendingQuote=null;if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>NuPage(title:'Exam Summary',child:Column(children:[
    Padding(padding:const EdgeInsets.all(18),child:TextField(onChanged:(v)=>query=v,onSubmitted:(_)=>_load(),decoration:InputDecoration(hintText:'Search a course or summary',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:()=>_load(),icon:const Icon(Icons.arrow_forward))))),
    if(busy)const LinearProgressIndicator(),if(error!=null)Padding(padding:const EdgeInsets.all(14),child:Text(error!,style:const TextStyle(color:Colors.red))),
    Expanded(child:ListView(children:[for(final r in rows)CheckboxListTile(value:selected.contains((r['id'] as num).toInt()),onChanged:busy?null:(v)=>setState((){pendingQuote=null;final id=(r['id'] as num).toInt();if(v==true){selected.add(id);}else{selected.remove(id);}}),title:Text(r['name'] as String),subtitle:Text(_money(r['price_kobo'])),secondary:const GlossIcon(Icons.description_rounded,size:44,color:nuRed)),
      if(more)TextButton(onPressed:busy?null:()=>_load(next:true),child:const Text('Load more')),if(rows.isEmpty&&!busy)TextButton(onPressed:()=>_load(),child:const Text('No summaries loaded. Retry'))])),
    SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[FilledButton(onPressed:busy||selected.isEmpty?null:_checkout,child:Text(widget.signedIn?'Review ${selected.length} selected':'Sign in to purchase')),TextButton(onPressed:widget.onWallet,child:const Text('Open central wallet'))]))),
  ]));
}
class OrdersPage extends StatelessWidget {
  const OrdersPage({required this.api,super.key});final ApiClient api;
  @override
  Widget build(BuildContext context)=>NuPage(title:'My Exam Summaries',child:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/orders').then(_data),builder:(context,s){
    if(s.hasError)return Center(child:Text('Unable to load purchases. Please reopen this page.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=_items(s.data!['items']);
    if(rows.isEmpty)return const Center(child:Text('No central-wallet purchases yet.'));
    return ListView(children:[for(final r in rows)ListTile(leading:const GlossIcon(Icons.description_rounded,size:46,color:nuRed),title:Text('Order #${r['id']}'),subtitle:Text('${r['created_at']}'),trailing:Text(_money(r['total_kobo'])),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>OrderPage(api:api,id:'${r['id']}'))))]);
  }));
}
class OrderPage extends StatelessWidget {
  const OrderPage({required this.api,required this.id,super.key});final ApiClient api;final String id;
  @override
  Widget build(BuildContext context)=>NuPage(title:'Order #$id',child:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/orders/$id').then(_data),builder:(context,s){
    if(s.hasError)return const Center(child:Text('Unable to load this order. Please reopen it.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
    return ListView(padding:const EdgeInsets.all(20),children:[const Text('Your Exam Summaries',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:18),for(final r in _items(s.data!['items']))Card(child:ListTile(title:Text(r['name'] as String),trailing:IconButton(tooltip:'Download',icon:const Icon(Icons.download),onPressed:()async{try{final d=_data(await api.postJson('/downloads/${r['id']}',{}));if(context.mounted)await pushNu(context,NativePdf(api:api,path:d['url'] as String,title:r['name'] as String));}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}})))]);
  }));
}
