import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../widgets/sculpted_icon.dart';

const _green = Color(0xff075239);
const _gold = Color(0xffe8b94c);
const _paper = Color(0xfff4f7f2);
String _money(dynamic kobo) => '₦${((num.tryParse('$kobo') ?? 0) / 100).toStringAsFixed(2)}';
Map<String, dynamic> _data(Map<String, dynamic> response) => Map<String, dynamic>.from(response['data'] as Map);
List<Map<String, dynamic>> _items(dynamic value) => (value as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
String _key() => List.generate(24, (_) => math.Random.secure().nextInt(256).toRadixString(16).padLeft(2,'0')).join();
Future<void> _open(String value) async {
  final uri = Uri.parse(value.startsWith('/') ? 'https://nounupdate.com$value' : value);
  final host = uri.host.toLowerCase();
  if (uri.scheme != 'https' || (host != 'nounupdate.com' && host != 'paystack.com' && !host.endsWith('.paystack.com'))) {
    throw const ApiException('This link cannot be opened here.');
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw const ApiException('Unable to open this link.');
}
class SiteLogo extends StatelessWidget {
  const SiteLogo({this.size = 46, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Image.network('https://nounupdate.com/images/logo.webp',
    width:size,height:size,fit:BoxFit.contain,
    errorBuilder:(_,__,___)=>Image.asset('assets/images/noun_update_logo.png',width:size,height:size,fit:BoxFit.contain));
}

class LivePortal extends StatefulWidget {
  const LivePortal({this.apiClient, super.key});
  final ApiClient? apiClient;
  @override
  State<LivePortal> createState()=>_LivePortalState();
}
class _LivePortalState extends State<LivePortal> with WidgetsBindingObserver {
  late final ApiClient api;
  List<Map<String,dynamic>> services=[];
  Map<String,dynamic>? profile,wallet;
  int tab=0;
  bool busy=false;
  String search='', category='news';
  String? accountError;
  String? pendingReference;
  late Future<Map<String,dynamic>> feed;
  final email=TextEditingController(), password=TextEditingController(), amount=TextEditingController(text:'1000');
  @override
  void initState(){super.initState();api=widget.apiClient??ApiClient();WidgetsBinding.instance.addObserver(this);feed=_feed();_loadServices();_loadAccount();}
  @override
  void dispose(){WidgetsBinding.instance.removeObserver(this);email.dispose();password.dispose();amount.dispose();super.dispose();}
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&profile!=null)_loadAccount();}
  Future<Map<String,dynamic>> _feed()=>api.getJson('/posts/$category').then(_data);
  Future<void> _loadServices() async {
    final bundled=_items(jsonDecode(await rootBundle.loadString('assets/data/services.json')));
    if(mounted)setState(()=>services=bundled);
    try{final result=_data(await api.getJson('/services'));if(mounted)setState(()=>services=_items(result['items']));}catch(_){/* Local directory is functional offline; no fabricated account data. */}
  }
  Future<void> _loadAccount() async {
    try{
      if(await const SessionStore().readAccessToken()==null)return;
      final b=_data(await api.getJson('/app/bootstrap'));
      final p=b['profile']==null?null:Map<String,dynamic>.from(b['profile'] as Map);
      final prefs=await SharedPreferences.getInstance();
      final reference=p==null?null:prefs.getString('nu_pending_${p['id']}');
      if(mounted)setState((){profile=p;wallet=b['wallet']==null?null:Map<String,dynamic>.from(b['wallet'] as Map);pendingReference=reference;accountError=null;});
    }catch(e){if(mounted)setState((){accountError=e.toString();if(e is ApiException&&e.statusCode==401){profile=null;wallet=null;}});}
  }
  Future<void> _run(Future<void> Function() action) async {
    if(busy)return;setState(()=>busy=true);
    try{await action();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _login() async {
    final d=_data(await api.postJson('/auth/login',{'email':email.text.trim(),'password':password.text}));
    await const SessionStore().saveTokens(accessToken:d['access_token'] as String,refreshToken:d['refresh_token'] as String);
    password.clear();await _loadAccount();if(mounted)setState(()=>tab=3);
  }
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
    await _open(d['authorization_url'] as String);
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
    if(s['enabled']==false)return;
    final id=s['id'];
    if(id=='wallet'){setState(()=>tab=3);return;}
    if(['news','guides','scholarships'].contains(id)){setState((){tab=2;category=id as String;feed=_feed();});return;}
    if(id=='exam-summary'){
      Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>ExamShop(api:api,signedIn:profile!=null,onWallet:(){Navigator.of(context).pop();setState(()=>tab=3);}))).then((_)=>_loadAccount());return;
    }
    _run(()=>_open((s['url']??s['path']) as String));
  }
  Widget _heading(String title,[String? subtitle])=>Padding(padding:const EdgeInsets.only(top:24,bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800,letterSpacing:-.5)),
    if(subtitle!=null)Padding(padding:const EdgeInsets.only(top:5),child:Text(subtitle,style:const TextStyle(color:Color(0xff6e8076))))]));
  Widget _serviceGrid(List<Map<String,dynamic>> entries)=>LayoutBuilder(builder:(context,box){
    final columns=box.maxWidth>700?4:box.maxWidth>470?3:2;
    return GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:entries.length,
      gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,mainAxisSpacing:12,crossAxisSpacing:12,
        mainAxisExtent:MediaQuery.textScalerOf(context).scale(18)>23?205:168),
      itemBuilder:(_,i){final s=entries[i];final enabled=s['enabled']!=false;
        return Semantics(button:true,label:s['label'] as String,enabled:enabled,child:Material(color:Colors.white,borderRadius:BorderRadius.circular(23),
          child:InkWell(borderRadius:BorderRadius.circular(23),onTap:enabled?()=>_service(s):null,
            child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              SculptedIcon((s['icon']??'compass') as String,size:65,accent:i%5==4?const Color(0xffb75642):const Color(0xff0a7450)),
              const Spacer(),Text(s['label'] as String,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w800,fontSize:14,color:enabled?_green:Colors.grey)),
              const SizedBox(height:4),Text(!enabled?'Coming soon':s['mode']=='native'?'Open':'Website ↗',style:const TextStyle(fontSize:11,color:Color(0xff748579))),
            ])))));
      });
  });
  Widget _home()=>ListView(padding:const EdgeInsets.fromLTRB(20,8,20,28),children:[
    Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:const LinearGradient(colors:[Color(0xff063d2d),Color(0xff087b54)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('YOUR NOUN. ALL TOGETHER.',style:TextStyle(color:_gold,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.5)),
      const SizedBox(height:13),Text(profile==null?'A little more ready.\nEvery single day.':'Welcome back,\n${profile!['name']}.',style:const TextStyle(fontSize:30,height:1.13,fontWeight:FontWeight.w800,color:Colors.white,letterSpacing:-.9)),
      const SizedBox(height:14),const Text('Your studies, updates and student tools,\nin one familiar place.',style:TextStyle(color:Color(0xffcee9dc),height:1.5)),
      const SizedBox(height:20),FilledButton(style:FilledButton.styleFrom(backgroundColor:_gold,foregroundColor:_green),onPressed:()=>setState(()=>tab=1),child:const Text('Explore your tools  ↗')),
    ])),
    _heading('Make today count','Your most useful shortcuts'),
    _serviceGrid(services.where((s)=>['courses','course-summary','exam-summary','pas-status','calendar','wallet'].contains(s['id'])).toList()),
    _heading('From the newsroom','Published on NOUN Update'),_newsList(compact:true),
  ]);
  Widget _explore(){final shown=services.where((s)=>'${s['label']} ${s['group']}'.toLowerCase().contains(search.toLowerCase())).toList();
    final groups=shown.map((s)=>s['group'] as String).toSet();
    return ListView(padding:const EdgeInsets.fromLTRB(20,8,20,28),children:[
      _heading('Find your next step','Everything, organised around you.'),
      TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search tools, summaries, results…')),
      if(shown.isEmpty)const Padding(padding:EdgeInsets.all(28),child:Text('No matching service. Try a shorter search.')),
      for(final group in groups)...[_heading(group),_serviceGrid(shown.where((s)=>s['group']==group).toList())],
    ]);
  }
  Widget _newsList({bool compact=false})=>FutureBuilder<Map<String,dynamic>>(future:feed,builder:(context,snapshot){
    if(snapshot.connectionState!=ConnectionState.done)return const Padding(padding:EdgeInsets.all(30),child:Center(child:CircularProgressIndicator()));
    if(snapshot.hasError)return _errorCard('Updates could not load. Check your connection and retry.',()=>setState(()=>feed=_feed()));
    final rows=_items(snapshot.data?['items']);
    if(rows.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('No published updates in this category yet.')));
    return Column(children:[for(final r in compact?rows.take(3):rows)Card(margin:const EdgeInsets.only(bottom:12),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>ArticlePage(api:api,item:r))),child:Padding(padding:const EdgeInsets.all(16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(r['image_url']!=null)ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.network(r['image_url'] as String,width:74,height:80,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SculptedIcon('news',size:74)))else const SculptedIcon('news',size:74),
      const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r['title'] as String,maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:7),Text('${r['published_at']}',style:const TextStyle(fontSize:12,color:Colors.grey))])),
    ]))))]);
  });
  Widget _updates()=>ListView(padding:const EdgeInsets.all(20),children:[_heading('Stay in the know'),
    Wrap(spacing:8,children:[for(final c in ['news','guides','scholarships','career','blog'])ChoiceChip(label:Text(c[0].toUpperCase()+c.substring(1)),selected:category==c,onSelected:(_)=>setState((){category=c;feed=_feed();}))]),
    const SizedBox(height:18),_newsList(),TextButton(onPressed:()=>_run(()=>_open(category=='news'?'/news/':category=='guides'?'/guides/':category=='scholarships'?'/scholarships.php':category=='career'?'/career-hub.php':'/news-index')),child:const Text('Browse the full archive ↗'))]);
  Widget _errorCard(String text,VoidCallback retry)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[Text(text),TextButton(onPressed:retry,child:const Text('Retry'))])));
  Widget _signIn()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Center(child:SculptedIcon('shield',size:92)),_heading('One account. One balance.','Use your existing Course Summary email and password.'),
    AutofillGroup(child:Column(children:[TextField(controller:email,keyboardType:TextInputType.emailAddress,autofillHints:const [AutofillHints.username],decoration:const InputDecoration(labelText:'Email address')),const SizedBox(height:12),TextField(controller:password,obscureText:true,autofillHints:const [AutofillHints.password],decoration:const InputDecoration(labelText:'Password'),onSubmitted:(_)=>_run(_login))])),
    const SizedBox(height:18),FilledButton(onPressed:busy?null:()=>_run(_login),child:const Text('Sign in')),
    TextButton(onPressed:()=>_run(()=>_open('/course/auth.php?mode=register')),child:const Text('Create an account ↗')),
    TextButton(onPressed:()=>_run(()=>_open('/course/forgot-password.php')),child:const Text('Forgot password?')),
  ]);
  Widget _walletPage()=>ListView(padding:const EdgeInsets.all(20),children:[
    if(profile==null)_signIn()else...[
      _heading('Your central wallet','Shared with Course Summary and Exam Summary checkout.'),
      if(accountError!=null)_errorCard(accountError!,_loadAccount),
      Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:_green,borderRadius:BorderRadius.circular(26)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('AVAILABLE BALANCE',style:TextStyle(color:Color(0xffb8dacc),fontSize:11,letterSpacing:1.2)),const SizedBox(height:9),Text(wallet==null?'—':_money(wallet!['balance_kobo']),style:const TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w800))])),const SculptedIcon('wallet',size:85,accent:Color(0xff2fa477))])),
      const SizedBox(height:20),TextField(controller:amount,keyboardType:TextInputType.number,inputFormatters:[FilteringTextInputFormatter.digitsOnly],decoration:const InputDecoration(labelText:'Add money (₦)',hintText:'1000')),
      const SizedBox(height:12),FilledButton(onPressed:busy?null:()=>_run(_fund),child:const Text('Continue to Paystack')),
      if(pendingReference!=null)Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[const Text('Have you completed your payment?'),SelectableText(pendingReference!,style:const TextStyle(fontSize:11)),TextButton(onPressed:busy?null:()=>_run(_recheck),child:const Text('Recheck payment'))]))),
      OutlinedButton(onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>OrdersPage(api:api))),child:const Text('My Exam Summary purchases')),
      TextButton(onPressed:()=>_run(()=>_open('/course/wallet.php')),child:const Text('Payment history & recovery ↗')),
      _heading('Recent activity'),
      if(_items(wallet?['transactions']).isEmpty)const Text('No wallet transactions yet.'),
      for(final t in _items(wallet?['transactions']))Card(child:ListTile(title:Text(t['title'] as String),subtitle:Text('${t['created_at']}'),trailing:Text(_money(t['amount_kobo']),style:TextStyle(fontWeight:FontWeight.w800,color:(num.tryParse('${t['amount_kobo']}')??0)<0?const Color(0xffb45540):_green)))),
    ]]);
  Widget _account()=>ListView(padding:const EdgeInsets.all(20),children:[
    if(profile==null)_signIn()else...[
      const Center(child:SiteLogo(size:90)),_heading(profile!['name'] as String,profile!['email'] as String),
      ListTile(leading:const SculptedIcon('people',size:45),title:const Text('Manage profile'),trailing:const Icon(Icons.open_in_new,size:18),onTap:()=>_run(()=>_open('/course/profile.php'))),
      ListTile(leading:const SculptedIcon('shield',size:45),title:const Text('Privacy & account support'),onTap:()=>_run(()=>_open('/course/privacy.php'))),
      OutlinedButton(onPressed:busy?null:()=>_run(()async{await api.postJson('/auth/logout',{});await const SessionStore().clear();if(mounted)setState((){profile=null;wallet=null;pendingReference=null;accountError=null;});}),child:const Text('Sign out')),
    ],const SizedBox(height:30),const Text('NOUN Update Educational Consultant',style:TextStyle(fontWeight:FontWeight.w800)),
    const SizedBox(height:8),const Text('Independent student support. Not an official arm of the National Open University of Nigeria.',style:TextStyle(color:Colors.grey,fontSize:12)),
    TextButton(onPressed:()=>_run(()=>_open('/support.php')),child:const Text('Get help ↗')),
  ]);
  @override
  Widget build(BuildContext context)=>Scaffold(backgroundColor:_paper,
    appBar:AppBar(backgroundColor:_paper,title:const Row(children:[SiteLogo(),SizedBox(width:10),Text('NOUN UPDATE',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,letterSpacing:.5))]),
      actions:[IconButton(tooltip:'Refresh',onPressed:()=>_run(()async{await _loadAccount();if(mounted)setState(()=>feed=_feed());}),icon:const Icon(Icons.refresh))]),
    body:Column(children:[if(busy)const LinearProgressIndicator(minHeight:2),Expanded(child:SafeArea(top:false,child:switch(tab){0=>_home(),1=>_explore(),2=>_updates(),3=>_walletPage(),_=>_account()}))]),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
      NavigationDestination(icon:SculptedIcon('compass',size:32),label:'Home'),NavigationDestination(icon:SculptedIcon('book',size:32),label:'Explore'),NavigationDestination(icon:SculptedIcon('news',size:32),label:'Updates'),NavigationDestination(icon:SculptedIcon('wallet',size:32),label:'Wallet'),NavigationDestination(icon:SculptedIcon('people',size:32),label:'Account'),
    ]));
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({required this.api,required this.item,super.key});
  final ApiClient api;final Map<String,dynamic> item;
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('NOUN Update')),body:FutureBuilder<Map<String,dynamic>>(
    future:api.getJson('/posts/${item['category']}/${item['id']}').then(_data),builder:(context,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('This article could not load. Return to Updates and retry.')));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());final d=s.data!;
      return ListView(padding:const EdgeInsets.all(22),children:[if(d['image_url']!=null)ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.network(d['image_url'] as String,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),
        const SizedBox(height:20),Text(d['title'] as String,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:10),Text('${d['published_at']}',style:const TextStyle(color:Colors.grey)),const SizedBox(height:24),SelectableText(d['content_text'] as String,style:const TextStyle(fontSize:17,height:1.7)),const SizedBox(height:22),OutlinedButton(onPressed:()async{try{await _open(d['url'] as String);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}},child:const Text('Open original article ↗'))]);
    }));
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
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Exam Summary')),body:Column(children:[
    Padding(padding:const EdgeInsets.all(18),child:TextField(onChanged:(v)=>query=v,onSubmitted:(_)=>_load(),decoration:InputDecoration(hintText:'Search a course or summary',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:()=>_load(),icon:const Icon(Icons.arrow_forward))))),
    if(busy)const LinearProgressIndicator(),if(error!=null)Padding(padding:const EdgeInsets.all(14),child:Text(error!,style:const TextStyle(color:Colors.red))),
    Expanded(child:ListView(children:[for(final r in rows)CheckboxListTile(value:selected.contains((r['id'] as num).toInt()),onChanged:busy?null:(v)=>setState((){pendingQuote=null;final id=(r['id'] as num).toInt();if(v==true){selected.add(id);}else{selected.remove(id);}}),title:Text(r['name'] as String),subtitle:Text(_money(r['price_kobo'])),secondary:const SculptedIcon('document',size:44)),
      if(more)TextButton(onPressed:busy?null:()=>_load(next:true),child:const Text('Load more')),if(rows.isEmpty&&!busy)TextButton(onPressed:()=>_load(),child:const Text('No summaries loaded. Retry'))])),
    SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[FilledButton(onPressed:busy||selected.isEmpty?null:_checkout,child:Text(widget.signedIn?'Review ${selected.length} selected':'Sign in to purchase')),TextButton(onPressed:widget.onWallet,child:const Text('Open central wallet'))]))),
  ]));
}
class OrdersPage extends StatelessWidget {
  const OrdersPage({required this.api,super.key});final ApiClient api;
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('My Exam Summaries')),body:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/orders').then(_data),builder:(context,s){
    if(s.hasError)return Center(child:Text('Unable to load purchases. Please reopen this page.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=_items(s.data!['items']);
    if(rows.isEmpty)return const Center(child:Text('No central-wallet purchases yet.'));
    return ListView(children:[for(final r in rows)ListTile(leading:const SculptedIcon('document',size:46),title:Text('Order #${r['id']}'),subtitle:Text('${r['created_at']}'),trailing:Text(_money(r['total_kobo'])),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>OrderPage(api:api,id:'${r['id']}'))))]);
  }));
}
class OrderPage extends StatelessWidget {
  const OrderPage({required this.api,required this.id,super.key});final ApiClient api;final String id;
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Order #$id')),body:FutureBuilder<Map<String,dynamic>>(future:api.getJson('/orders/$id').then(_data),builder:(context,s){
    if(s.hasError)return const Center(child:Text('Unable to load this order. Please reopen it.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
    return ListView(padding:const EdgeInsets.all(20),children:[const Text('Your Exam Summaries',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:18),for(final r in _items(s.data!['items']))Card(child:ListTile(title:Text(r['name'] as String),trailing:IconButton(tooltip:'Download',icon:const Icon(Icons.download),onPressed:()async{try{final d=_data(await api.postJson('/downloads/${r['id']}',{}));await _open(d['url'] as String);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}})))]);
  }));
}
