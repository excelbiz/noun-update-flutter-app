import 'package:flutter/material.dart';
import '../core/appearance.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key,required this.api});
  final ApiClient api;
  @override State<AppearanceSettings> createState()=>_AppearanceSettingsState();
}
class _AppearanceSettingsState extends State<AppearanceSettings> {
  bool saving=false,checking=false;
  String? connection;
  Future<void> save({ThemeMode? mode,String? font,String? accent,bool? automatic,String? textSize}) async {
    if(saving)return;setState(()=>saving=true);
    try{await Appearance.instance.change(mode:mode,font:font,accent:accent,automatic:automatic,textSize:textSize);}catch(_){if(mounted)nuMessage(context,'Your preference could not be saved. Please try again.');}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Future<void> check() async {
    setState((){checking=true;connection=null;});
    try{final result=unpack(await widget.api.getJson('/health'));if(mounted)setState(()=>connection=result['status']=='ok'?'Connected to NOUN Update. Website data is available.':'The service is not ready. Please try again later.');}
    catch(_){if(mounted)setState(()=>connection='Unable to connect to NOUN Update. Check your internet connection and try again.');}
    finally{if(mounted)setState(()=>checking=false);}
  }
  @override Widget build(BuildContext context)=>ListenableBuilder(listenable:Appearance.instance,builder:(context,_){final a=Appearance.instance;return NuPage(title:'Settings',child:ListView(padding:const EdgeInsets.all(18),children:[
    const ServiceHero(title:'Make it yours',subtitle:'Choose a comfortable reading style and appearance.',icon:Icons.tune_rounded),
    const NuTitle('Appearance',subtitle:'Your preferences are saved on this device.'),
    NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Display mode',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:4,children:[ChoiceChip(key:const ValueKey('mode-auto'),label:const Text('Auto'),selected:a.automatic,onSelected:saving?null:(_)=>save(automatic:true)),for(final m in [ThemeMode.light,ThemeMode.dark,ThemeMode.system])ChoiceChip(key:ValueKey('mode-${m.name}'),label:Text(switch(m){ThemeMode.system=>'System',ThemeMode.light=>'Light',ThemeMode.dark=>'Dark'}),selected:!a.automatic&&a.mode==m,onSelected:saving?null:(_)=>save(mode:m))])])),
    const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('Auto uses light mode from 06:00 to 18:59 and dark mode from 19:00 to 05:59, using your device’s local time.')),
    NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Text size',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Wrap(spacing:8,children:[for(final size in Appearance.textSizes.keys)ChoiceChip(label:Text(size),selected:a.textSize==size,onSelected:saving?null:(_)=>save(textSize:size))])])),
    NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Reading font',style:TextStyle(fontWeight:FontWeight.w700)),for(final entry in Appearance.fonts.entries)ListTile(contentPadding:EdgeInsets.zero,title:Text(entry.key,style:TextStyle(fontFamily:entry.value.isEmpty?null:entry.value)),subtitle:Text('Clear ideas. Confident learning.',style:TextStyle(fontFamily:entry.value.isEmpty?null:entry.value,fontSize:12)),trailing:Icon(a.font==entry.key?Icons.radio_button_checked:Icons.radio_button_off,color:Theme.of(context).colorScheme.primary),onTap:saving?null:()=>save(font:entry.key))])),
    NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Accent colour',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:6,children:[for(final entry in Appearance.accents.entries)ChoiceChip(avatar:CircleAvatar(backgroundColor:entry.value,radius:9),label:Text(entry.key),selected:a.accent==entry.key,onSelected:saving?null:(_)=>save(accent:entry.key))]),const SizedBox(height:8),const Text('Applies to buttons, selections and highlights. NOUN Update branding stays consistent.',style:TextStyle(fontSize:12))])),
    NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Reading preview',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Prepare with purpose. Read your course materials, organise your notes and make steady progress.'),const SizedBox(height:12),FilledButton(onPressed:(){},child:const Text('Sample button'))])),
    TextButton(onPressed:saving?null:()=>save(automatic:true,textSize:'Default',mode:ThemeMode.system,font:'Modern sans',accent:'Emerald'),child:const Text('Restore default appearance')),
    const NuTitle('Connection'),NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Website updates, course resources and account details are securely loaded from NOUN Update.'),const SizedBox(height:12),OutlinedButton.icon(onPressed:checking?null:check,icon:const Icon(Icons.sync_rounded),label:Text(checking?'Checking…':'Check connection')),if(connection!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(connection!,semanticsLabel:connection))])),
    const Text('NOUN Update · Version 0.5.0',textAlign:TextAlign.center),
  ]));});
}
