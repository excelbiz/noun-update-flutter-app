import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/skin_theme.dart';
import '../core/appearance.dart';
import '../core/api_client.dart';
import '../core/premium_service.dart';
import '../widgets/native_ui.dart';
import 'live_portal.dart';
import 'native_account.dart';

/// Preview never modifies account entitlement or the persisted active skin.
class SkinGallery extends StatelessWidget {
  const SkinGallery({super.key,this.api});
  final ApiClient? api;
  @override Widget build(BuildContext context) => NuPage(title:'App skins',child:ListView(
    padding:const EdgeInsets.all(18),children:[
      const Text('Your studies. Your style.',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const Text('The current NOUN Update design stays free. Explore ten Premium styles in light and dark.'),
      const SizedBox(height:18),
      for(final skin in AppSkin.values) Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
        minVerticalPadding:18,leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:skin.isPremium?Image.asset(SkinTokens.forSkin(skin,Brightness.light).heroAsset,width:68,height:62,fit:BoxFit.cover,cacheWidth:160):const BrandLogo(size:48)),
        title:Text(skin.label),subtitle:Text(skin.isPremium?'PREMIUM · Preview':'FREE · Current design'),
        trailing:const Icon(Icons.chevron_right),onTap:()=>pushNu(context,SkinPreview(skin:skin,api:api)))),
    ]));
}

class SkinPreview extends StatefulWidget {
  const SkinPreview({super.key,required this.skin,this.api});
  final ApiClient? api;
  final AppSkin skin;
  @override State<SkinPreview> createState()=>_SkinPreviewState();
}
class _SkinPreviewState extends State<SkinPreview> {
  bool dark=false,saving=false,login=false;
  late final previewApi=_SkinPreviewApi(editorial:widget.skin==AppSkin.elegantEditorial,bold:widget.skin==AppSkin.boldPremium,future:widget.skin==AppSkin.futureTech);
  @override void initState(){super.initState();dark=widget.skin==AppSkin.futureTech;}
  Future<void> apply()async{
    final api=widget.api;if(api==null)return;
    final service=PremiumService.instance;
    if(service.accountId==null){nuMessage(context,'Sign in to save your preferred skin.');return;}
    setState(()=>saving=true);
    try{await service.save(api,{'preferred_skin':widget.skin.name});if(mounted)nuMessage(context,'Your skin has been saved.');}
    catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context) => Theme(
    data:buildSkinTheme(widget.skin,brightness:dark?Brightness.dark:Brightness.light,fontFamily:Appearance.instance.family),
    child:Builder(builder:(context)=>Scaffold(
      appBar:AppBar(toolbarHeight:48,title:Text(widget.skin.label,style:const TextStyle(fontSize:16)),actions:[
        IconButton(tooltip:login?'Preview dashboard':'Preview sign-in',onPressed:()=>setState(()=>login=!login),icon:Icon(login?Icons.dashboard_outlined:Icons.login)),
        IconButton(tooltip:dark?'Preview light':'Preview dark',onPressed:()=>setState(()=>dark=!dark),icon:Icon(dark?Icons.light_mode:Icons.dark_mode)),
      ]),
      body:Column(children:[
        Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:16,vertical:5),color:Theme.of(context).colorScheme.secondaryContainer,child:const Text('STYLE PREVIEW · SAMPLE CONTENT',style:TextStyle(fontSize:10,letterSpacing:1))),
        Expanded(child:login?NativeAuth(previewApi):LivePortal(apiClient:previewApi,preview:true,previewData:widget.skin==AppSkin.elegantEditorial?editorialPreviewData():widget.skin==AppSkin.boldPremium?boldPreviewData():widget.skin==AppSkin.futureTech?futurePreviewData():null)),
        SafeArea(top:false,child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:5),child:ListenableBuilder(listenable:PremiumService.instance,builder:(context,_)=>Row(children:[
          Expanded(child:Text(widget.skin.isPremium?'Free preview · Premium to apply':'Your free default design',style:const TextStyle(fontSize:11))),
          FilledButton(onPressed:saving||widget.api==null||(widget.skin.isPremium&&!PremiumService.instance.allows('premium_skins'))?null:apply,child:Text(saving?'Saving…':'Apply skin')),
        ])))),
      ]),
    )));
}

/// Isolated read-only fixture: previews never contact payment/auth endpoints,
/// grant access or write to the real account. LivePortal is the real screen tree.
class _SkinPreviewApi extends ApiClient {
  _SkinPreviewApi({this.editorial=false,this.bold=false,this.future=false});
  final bool editorial,bold,future;
  @override Future<Map<String,dynamic>> getJson(String path)async{
    if(path=='/services')return {'data':{'items':jsonDecode(await rootBundle.loadString('assets/data/services.json'))}};
    if(path=='/motivation/today')return {'data':{'quote':{'id':0,'quote':editorial?'Discipline today creates the freedom you want tomorrow.':bold?'Consistency today creates success tomorrow.':'Discipline today, a brighter tomorrow.','author':bold?'NOUN Update':'NOUN Update · sample','date':DateTime.now().toUtc().add(const Duration(hours:1)).toIso8601String().substring(0,10)}}};
    if(future&&path.startsWith('/study/'))return futurePreviewStudy(path);
    if(future&&path.startsWith('/posts/'))return {'data':{'items':boldPreviewNotices()}};
    if(bold&&path=='/study/EDU302')return {'data':{'course_title':'Research Methods in Education','sections':[for(var i=0;i<20;i++){'index':i}]}};
    if(bold&&path=='/study/EDU302/state')return {'data':{'done':[for(var i=0;i<12;i++)i],'notes':'','revision':0}};
    if(bold&&path.startsWith('/posts/'))return {'data':{'items':boldPreviewNotices()}};
    if(editorial&&path=='/study/CIT321')return {'data':{'course_title':'Computer Systems and Networks','sections':[for(var i=0;i<20;i++){'index':i}]}};
    if(editorial&&path=='/study/CIT321/state')return {'data':{'done':[for(var i=0;i<13;i++)i],'notes':'','revision':0}};
    if(editorial&&path.startsWith('/posts/'))return {'data':{'items':[{'id':0,'category':'news','title':'Examination timetable now available','published_at':DateTime.now().toIso8601String()}]}};
    if(path.startsWith('/posts/'))return {'data':{'items':[]}};
    return {'data':{'items':[]}};
  }
  @override Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey})async=>throw const ApiException('This is a design preview. Return to the app to use your account.');
}

