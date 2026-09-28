import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/premium_service.dart';
import '../widgets/native_ui.dart';

class PremiumProfileFrame {
  const PremiumProfileFrame(this.id,this.label,this.subtitle,this.primary,this.secondary,this.icon);
  final String id,label,subtitle;
  final Color primary,secondary;
  final IconData icon;
}

const premiumProfileFrames=<PremiumProfileFrame>[
  PremiumProfileFrame('classic','Classic','Clean NOUN Update profile',Color(0xff006341),Color(0xffe9f8f2),Icons.school_rounded),
  PremiumProfileFrame('academicGold','Academic Gold','Warm achievement frame',Color(0xffffc928),Color(0xff6f5410),Icons.workspace_premium_rounded),
  PremiumProfileFrame('campusGreen','Campus Green','Layered campus-inspired frame',Color(0xff0a7a52),Color(0xffbdebd8),Icons.eco_rounded),
  PremiumProfileFrame('futureGlow','Future Glow','Modern luminous technology frame',Color(0xff00b7c7),Color(0xff1a3757),Icons.auto_awesome_rounded),
  PremiumProfileFrame('editorialInk','Editorial Ink','Refined academic editorial frame',Color(0xff263238),Color(0xffd7c7a1),Icons.menu_book_rounded),
];

PremiumProfileFrame profileFrameById(String id)=>premiumProfileFrames.firstWhere((f)=>f.id==id,orElse:()=>premiumProfileFrames.first);

class PremiumProfileAvatar extends StatelessWidget {
  const PremiumProfileAvatar({super.key,required this.name,this.size=72,this.frameId});
  final String name;
  final double size;
  final String? frameId;
  @override Widget build(BuildContext context){
    final premium=PremiumService.instance;
    final frame=profileFrameById(frameId??premium.effectiveProfileFrame);
    final initials=name.trim().isEmpty?'NU':name.trim().split(RegExp(r'\s+')).take(2).map((e)=>e.characters.first.toUpperCase()).join();
    final classic=frame.id=='classic';
    return Semantics(label:'$name profile',child:Container(
      width:size,height:size,
      padding:EdgeInsets.all(classic?3:5),
      decoration:BoxDecoration(
        shape:BoxShape.circle,
        gradient:classic?null:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[frame.primary,frame.secondary,frame.primary]),
        color:classic?Theme.of(context).colorScheme.primaryContainer:null,
        boxShadow:classic?null:[BoxShadow(color:frame.primary.withValues(alpha:.28),blurRadius:14,spreadRadius:1)],
      ),
      child:Container(
        decoration:BoxDecoration(shape:BoxShape.circle,color:Theme.of(context).colorScheme.surface,border:Border.all(color:classic?Theme.of(context).colorScheme.outlineVariant:Colors.white.withValues(alpha:.75),width:2)),
        alignment:Alignment.center,
        child:Text(initials,style:TextStyle(fontSize:size*.27,fontWeight:FontWeight.w900,color:classic?Theme.of(context).colorScheme.primary:frame.primary)),
      ),
    ));
  }
}

class ProfileCosmeticsPage extends StatefulWidget {
  const ProfileCosmeticsPage({super.key,required this.api,this.name='Student'});
  final ApiClient api;
  final String name;
  @override State<ProfileCosmeticsPage> createState()=>_ProfileCosmeticsPageState();
}
class _ProfileCosmeticsPageState extends State<ProfileCosmeticsPage>{
  bool saving=false;
  String? selected;
  @override void initState(){super.initState();selected=PremiumService.instance.preferredProfileFrame;}
  Future<void> apply(String id)async{
    final premium=PremiumService.instance;
    if(id!='classic'&&!premium.allows('profile_frames')){nuMessage(context,'Active NOUN Update Premium is required to apply this profile style.');return;}
    setState(()=>saving=true);
    try{await premium.save(widget.api,{'profile_frame':id});if(mounted)setState(()=>selected=id);if(mounted)nuMessage(context,id=='classic'?'Classic profile restored.':'Premium profile style applied.');}
    catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>NuPage(title:'Profile styles',child:ListView(padding:const EdgeInsets.all(20),children:[
    const ServiceHero(title:'Make your profile feel like yours',subtitle:'Premium profile frames personalise your account without changing your academic details.',icon:Icons.account_circle_outlined),
    const SizedBox(height:12),
    Center(child:PremiumProfileAvatar(name:widget.name,size:110,frameId:selected)),
    const SizedBox(height:18),
    if(!PremiumService.instance.allows('profile_frames'))const NuPanel(child:Text('You can preview every frame. Applying a Premium frame requires active Premium access. The Classic frame remains free.')),
    for(final frame in premiumProfileFrames)NuPanel(child:Row(children:[
      PremiumProfileAvatar(name:widget.name,size:58,frameId:frame.id),const SizedBox(width:14),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(frame.label,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(frame.subtitle,style:TextStyle(fontSize:12,color:nuMuted(context)))])),
      if(selected==frame.id)const Icon(Icons.check_circle_rounded) else FilledButton.tonal(onPressed:saving?null:()=>apply(frame.id),child:Text(frame.id=='classic'?'Use':'Apply')),
    ])),
    const NuPanel(child:Text('If Premium expires, the app automatically shows the Classic profile again while remembering your selected Premium frame for a future reactivation.')),
  ]));
}
