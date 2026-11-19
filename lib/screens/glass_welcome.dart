import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_components.dart';
import '../widgets/native_ui.dart';

/// First-run welcome. No session, student record or service call is needed.
class GlassWelcomeGate extends StatefulWidget {
  const GlassWelcomeGate({super.key,required this.home});
  final Widget home;
  @override State<GlassWelcomeGate> createState()=>_GlassWelcomeGateState();
}
class _GlassWelcomeGateState extends State<GlassWelcomeGate> {
  static const keyName='nu-green-glass-intro-v1';
  bool? seen;
  int step=0;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    var complete=false;
    try{complete=(await SharedPreferences.getInstance()).getBool(keyName)??false;}catch(_){/* Continue with local onboarding. */}
    if(mounted)setState(()=>seen=complete);
  }
  Future<void> finish()async{
    setState(()=>seen=true);
    try{await (await SharedPreferences.getInstance()).setBool(keyName,true);}catch(_){/* The dashboard remains usable. */}
  }
  @override Widget build(BuildContext context){
    if(seen==true)return widget.home;
    return Scaffold(backgroundColor:const Color(0xff00452f),body:Stack(fit:StackFit.expand,children:[
      const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,
        end:Alignment.bottomCenter,colors:[Color(0xff0b8554),Color(0xff00452f),Color(0xff031a12)]))),
      const GlassWaves(gold:true),
      SafeArea(child:seen==null?const Center(child:BrandLogo(size:120)):LayoutBuilder(builder:(context,box)=>
        SingleChildScrollView(padding:const EdgeInsets.fromLTRB(23,12,23,22),
          child:ConstrainedBox(constraints:BoxConstraints(minHeight:(box.maxHeight-34).clamp(0,double.infinity).toDouble()),
            child:Column(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Align(alignment:Alignment.centerRight,child:TextButton(onPressed:finish,
                style:TextButton.styleFrom(foregroundColor:Colors.white),child:const Text('Skip'))),
              if(step==0)...[
                const BrandLogo(size:128),
                const SizedBox(height:16),
                ClipRRect(borderRadius:BorderRadius.circular(19),child:Image.asset('assets/images/skins/campus.webp',
                  width:340,height:175,fit:BoxFit.cover,cacheWidth:720,
                  errorBuilder:(context,error,stack)=>const SizedBox(height:140,child:Center(child:Icon(Icons.school,size:75,color:Colors.white))))),
              ]else const SizedBox(width:186,height:178,child:BookStackArt()),
              Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Column(children:[
                Text(step==0?'NOUN Update':'All your NOUN study tools',textAlign:TextAlign.center,
                  style:Theme.of(context).textTheme.headlineMedium?.copyWith(color:Colors.white,fontWeight:FontWeight.w800)),
                const SizedBox(height:8),Text(step==0?'Your study companion for the National Open University of Nigeria':
                    'Organise your courses, read materials, save revision notes and check your exam timetable.',
                  textAlign:TextAlign.center,style:const TextStyle(color:Color(0xffdff6e8),height:1.45)),
                const SizedBox(height:13),
                Semantics(label:'Page ${step+1} of 2',child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                  for(var i=0;i<2;i++)Padding(padding:const EdgeInsets.symmetric(horizontal:4),
                    child:Icon(Icons.circle,size:8,color:i==step?const Color(0xff95f2ad):const Color(0xff597a66))),
                ])),
              ])),
              ConstrainedBox(constraints:const BoxConstraints(maxWidth:380),child:GlassAction(
                label:step==0?'Next':'Get started',icon:Icons.arrow_forward_rounded,
                onPressed:step==0?()=>setState(()=>step=1):finish)),
            ]))))),
    ]));
  }
}
