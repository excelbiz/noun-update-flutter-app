import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api_client.dart';
import '../core/premium_service.dart';
import '../widgets/native_ui.dart';
import 'skin_gallery.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key,required this.api});
  final ApiClient api;
  @override State<PremiumPage> createState()=>_PremiumPageState();
}
class _PremiumPageState extends State<PremiumPage>{
  late Future<Map<String,dynamic>> config;
  @override void initState(){super.initState();config=widget.api.getJson('/premium/config').then(unpack);}
  @override Widget build(BuildContext context)=>NuPage(title:'NOUN Update Premium',child:ListView(padding:const EdgeInsets.all(20),children:[
    const ServiceHero(title:'Make it yours.\nUnderstand your progress.',subtitle:'Your academic essentials stay free.',icon:Icons.workspace_premium_outlined),
    const SizedBox(height:16),OutlinedButton.icon(onPressed:()=>pushNu(context,SkinGallery(api:widget.api)),icon:const Icon(Icons.palette_outlined),label:const Text('Preview all 10 Premium skins')),
    FutureBuilder<Map<String,dynamic>>(future:config,builder:(context,s){
      if(s.hasError)return AsyncError('Premium plans are not available right now. No payment has been started.',()=>setState(()=>config=widget.api.getJson('/premium/config').then(unpack)));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final c=s.data!;
      if(c['premium_enabled']!=true)return const NuPanel(child:Text('Premium is currently unavailable. Your study tools remain available.'));
      final features=Map<String,dynamic>.from(c['premium_features'] as Map? ?? {});
      const labels={'ad_free':'Completely ad-free','premium_skins':'10 Premium skins','mock_analytics':'Advanced Mock analytics','pop_analytics':'Advanced POP analytics','reports':'Downloadable analytics reports','custom_icons':'Custom app icons','profile_frames':'Premium profile styles','seasonal_skins':'Seasonal skins','milestone_celebrations':'Enhanced milestone celebrations'};
      return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const NuTitle('Your Premium experience'),for(final entry in labels.entries)if(features[entry.key]==true)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.check_circle_outline),title:Text(entry.value)),
        const NuTitle('Choose your plan'),for(final p in records(c['plans']))NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(p['badge']!=null)Chip(label:Text('${p['badge']}')),Text('${p['name']}',style:Theme.of(context).textTheme.titleLarge),
          if(p['promotion_active']==true)Text('${p['currency']} ${((p['regular_price_minor'] as num)/100).toStringAsFixed(0)}',style:const TextStyle(decoration:TextDecoration.lineThrough)),
          Text('${p['currency']} ${((p['price_minor'] as num)/100).toStringAsFixed(0)} / ${p['billing_period']}',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800)),
          if(p['promotion_active']==true&&p['promotion_text']!=null)Text('${p['promotion_text']}'),
        ])),
        const NuPanel(child:Text('Purchasing is not enabled in this preview build. Plan prices are supplied by NOUN Update; no payment is taken here.')),
      ]);
    }),
    TextButton.icon(onPressed:()async{final p=PremiumService.instance;final id=p.accountId;if(id==null){nuMessage(context,'Sign in to check your Premium access.');return;}await p.refresh(widget.api,id);if(context.mounted)nuMessage(context,p.isPremium?'Your Premium access is active.':p.error??'No active Premium access was returned. If you already paid, contact support with your payment reference. Do not pay again.');},icon:const Icon(Icons.sync),label:const Text('Recover Premium Payment · Check access')),
  ]));
}

