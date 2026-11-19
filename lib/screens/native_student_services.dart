import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';
import '../widgets/glass_components.dart';
import '../core/green_glass.dart';

class NativeInformation extends StatefulWidget {
  const NativeInformation({super.key, required this.api, required this.id, required this.title});
  final ApiClient api;
  final String id, title;
  @override
  State<NativeInformation> createState() => _NativeInformationState();
}

class _NativeInformationState extends State<NativeInformation> {
  late Future<Map<String,dynamic>> document = fetch();
  Future<Map<String,dynamic>> fetch() async {
    if (widget.id == 'about') {
      return {
        'title': 'About NOUN Update',
        'sections': [
          {'heading':'Your academic companion', 'text':'NOUN Update is an independent educational support platform for students of the National Open University of Nigeria. Use it to organise your courses, find study materials and follow academic updates.'},
          {'heading':'Official student records', 'text':'NOUN Update is not the university. Use notices from the university to confirm official dates, results and requirements.'},
        ],
      };
    }
    return unpack(await widget.api.getJson('/information/${widget.id}'));
  }
  @override
  Widget build(BuildContext context) => NuPage(title:widget.title, child:FutureBuilder(
    future:document,builder:(context,snapshot) {
      if(snapshot.hasError) return Center(child:Padding(padding:const EdgeInsets.all(20),
        child:AsyncError(snapshot.error!,()=>setState(()=>document=fetch()))));
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final data=snapshot.data!;
      final sections=records(data['sections']);
      return ListView.builder(padding:const EdgeInsets.all(18),itemCount:sections.length+1,
        itemBuilder:(context,index) {
          if(index==0)return NuTitle('${data['title']}',subtitle:data['updated_at'] as String?);
          final section=sections[index-1];
          return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            if('${section['heading']??''}'.isNotEmpty) ...[
              Text('${section['heading']}',style:Theme.of(context).textTheme.titleMedium),
              const SizedBox(height:8),
            ],
            SelectableText('${section['text']}',style:const TextStyle(height:1.5)),
          ]));
        });
    }));
}

/// Local revision plan: scoped separately for each signed-in student and guest.
class NativeStudyHub extends StatefulWidget {
  const NativeStudyHub({super.key, required this.scope, required this.onMaterials,
    required this.onCourses, required this.onSaved, required this.onFocus});
  final String scope;
  final VoidCallback onMaterials,onCourses,onSaved,onFocus;
  @override State<NativeStudyHub> createState()=>_NativeStudyHubState();
}

class _NativeStudyHubState extends State<NativeStudyHub> {
  final input=TextEditingController();
  List<Map<String,dynamic>> tasks=[];
  bool loading=true,saving=false;
  Object? error;
  String get storageKey=>'nu-revision-plan-v1-${widget.scope}';
  @override void initState(){super.initState();load();}
  @override void dispose(){input.dispose();super.dispose();}
  Future<void> load()async{
    try{
      final raw=(await SharedPreferences.getInstance()).getString(storageKey);
      final result=raw==null?<Map<String,dynamic>>[]:records(jsonDecode(raw));
      if(mounted)setState((){tasks=result;loading=false;error=null;});
    }catch(_){if(mounted)setState((){error='Your saved revision plan could not be read.';loading=false;});}
  }
  Future<void> save(List<Map<String,dynamic>> next,{bool clear=false})async{
    if(saving||loading||error!=null)return;
    setState(()=>saving=true);
    try{
      final ok=await (await SharedPreferences.getInstance()).setString(storageKey,jsonEncode(next));
      if(!ok)throw StateError('Could not save');
      if(mounted)setState((){tasks=next;if(clear)input.clear();});
    }catch(_){if(mounted)nuMessage(context,'Could not save the revision plan on this device.');}
    finally{if(mounted)setState(()=>saving=false);}
  }
  void add(){
    final value=input.text.trim();
    if(value.isEmpty)return;
    if(tasks.length>=100){nuMessage(context,'Remove a finished task before adding another.');return;}
    save([...tasks,{'title':value,'done':false}],clear:true);
  }
  @override Widget build(BuildContext context){
    final completed=tasks.where((task)=>task['done']==true).length;
    return NuPage(title:'Study Hub',child:ListView(padding:const EdgeInsets.all(18),children:[
      if(GreenGlass.of(context)!=null)...[
        const GlassHero(title:'Your all-in-one Study Space',subtitle:'Learn · Practice · Revise',artwork:BookStackArt()),
        const SizedBox(height:11),
        GlassRow(icon:Icons.menu_book_outlined,title:'Course Materials',onTap:widget.onMaterials),
        GlassRow(icon:Icons.edit_note_rounded,title:'My Courses & Revision Notes',onTap:widget.onCourses),
        GlassRow(icon:Icons.bookmark_outline,title:'Saved Resources',onTap:widget.onSaved),
        GlassRow(icon:Icons.timer_outlined,title:'Focus Timer',onTap:widget.onFocus),
      ]else...[
      const ServiceHero(title:'Your all-in-one study space',subtitle:'Plan your revision and return to your courses.',icon:Icons.school_outlined),
      NuPanel(padding:0,child:Column(children:[
        ListTile(leading:const Icon(Icons.menu_book_outlined),title:const Text('Course materials'),onTap:widget.onMaterials,trailing:const Icon(Icons.chevron_right)),
        ListTile(leading:const Icon(Icons.school_outlined),title:const Text('My Courses & notes'),onTap:widget.onCourses,trailing:const Icon(Icons.chevron_right)),
        ListTile(leading:const Icon(Icons.bookmark_outline),title:const Text('Saved resources'),onTap:widget.onSaved,trailing:const Icon(Icons.chevron_right)),
        ListTile(leading:const Icon(Icons.timer_outlined),title:const Text('Focus timer'),onTap:widget.onFocus,trailing:const Icon(Icons.chevron_right)),
      ])),
      ],
      NuTitle('Revision plan',subtitle:'$completed of ${tasks.length} complete · saved on this device'),
      if(tasks.isNotEmpty) Padding(padding:const EdgeInsets.only(bottom:12),
        child:LinearProgressIndicator(value:completed/tasks.length,semanticsLabel:'Revision tasks completed')),
      if(loading)const LinearProgressIndicator(),
      if(error!=null)AsyncError(error!,load),
      if(!loading&&error==null)...[
        TextField(controller:input,maxLength:120,enabled:!saving,onSubmitted:(_)=>add(),
          decoration:const InputDecoration(labelText:'New revision task',hintText:'e.g. Review Unit 2')),
        Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:saving?null:add,
          icon:const Icon(Icons.add),label:const Text('Add task'))),
        if(tasks.isEmpty)const Padding(padding:EdgeInsets.only(top:14),child:Text('Add the first topic or reading session you want to finish.')),
        for(var i=0;i<tasks.length;i++)NuPanel(padding:0,child:Row(children:[
          Expanded(child:CheckboxListTile(title:Text('${tasks[i]['title']}'),value:tasks[i]['done']==true,
            onChanged:saving?null:(value)=>save([
              for(var n=0;n<tasks.length;n++)if(n==i){...tasks[n],'done':value==true}else tasks[n],
            ]))),
          IconButton(tooltip:'Remove task',onPressed:saving?null:()=>save([...tasks]..removeAt(i)),icon:const Icon(Icons.delete_outline)),
        ])),
      ],
    ]));
  }
}
