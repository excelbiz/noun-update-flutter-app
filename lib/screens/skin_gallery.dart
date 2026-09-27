import 'package:flutter/material.dart';
import '../core/skin_theme.dart';
import '../core/appearance.dart';
import '../widgets/native_ui.dart';

/// Preview never modifies account entitlement or the persisted active skin.
class SkinGallery extends StatelessWidget {
  const SkinGallery({super.key});
  @override Widget build(BuildContext context) => NuPage(title:'App skins',child:ListView(
    padding:const EdgeInsets.all(18),children:[
      const Text('Your studies. Your style.',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const Text('The current NOUN Update design stays free. Explore ten Premium styles in light and dark.'),
      const SizedBox(height:18),
      for(final skin in AppSkin.values) Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
        minVerticalPadding:18,leading:Icon(skin.isPremium?Icons.auto_awesome:Icons.school_outlined),
        title:Text(skin.label),subtitle:Text(skin.isPremium?'PREMIUM · Preview':'FREE · Current design'),
        trailing:const Icon(Icons.chevron_right),onTap:()=>pushNu(context,SkinPreview(skin:skin)))),
    ]));
}

class SkinPreview extends StatefulWidget {
  const SkinPreview({super.key,required this.skin});
  final AppSkin skin;
  @override State<SkinPreview> createState()=>_SkinPreviewState();
}
class _SkinPreviewState extends State<SkinPreview> {
  bool dark=false;
  @override Widget build(BuildContext context) => Theme(
    data:buildSkinTheme(widget.skin,brightness:dark?Brightness.dark:Brightness.light,fontFamily:Appearance.instance.family),
    child:Builder(builder:(context)=>Scaffold(
      appBar:AppBar(title:Text(widget.skin.label),actions:[IconButton(tooltip:dark?'Preview light':'Preview dark',onPressed:()=>setState(()=>dark=!dark),icon:Icon(dark?Icons.light_mode:Icons.dark_mode))]),
      body:ListView(padding:const EdgeInsets.all(18),children:[
        const Text('STYLE PREVIEW · SAMPLE CONTENT',style:TextStyle(fontSize:11,letterSpacing:1.2)),
        const SizedBox(height:18),
        Text('Good morning, student',style:Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height:8),const Text('Learn at your pace. Make today count.'),
        const SizedBox(height:20),
        NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('TODAY’S MOTIVATION',style:TextStyle(color:Theme.of(context).colorScheme.secondary,fontWeight:FontWeight.w700)),
          const SizedBox(height:12),const Text('“Small progress is still progress. Keep going.”',style:TextStyle(fontSize:23,height:1.4)),
          const SizedBox(height:8),const Text('Sample quote · NOUN Update'),
        ])),
        const NuTitle('Continue studying'),
        NuPanel(child:ListTile(contentPadding:EdgeInsets.zero,leading:const GlossIcon(Icons.menu_book_rounded),title:const Text('Your course workspace'),subtitle:const Text('Materials, notes and practice'),trailing:const Icon(Icons.chevron_right))),
        const NuTitle('Study resources'),
        for(final item in [('Course Summary',Icons.menu_book_rounded),('Exam Summary',Icons.description_rounded),('Past Questions',Icons.quiz_rounded)])
          NuPanel(child:ListTile(contentPadding:EdgeInsets.zero,leading:Icon(item.$2,color:Theme.of(context).colorScheme.primary),title:Text(item.$1),trailing:const Icon(Icons.chevron_right))),
        const SizedBox(height:12),
        Text(widget.skin.isPremium?'Applying Premium skins will be available after server-verified subscription integration. Previewing is free.':'This is your free default design.'),
        const SizedBox(height:18),OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('Back to skins')),
      ]),
    )));
}
