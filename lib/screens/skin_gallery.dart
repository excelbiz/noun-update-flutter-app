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
  late final previewApi=_SkinPreviewApi();
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
        Expanded(child:login?NativeAuth(previewApi):LivePortal(apiClient:previewApi,preview:true)),
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
  @override Future<Map<String,dynamic>> getJson(String path)async{
    if(path=='/services')return {'data':{'items':jsonDecode(await rootBundle.loadString('assets/data/services.json'))}};
    if(path=='/motivation/today')return {'data':{'quote':{'id':0,'quote':'Discipline today, a brighter tomorrow.','author':'NOUN Update · sample','date':DateTime.now().toUtc().add(const Duration(hours:1)).toIso8601String().substring(0,10)}}};
    if(path.startsWith('/posts/'))return {'data':{'items':[]}};
    return {'data':{'items':[]}};
  }
  @override Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body,{String? idempotencyKey})async=>throw const ApiException('This is a design preview. Return to the app to use your account.');
}