class BirthdaySettings extends StatefulWidget {
  const BirthdaySettings({super.key,required this.api});final ApiClient api;
  @override State<BirthdaySettings> createState()=>_BirthdaySettingsState();
}
class _BirthdaySettingsState extends State<BirthdaySettings>{
  int? month,day;bool enabled=true,saving=false;
  static const months=['January','February','March','April','May','June','July','August','September','October','November','December'];
  @override void initState(){super.initState();final b=PremiumService.instance.birthday;month=b['month'] as int?;day=b['day'] as int?;enabled=b['celebration_enabled']!=false;}
  Future<void> save({bool remove=false})async{
    if(!remove&&(month==null||day==null)){nuMessage(context,'Choose your birthday month and day.');return;}
    setState(()=>saving=true);
    try{await PremiumService.instance.save(widget.api,{'birthday':{'month':remove?null:month,'day':remove?null:day,'celebration_enabled':enabled}});if(mounted)Navigator.pop(context);}
    catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>NuPage(title:'Your birthday',child:ListView(padding:const EdgeInsets.all(20),children:[
    const ServiceHero(title:'Let’s celebrate you',subtitle:'Birthday celebrations are free for everyone.',icon:Icons.cake_outlined),
    const SizedBox(height:16),const Text('We only use your birthday month and day to celebrate with you in NOUN Update. We do not need your birth year.'),const SizedBox(height:20),
    DropdownButtonFormField<int>(initialValue:month,decoration:const InputDecoration(labelText:'Month'),items:[for(int i=1;i<=12;i++)DropdownMenuItem(value:i,child:Text(months[i-1]))],onChanged:saving?null:(v)=>setState((){month=v;if(day!=null&&day!>DateTime(2000,v!+1,0).day)day=null;})),
    const SizedBox(height:14),DropdownButtonFormField<int>(key:ValueKey('$month-$day'),initialValue:day,decoration:const InputDecoration(labelText:'Day'),items:[for(int i=1;i<=(month==null?31:DateTime(2000,month!+1,0).day);i++)DropdownMenuItem(value:i,child:Text('$i'))],onChanged:saving?null:(v)=>setState(()=>day=v)),
    Material(color:Colors.transparent,child:SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Celebrate my birthday'),value:enabled,onChanged:saving?null:(v)=>setState(()=>enabled=v))),
    FilledButton(onPressed:saving?null:save,child:Text(saving?'Saving…':'Save birthday')),
    TextButton(onPressed:saving?null:()=>save(remove:true),child:const Text('Remove birthday')),
  ]));
}
class BirthdayBanner extends StatefulWidget {
  const BirthdayBanner({super.key,required this.name});final String name;
  @override State<BirthdayBanner> createState()=>_BirthdayBannerState();
}
class _BirthdayBannerState extends State<BirthdayBanner> with WidgetsBindingObserver {
  String? dismissed;Timer? clock;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);clock=Timer.periodic(const Duration(minutes:1),(_){if(mounted)setState((){});});}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&mounted)setState((){});}
  @override void dispose(){clock?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override Widget build(BuildContext context)=>ListenableBuilder(listenable:PremiumService.instance,builder:(context,_){
    final today=DateTime.now();final key='${PremiumService.instance.accountId}-${today.year}-${today.month}-${today.day}';
    if(!PremiumService.instance.isBirthday(today)||dismissed==key)return const SizedBox.shrink();
    final first=widget.name.trim().split(RegExp(r'\s+')).first;
    return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.cake_outlined),const Spacer(),IconButton(tooltip:'Dismiss birthday greeting',onPressed:()=>setState(()=>dismissed=key),icon:const Icon(Icons.close))]),
      Text('Happy Birthday, $first!',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:8),const Text('Another year of learning, growth and possibilities. NOUN Update is celebrating you today.'),
      TextButton.icon(onPressed:()=>pushNu(context,BrandedShareCard(title:'Happy Birthday, $first!',message:'May this new chapter bring you growth, knowledge and achievements worth celebrating.',author:'NOUN Update')),icon:const Icon(Icons.share_outlined),label:const Text('Share Birthday Card')),
    ]));
  });
}

