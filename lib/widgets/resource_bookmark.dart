import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/saved_resource_store.dart';
import 'native_ui.dart';

Map<String,dynamic> courseBookmark(String code,{bool summary=false})=>{
  'resource_key':'course:$code:${summary?'summary':'material'}',
  'resource_type':summary?'course_summary':'course_material',
  'title':'$code ${summary?'Course Summary':'Course Material'}',
  'course_code':code,
  'route':'/${summary?'course-summary':'courses'}/$code',
};

class ResourceBookmarkButton extends StatefulWidget {
  const ResourceBookmarkButton({super.key,required this.api,required this.resource,this.userId});
  final ApiClient api;final String? userId;final Map<String,dynamic> resource;
  @override State<ResourceBookmarkButton> createState()=>_ResourceBookmarkButtonState();
}
class _ResourceBookmarkButtonState extends State<ResourceBookmarkButton>{
  late SavedResourceStore store;bool ready=false,busy=false;
  String get id=>'${widget.resource['resource_key']}';
  @override void initState(){super.initState();store=SavedResourceStore(api:widget.api,userId:widget.userId);_load();}
  Future<void> _load()async{await store.load(force:false);if(mounted)setState(()=>ready=true);}
  Future<void> _toggle()async{
    if(!ready||busy)return;setState(()=>busy=true);
    try{
      final save=!store.contains(id);await store.setSaved(widget.resource,save);
      if(mounted)nuMessage(context,store.pending.containsKey(id)?'Saved on this device. Account sync is pending.':save?'Added to Saved resources.':'Removed from Saved resources.');
    }catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>IconButton(
    tooltip:store.contains(id)?'Remove bookmark':'Save resource',
    onPressed:ready&&!busy?_toggle:null,
    icon:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):Icon(store.contains(id)?Icons.bookmark_rounded:Icons.bookmark_border_rounded),
  );
}
