import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/saved_resource_store.dart';
import '../widgets/native_ui.dart';

class NativeSavedResourcesPage extends StatefulWidget {
  const NativeSavedResourcesPage({
    super.key,
    required this.api,
    required this.userId,
    this.onOpen,
  });

  final ApiClient api;
  final String? userId;
  final void Function(Map<String,dynamic> resource)? onOpen;

  @override
  State<NativeSavedResourcesPage> createState()=>_NativeSavedResourcesPageState();
}

class _NativeSavedResourcesPageState extends State<NativeSavedResourcesPage>{
  late final SavedResourceStore store;
  bool loading=true;

  @override
  void initState(){
    super.initState();
    store=SavedResourceStore(api:widget.api,userId:widget.userId);
    _load();
  }

  Future<void> _load()async{
    if(mounted)setState(()=>loading=true);
    await store.load();
    if(mounted)setState(()=>loading=false);
  }

  Future<void> _remove(Map<String,dynamic> item)async{
    await store.setSaved(item,false);
    if(mounted){
      setState((){});
      nuMessage(context,store.pending.isEmpty?'Removed from saved resources.':'Removed on this device. Account sync is pending.');
    }
  }

  void _open(Map<String,dynamic> item){
    final callback=widget.onOpen;
    if(callback==null)return;
    final route='${item['route']??''}'.trim();
    callback({
      ...item,
      if(route.isNotEmpty)'route':route.startsWith('/')?route.substring(1):route,
    });
  }

  IconData _icon(String type)=>switch(type){
    'course_material'=>Icons.menu_book_rounded,
    'course_summary'=>Icons.auto_stories_rounded,
    'exam_summary'=>Icons.summarize_rounded,
    'past_question'=>Icons.description_outlined,
    'guide'=>Icons.lightbulb_outline_rounded,
    'course_hub'=>Icons.school_rounded,
    _=>Icons.bookmark_rounded,
  };

  @override
  Widget build(BuildContext context)=>NuPage(
    title:'Saved resources',
    child:RefreshIndicator(
      onRefresh:_load,
      child:ListView(
        padding:const EdgeInsets.all(20),
        physics:const AlwaysScrollableScrollPhysics(),
        children:[
          const ServiceHero(
            title:'Your saved library',
            subtitle:'Bookmarks stay available on this device and follow your account when you are signed in.',
            icon:Icons.bookmarks_outlined,
          ),
          if(widget.userId==null)const NuPanel(child:Text('You are using device-only bookmarks. Sign in to keep saved resources across your devices.')),
          if(store.pending.isNotEmpty)NuPanel(
            color:const Color(0xfffff3cd),
            child:Row(children:[
              const Icon(Icons.cloud_upload_outlined),
              const SizedBox(width:10),
              Expanded(child:Text('${store.pending.length} saved-resource change${store.pending.length==1?' is':'s are'} waiting to sync. Pull to refresh when you are online.')),
            ]),
          ),
          if(loading)const Padding(padding:EdgeInsets.symmetric(vertical:18),child:LinearProgressIndicator()),
          if(!loading&&store.all.isEmpty)const NuPanel(child:Column(children:[
            Icon(Icons.bookmark_border_rounded,size:48),
            SizedBox(height:10),
            Text('Nothing saved yet',style:TextStyle(fontWeight:FontWeight.w800)),
            SizedBox(height:5),
            Text('Save useful materials, summaries, questions and course hubs to build your reading list.',textAlign:TextAlign.center),
          ])),
          for(final item in store.all)NuPanel(
            padding:0,
            child:ListTile(
              contentPadding:const EdgeInsets.fromLTRB(14,8,8,8),
              leading:GlossIcon(_icon('${item['resource_type']??''}'),size:42),
              title:Text('${item['title']??item['resource_key']}',style:const TextStyle(fontWeight:FontWeight.w800)),
              subtitle:Text([
                if('${item['course_code']??''}'.isNotEmpty)'${item['course_code']}',
                if('${item['resource_type']??''}'.isNotEmpty)'${item['resource_type']}'.replaceAll('_',' '),
              ].join(' · ')),
              onTap:widget.onOpen==null?null:()=>_open(item),
              trailing:IconButton(
                tooltip:'Remove from saved resources',
                onPressed:()=>_remove(item),
                icon:const Icon(Icons.bookmark_remove_outlined),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