class MotivationCard extends StatefulWidget {
  const MotivationCard({super.key,required this.api});final ApiClient api;
  @override State<MotivationCard> createState()=>_MotivationCardState();
}
class _MotivationCardState extends State<MotivationCard> with WidgetsBindingObserver {
  Timer? clock;String? loadedDay;
  Map<String,dynamic>? quote;bool offline=false,saving=false;
  String get today=>DateTime.now().toUtc().add(const Duration(hours:1)).toIso8601String().substring(0,10);
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);load();clock=Timer.periodic(const Duration(minutes:1),(_){if(loadedDay!=today)load();});}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&loadedDay!=today)load();}
  @override void dispose(){clock?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  Future<void> load()async{
    loadedDay=today;
    if(mounted)setState((){if(quote?['date']!=today)quote=null;offline=false;});
    final prefs=await SharedPreferences.getInstance();
    try{
      final r=unpack(await widget.api.getJson('/motivation/today'));
      final q=r['quote']==null?null:Map<String,dynamic>.from(r['quote'] as Map);
      if(q==null){await prefs.remove('nu-daily-motivation');}else{await prefs.setString('nu-daily-motivation',jsonEncode(q));}
      if(mounted)setState(()=>quote=q);
    }catch(_){
      try{final q=jsonDecode(prefs.getString('nu-daily-motivation')??'null');if(q is Map&&q['date']==today&&mounted)setState((){quote=Map<String,dynamic>.from(q);offline=true;});}catch(_){/* Discard damaged cache. */}
    }
  }
  @override Widget build(BuildContext context){final q=quote;if(q==null||q['date']!=today)return const SizedBox.shrink();return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('TODAY’S MOTIVATION',style:TextStyle(color:Theme.of(context).colorScheme.primary,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.5)),const SizedBox(height:12),
    Text('“${q['quote']}”',style:const TextStyle(fontSize:21,height:1.4,fontWeight:FontWeight.w700)),const SizedBox(height:10),Text('— ${q['author']}'),
    if(offline)const Text('Saved for today · Offline',style:TextStyle(fontSize:11)),
    Wrap(spacing:8,children:[TextButton.icon(onPressed:()=>pushNu(context,BrandedShareCard(title:'Today’s motivation',message:'${q['quote']}',author:'${q['author']}')),icon:const Icon(Icons.share_outlined),label:const Text('Share Quote')),
    TextButton.icon(onPressed:saving?null:()async{if(PremiumService.instance.accountId==null){nuMessage(context,'Sign in to save your favourite quotes.');return;}setState(()=>saving=true);try{await widget.api.postJson('/motivation/saved',{'quote_id':int.parse('${q['id']}'),'saved':true});if(context.mounted)nuMessage(context,'Added to Saved Motivation.');}catch(e){if(context.mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>saving=false);}},icon:const Icon(Icons.favorite_border),label:const Text('Save Quote'))]),
  ]));}
}
class SavedMotivation extends StatefulWidget {
  const SavedMotivation({super.key,required this.api});final ApiClient api;
  @override State<SavedMotivation> createState()=>_SavedMotivationState();
}
class _SavedMotivationState extends State<SavedMotivation>{
  late Future<Map<String,dynamic>> data;
  @override void initState(){super.initState();data=widget.api.getJson('/motivation/saved').then(unpack);}
  @override Widget build(BuildContext context)=>NuPage(title:'Saved Motivation',child:FutureBuilder<Map<String,dynamic>>(future:data,builder:(context,s){
    if(s.hasError)return AsyncError('Sign in and reconnect to load your saved quotes.',()=>setState(()=>data=widget.api.getJson('/motivation/saved').then(unpack)));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=records(s.data!['items']);
    return ListView(padding:const EdgeInsets.all(20),children:[if(rows.isEmpty)const NuPanel(child:Text('Quotes you save will appear here.')),
    for(final q in rows)NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('“${q['quote']}”',style:const TextStyle(fontSize:20)),Text('— ${q['author']}'),Wrap(children:[TextButton(onPressed:()=>pushNu(context,BrandedShareCard(title:'A little motivation',message:'${q['quote']}',author:'${q['author']}')),child:const Text('Share Quote')),TextButton(onPressed:()async{try{await widget.api.postJson('/motivation/saved',{'quote_id':int.parse('${q['id']}'),'saved':false});if(mounted)setState(()=>data=widget.api.getJson('/motivation/saved').then(unpack));}catch(e){if(context.mounted)nuMessage(context,e);}},child:const Text('Remove'))])]))]);
  }));
}

/// Captures only the branded card, never personal account details or screen controls.
class BrandedShareCard extends StatefulWidget {
  const BrandedShareCard({super.key,required this.title,required this.message,required this.author});
  final String title,message,author;
  @override State<BrandedShareCard> createState()=>_BrandedShareCardState();
}
class _BrandedShareCardState extends State<BrandedShareCard>{
  final captureKey=GlobalKey();bool busy=false;
  Future<void> share()async{
    setState(()=>busy=true);
    try{
      await WidgetsBinding.instance.endOfFrame;
      final boundary=captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image=await boundary.toImage(pixelRatio:2);
      final bytes=await image.toByteData(format:ui.ImageByteFormat.png);image.dispose();
      if(!mounted||bytes==null)return;
      final box=context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(ShareParams(files:[XFile.fromData(bytes.buffer.asUint8List(),mimeType:'image/png')],fileNameOverrides:['noun-update-card.png'],sharePositionOrigin:box.localToGlobal(Offset.zero)&box.size));
    }catch(_){if(mounted)nuMessage(context,'The sharing menu could not open. Please try again.');}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>NuPage(title:'Share your card',child:ListView(padding:const EdgeInsets.all(20),children:[
    RepaintBoundary(key:captureKey,child:Container(padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,border:Border.all(color:Theme.of(context).colorScheme.primary,width:2),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Row(children:[BrandLogo(size:48),SizedBox(width:12),Expanded(child:Text('NOUN UPDATE',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)))]),
      const SizedBox(height:36),Text(widget.title.toUpperCase(),style:TextStyle(color:Theme.of(context).colorScheme.primary,letterSpacing:1.4,fontSize:12,fontWeight:FontWeight.w700)),const SizedBox(height:20),Text(widget.message,style:const TextStyle(fontSize:26,height:1.4,fontWeight:FontWeight.w700)),const SizedBox(height:22),Text('— ${widget.author}'),const SizedBox(height:40),const Text('Stay focused. Keep learning.\nnounupdate.com',style:TextStyle(fontSize:13,height:1.6)),
    ]))),const SizedBox(height:20),FilledButton.icon(onPressed:busy?null:share,icon:const Icon(Icons.ios_share),label:Text(busy?'Preparing card…':'Share to your apps')),
    const SizedBox(height:10),const Text('Choose an installed social app from your phone’s sharing menu. Nothing is posted automatically.'),
  ]));
}