/// Read-only sample account for the clearly labelled Elegant Editorial preview.
/// This data is never used by the live account or persisted as membership.
Map<String,dynamic> editorialPreviewData(){
  final date=DateTime.now().add(const Duration(days:12));
  final examDate=DateTime(date.year,date.month,date.day,8);
  return {
   'details':{'Name':'Tunde Adebayo','Programme':'B.Sc. Computer Science','Level':'300 Level','Study centre':'Abuja Study Centre'},
   'courses':['CIT321'],
   'profile':<String,dynamic>{'id':'editorial-sample','name':'Tunde Adebayo','email':'student@example.test','matric_number':'NOUN/2023/123456'},
   'wallet':<String,dynamic>{'balance_kobo':520000,'transactions':[
    {'title':'Premium Subscription','amount_kobo':-300000,'created_at':DateTime.now().subtract(const Duration(days:3)).toIso8601String(),'status':'posted'},
    {'title':'Wallet Top Up','amount_kobo':500000,'created_at':DateTime.now().subtract(const Duration(days:5)).toIso8601String(),'status':'posted'},
    {'title':'Study Material Purchase','amount_kobo':-150000,'created_at':DateTime.now().subtract(const Duration(days:13)).toIso8601String(),'status':'posted'},
   ]},
   'next_exam':<String,dynamic>{'course_code':'CIT321','course_title':'Computer Systems and Networks','date':'${examDate.day} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][examDate.month-1]} ${examDate.year}','time':'9:00 AM WAT','exam_datetime':examDate.toIso8601String(),'is_past':false},
  };
}

// Isolated design data: no account, entitlement or wallet writes.
List<Map<String,dynamic>> boldPreviewNotices()=>[
 {'id':0,'category':'news','title':'2026_2 Exam Timetable is now available!','published_at':DateTime.now().toIso8601String()},
 {'id':1,'category':'news','title':'NOUN releases 2026_2 exam guidelines','published_at':DateTime.now().subtract(const Duration(hours:2)).toIso8601String()},
 {'id':2,'category':'news','title':'Keep your study plan up to date','published_at':DateTime.now().subtract(const Duration(days:1)).toIso8601String()},
];
Map<String,dynamic> boldPreviewData(){
 final date=DateTime.now().add(const Duration(days:2));
 final exam=DateTime(date.year,date.month,date.day,8);
 return {
  'details':{'Name':'NOUN Student','Programme':'B.Ed. Education','Level':'300 Level','Study centre':'Abeokuta Study Centre'},
  'courses':['EDU302'],
  'profile':<String,dynamic>{'id':'bold-sample','name':'NOUN Student','email':'student@example.test','matric_number':'NOUN/2024/123456'},
  'wallet':<String,dynamic>{'balance_kobo':500000,'transactions':[
   {'title':'Wallet Top Up','amount_kobo':500000,'created_at':DateTime.now().subtract(const Duration(days:2)).toIso8601String(),'status':'posted'},
   {'title':'Exam Practice (Mock)','amount_kobo':-50000,'created_at':DateTime.now().subtract(const Duration(days:4)).toIso8601String(),'status':'posted'},
   {'title':'Study Material Purchase','amount_kobo':-30000,'created_at':DateTime.now().subtract(const Duration(days:6)).toIso8601String(),'status':'posted'},
  ]},
  'next_exam':<String,dynamic>{'course_code':'EDU302','course_title':'Research Methods in Education','date':'${exam.day} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][exam.month-1]} ${exam.year}','time':'9:00 AM WAT','exam_datetime':exam.toIso8601String(),'is_past':false},
 };
}

// Read-only Future Tech samples. Progress is derived from these section records.
Map<String,dynamic> futurePreviewStudy(String path){
 final code=path.split('/')[2],count=code=='GST101'?20:code=='CIT101'?23:10,done=code=='GST101'?14:code=='CIT101'?0:10;
 if(path.endsWith('/state'))return {'data':{'done':[for(var i=0;i<done;i++)i],'notes':'','revision':0}};
 return {'data':{'course_title':code=='GST101'?'Use of English':code=='CIT101'?'Introduction to Computing':'Study resources','sections':[for(var i=0;i<count;i++){'index':i,'title':'Unit ${i+1}','content':'Sample course section for style review.'}]}};
}
Map<String,dynamic> futurePreviewData(){
 final sample=boldPreviewData(),date=DateTime.now().add(const Duration(days:15)),exam=DateTime(date.year,date.month,date.day,9);
 sample['courses']=['GST101','GST102','GST103','GST104','GST105','CIT101'];
 sample['profile']['id']='future-sample';sample['wallet']['balance_kobo']=1250000;
 sample['details']['Programme']='B.Sc. Computer Science';
 sample['next_exam']={'course_code':'GST101','course_title':'Use of English','date':'${exam.day}/${exam.month}/${exam.year}','time':'10:00 AM WAT','exam_datetime':exam.toIso8601String(),'is_past':false};
 return sample;
}
