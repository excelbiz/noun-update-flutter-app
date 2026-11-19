import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/academic_period.dart';
import '../core/api_client.dart';
import '../core/saved_resource_store.dart';
import '../widgets/native_ui.dart';
import '../widgets/glass_components.dart';
import '../core/green_glass.dart';
import '../core/study_state_store.dart';
import 'native_tools.dart';

class StudentWorkspace extends ChangeNotifier {
  StudentWorkspace(this.scope,{ApiClient? api}):api=api??ApiClient();
  final String scope;
  final ApiClient api;
  Map<String,String> details={};
  List<String> courses=[];
  Set<String> pins={};
  int revision=0;
  bool dirty=false;
  bool syncing=false;
  Map<String,dynamic>? conflict;
  int _edits=0,_generation=0;
  void beginEdit(){_edits++;_generation++;}
  void endEdit(){if(_edits>0)_edits--;}
  void _checkOwner(Map<String,dynamic> data){
    if(data['account_id']!=null && '${data['account_id']}'!=scope)throw const ApiException('The signed-in account changed. Reopen your workspace.');
  }
  Future<void> resolveConflict(bool keepLocal)async{
    final remote=conflict;if(remote==null||syncing)return;
    syncing=true;
    try{
      if(keepLocal){await _push(baseRevision:(remote['revision'] as num).toInt());}
      else{_applyRemote(remote);await _persist();}
      conflict=null;
    }on ApiException catch(e){
      if(e.code=='WORKSPACE_CONFLICT'){conflict=await _remote();}else{rethrow;}
    }finally{syncing=false;notifyListeners();}
  }
  bool get canSync=>RegExp(r'^\d+$').hasMatch(scope);
  bool get syncPending=>canSync&&dirty;
  bool get hasStudentDetails=>details.entries.any((entry)=>entry.key!='Session'&&entry.key!='Semester'&&entry.value.trim().isNotEmpty);
  AcademicPeriod get period=>AcademicPeriod.forDate(DateTime.now());
  String get key=>'nu-workspace-v1-$scope';

  Future<void> _persist() async {
    final ok=await (await SharedPreferences.getInstance()).setString(key,jsonEncode({
      'details':details,'courses':courses,'pins':pins.toList(),'revision':revision,'dirty':dirty,
    }));
    if(!ok)throw StateError('Could not save your changes.');
  }

  bool _ensureCurrentPeriod(){
    if(!hasStudentDetails)return false;
    final current=period;
    final changed=details['Session']!=current.sessionKey||details['Semester']!=current.semesterLabel;
    if(changed){
      details={...details,'Session':current.sessionKey,'Semester':current.semesterLabel};
    }
    return changed;
  }

  void _applyRemote(Map<String,dynamic> remote){
    _checkOwner(remote);
    conflict=null;
    details=Map<String,String>.from(remote['details'] as Map? ?? const {});
    courses=List<String>.from(remote['courses'] as List? ?? const []);
    pins=Set<String>.from(remote['pins'] as List? ?? const []);
    revision=(remote['revision'] as num?)?.toInt()??0;
    dirty=false;
  }

  Future<Map<String,dynamic>> _remote()async{final data=unpack(await api.getJson('/workspace'));_checkOwner(data);return data;}

  Future<void> _push({int? baseRevision})async{
    _ensureCurrentPeriod();
    final generation=_generation;
    final response=unpack(await api.postJson('/workspace',{
      'account_id':scope,
      'details':details,
      'courses':courses,
      'pins':pins.toList(),
      'base_revision':baseRevision??revision,
    }));
    _checkOwner(response);
    if(generation==_generation){_applyRemote(response);}else{revision=(response['revision'] as num).toInt();dirty=true;}
    await _persist();
  }

  Future<void> _syncLoaded({Map<String,dynamic>? bootstrapRemote}) async {
    if(!canSync||syncing||_edits>0)return;
    syncing=true;
    try{
      final generation=_generation;
      final remote=bootstrapRemote??await _remote();
      if(generation!=_generation)return;
      _checkOwner(remote);
      final exists=remote['exists']==true;
      final remoteRevision=(remote['revision'] as num?)?.toInt()??0;
      if(dirty || (!exists && (details.isNotEmpty||courses.isNotEmpty||pins.isNotEmpty))){
        if(exists && remoteRevision!=revision){conflict=remote;return;}
        try{
          await _push(baseRevision:revision);
        }on ApiException catch(e){
          if(e.code!='WORKSPACE_CONFLICT')rethrow;
          conflict=await _remote();
        }
      }else if(exists){
        _applyRemote(remote);
        if(_ensureCurrentPeriod()){
          dirty=true;
          await _persist();
          await _push(baseRevision:remoteRevision);
        }else{
          await _persist();
        }
      }
    }catch(_){
      // Offline or temporarily unavailable: keep the local copy and retry later.
    }finally{
      syncing=false;
      notifyListeners();
    }
  }

  Future<void> load({Map<String,dynamic>? bootstrapRemote}) async {
    if(_edits>0||syncing)return;
    try {
      final raw=(await SharedPreferences.getInstance()).getString(key);
      if(raw!=null){
        final d=jsonDecode(raw) as Map;
        details=Map<String,String>.from(d['details'] as Map? ?? const {});
        courses=List<String>.from(d['courses'] as List? ?? const []);
        pins=Set<String>.from(d['pins'] as List? ?? const []);
        revision=(d['revision'] as num?)?.toInt()??0;
        dirty=d['dirty'] is bool?d['dirty'] as bool:canSync;
      }
    } catch (_) { details={};courses=[];pins={};revision=0;dirty=false; }
    if(!canSync&&_ensureCurrentPeriod())await _persist();
    notifyListeners();
    await _syncLoaded(bootstrapRemote:bootstrapRemote);
  }

  Future<void> save() async {
    _generation++;
    _ensureCurrentPeriod();
    dirty=canSync;
    await _persist();
    notifyListeners();
    if(!canSync)return;
    try{
      await _push();
    }on ApiException catch(e){
      if(e.code=='WORKSPACE_CONFLICT'){
        try{
          conflict=await _remote();
        }catch(_){/* Keep the local edit queued for the next sync. */}
      }
      // Any other network/server error leaves the local edit queued safely.
    }catch(_){/* Keep the local edit queued safely. */}
    notifyListeners();
  }
}

class StudentSetup extends StatefulWidget {
  const StudentSetup({super.key,required this.workspace});
  final StudentWorkspace workspace;
  @override State<StudentSetup> createState()=>_StudentSetupState();
}
class _StudentSetupState extends State<StudentSetup> {
  final fields=<String,TextEditingController>{};bool saving=false;
  @override void initState(){super.initState();widget.workspace.beginEdit();for(final k in ['Name','Programme','Faculty','Level','Study centre']){fields[k]=TextEditingController(text:widget.workspace.details[k]??'');}}
  @override void dispose(){for(final c in fields.values){c.dispose();}widget.workspace.endEdit();super.dispose();}
  @override Widget build(BuildContext context){
    final period=widget.workspace.period;
    return NuPage(title:'Student details',child:ListView(padding:const EdgeInsets.all(20),children:[
      const NuTitle('Make this your dashboard',subtitle:'Add what you know. You can complete optional details later.'),
      WorkspaceConflictNotice(workspace:widget.workspace),
      Text(widget.workspace.canSync?'Saved offline on this device and synchronised to your NOUN Update account when connected.':'Saved on this device. Sign in to synchronise these details across devices.'),const SizedBox(height:16),
      NuPanel(child:Row(children:[const Icon(Icons.calendar_month_outlined),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Current academic period',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(period.displayLabel)]))])),
      const SizedBox(height:14),
      for(final f in fields.entries)Padding(padding:const EdgeInsets.only(bottom:14),child:TextField(controller:f.value,maxLength:120,decoration:InputDecoration(labelText:f.key,counterText:''))),
      FilledButton(onPressed:saving?null:() async {
        setState(()=>saving=true);
        final old=Map<String,String>.from(widget.workspace.details);
        widget.workspace.details={for(final f in fields.entries)f.key:f.value.text.trim(),'Session':period.sessionKey,'Semester':period.semesterLabel};
        try{await widget.workspace.save();if(context.mounted)Navigator.pop(context);}catch(_){widget.workspace.details=old;if(context.mounted)nuMessage(context,'Could not save your details. Please try again.');}finally{if(mounted)setState(()=>saving=false);}
      },child:Text(saving?'Saving…':'Save details')),
    ]));
  }
}

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key,required this.workspace,required this.openResource});
  final StudentWorkspace workspace;
  final void Function(String id,String label) openResource;
  @override State<MyCoursesPage> createState()=>_MyCoursesPageState();
}
class _MyCoursesPageState extends State<MyCoursesPage>{
 final code=TextEditingController();String? error;bool saving=false,bookmarksReady=false;
 late final SavedResourceStore saved;
 String section='Registered',query='';
 List<Map<String,dynamic>> library=[];
 Object? libraryError;
 bool libraryLoading=false;
 bool get glass=>GreenGlass.of(context)!=null;
 String? get studentId=>widget.workspace.canSync?widget.workspace.scope:null;
 final progress=<String,double>{};
 final _checked=<String>{};
 @override void didChangeDependencies(){super.didChangeDependencies();if(glass)loadProgress();}
 Future<void> loadProgress({bool refresh=false})async{
  final courses=widget.workspace.courses.where((c)=>refresh||_checked.add(c)).toList();
  await Future.wait(courses.map((course)async{
    try{
      final ratio=await StudyStateStore(api:widget.workspace.api,courseCode:course,userId:studentId).cachedProgress();
      if(mounted)setState((){if(ratio==null){progress.remove(course);}else{progress[course]=ratio;}});
    }catch(_){/* Reading history is optional. */}
  }));
 }
 Future<void> searchLibrary()async{
  if(libraryLoading)return;
  final search=query;
  setState((){libraryLoading=true;libraryError=null;});
  try{
   final result=unpack(await widget.workspace.api.getJson('/materials?q=${Uri.encodeQueryComponent(search)}'));
   if(mounted&&query==search)setState(()=>library=records(result['items']));
  }catch(e){if(mounted&&query==search)setState(()=>libraryError=e);}
  finally{if(mounted){setState(()=>libraryLoading=false);if(query!=search&&section=='All Courses')searchLibrary();}}
 }
 void addCourse(){
  final c=code.text.replaceAll(' ','').toUpperCase();
  if(!RegExp(r'^[A-Z]{2,5}[0-9]{3}$').hasMatch(c)){setState(()=>error='Enter a course code such as CIT411.');return;}
  if(widget.workspace.courses.contains(c)){setState(()=>error='This course is already saved.');return;}
  update([...widget.workspace.courses,c]);
 }
 Future<void> removeCourse(String c)async{
  final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text('Remove $c?'),
    content:const Text('This also removes it from your synchronised course list.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Remove'))]));
  if(yes==true&&mounted)await update(widget.workspace.courses.where((v)=>v!=c).toList());
 }
 void glassHub(String course)=>pushNu(context,GlassCourseOverview(api:widget.workspace.api,code:course,userId:studentId,
    programme:widget.workspace.details['Programme'],faculty:widget.workspace.details['Faculty'],
    openResource:widget.openResource)).then((_){if(mounted)loadProgress(refresh:true);});
 Widget glassCourses(BuildContext context){
  final items=widget.workspace.courses.where((c)=>c.contains(query.toUpperCase())&&
    (section!='Favourites'||saved.contains(bookmarkKey(c)))).toList();
  return ListView(padding:const EdgeInsets.fromLTRB(15,8,15,25),children:[
    TextField(onChanged:(v){setState(()=>query=v.trim());},onSubmitted:(_){if(section=='All Courses')searchLibrary();},
      decoration:InputDecoration(hintText:section=='All Courses'?'Search course code or title':'Search registered course codes',prefixIcon:const Icon(Icons.search),
        suffixIcon:section=='All Courses'?IconButton(tooltip:'Search course catalogue',onPressed:searchLibrary,icon:const Icon(Icons.arrow_forward)):null)),
    const SizedBox(height:9),
    Wrap(spacing:6,runSpacing:4,children:[for(final tab in ['Registered','All Courses','Favourites'])
      ChoiceChip(showCheckmark:false,label:Text(tab=='Registered'?'Registered (${widget.workspace.courses.length})':tab),
        selected:tab==section,onSelected:(_){setState(()=>section=tab);if(tab=='All Courses')searchLibrary();})]),
    const SizedBox(height:7),
    WorkspaceConflictNotice(workspace:widget.workspace),
    if(section=='All Courses')...[
      if(libraryLoading)const LinearProgressIndicator(),
      if(libraryError!=null)AsyncError(libraryError!,searchLibrary),
      if(!libraryLoading&&libraryError==null&&library.isEmpty)const NuPanel(child:Text('No courses found. Try a different search.')),
      for(final row in library)GlassRow(icon:Icons.menu_book_rounded,title:'${row['course_code']}',
        subtitle:'${row['title']??'Course material'}',onTap:()=>glassHub('${row['course_code']}')),
      if(library.isNotEmpty)TextButton(onPressed:()=>widget.openResource('courses','Course Materials'),child:const Text('Browse the full course library')),
    ]else...[
      if(items.isEmpty)NuPanel(child:Text(section=='Favourites'?'Use the bookmark beside a registered course to add it here.':
        query.isEmpty?'Add your registered courses to build your study list.':'No registered course matches this search.')),
      for(final c in items)GlassRow(icon:Icons.menu_book_rounded,title:c,
        subtitle:'Course materials and study tools',
        onTap:()=>glassHub(c),end:Row(mainAxisSize:MainAxisSize.min,children:[
          if(progress[c]!=null&&MediaQuery.textScalerOf(context).scale(12)<=15)GlassProgress(value:progress[c]!),
          PopupMenuButton<String>(tooltip:'Options for $c',
          icon:Icon(saved.contains(bookmarkKey(c))?Icons.bookmark_rounded:Icons.more_vert_rounded),
          onSelected:(value){if(value=='save'){toggleBookmark(c);}else{removeCourse(c);}},itemBuilder:(_)=>[
            PopupMenuItem(value:'save',enabled:bookmarksReady,child:Text(saved.contains(bookmarkKey(c))?'Remove favourite':'Add favourite')),
            PopupMenuItem(value:'remove',enabled:!saving,child:const Text('Remove course')),
          ]),
        ])),
      if(section=='Registered')...[
        const NuTitle('Add a course'),
        TextField(controller:code,textCapitalization:TextCapitalization.characters,onSubmitted:(_){if(!saving)addCourse();},
          decoration:InputDecoration(labelText:'Course code',hintText:'For example, CIT411',errorText:error)),
        const SizedBox(height:9),
        GlassAction(label:'Add course',icon:Icons.add,onPressed:saving?null:addCourse),
      ],
    ],
  ]);
 }

 @override void initState(){super.initState();saved=SavedResourceStore(api:widget.workspace.api,userId:widget.workspace.canSync?widget.workspace.scope:null);_loadBookmarks();}
 @override void dispose(){code.dispose();super.dispose();}
 String bookmarkKey(String course)=>'course:$course';
 Future<void> _loadBookmarks()async{await saved.load();if(mounted)setState(()=>bookmarksReady=true);}
 Future<void> toggleBookmark(String course)async{
  if(!bookmarksReady)return;
  final key=bookmarkKey(course),wasSaved=saved.contains(key);
  await saved.setSaved({
    'resource_key':key,
    'resource_type':'course_hub',
    'title':'$course Course Hub',
    'course_code':course,
    'route':'/courses',
  },!wasSaved);
  if(mounted){
    setState((){});
    final pending=saved.pending.containsKey(key);
    nuMessage(context,!wasSaved?(pending?'Course saved on this device. Account sync is pending.':'Course saved to your resources.'):'Course removed from saved resources.');
  }
 }
 Future<void> update(List<String> next) async {if(saving)return;setState(()=>saving=true);final old=List<String>.from(widget.workspace.courses);widget.workspace.courses=next;try{await widget.workspace.save();code.clear();if(mounted){setState(()=>error=null);if(glass)loadProgress();}}catch(_){widget.workspace.courses=old;if(mounted)setState(()=>error='Could not save your courses. Try again.');}finally{if(mounted)setState(()=>saving=false);}}
 void hub(String course)=>pushNu(context,NuPage(title:course,child:ListView(padding:const EdgeInsets.all(20),children:[
  NuTitle('$course Course Hub',subtitle:'Your resources, together.',trailing:IconButton(tooltip:saved.contains(bookmarkKey(course))?'Remove saved course':'Save course hub',onPressed:bookmarksReady?()=>toggleBookmark(course):null,icon:Icon(saved.contains(bookmarkKey(course))?Icons.bookmark_rounded:Icons.bookmark_border_rounded))),
  const NuPanel(child:Text('Exam date and assessment classification have not been verified. A non-examinable course is not automatically a PAS course.')),
  for(final item in [('courses','Course Material'),('course-summary','Course Summary'),('exam-summary','Exam Summary'),('past-questions','Past Questions'),('mock','Mock Examination'),('study-hub','Study Hub')])NuPanel(padding:0,child:ListTile(title:Text(item.$2),subtitle:Text('Open the library and search $course'),leading:const Icon(Icons.menu_book_outlined),trailing:const Icon(Icons.chevron_right),onTap:()=>widget.openResource(item.$1,item.$2))),
 ])));
 @override Widget build(BuildContext context)=>NuPage(title:'My Courses',child:ListenableBuilder(listenable:widget.workspace,builder:(context,_)=>glass?glassCourses(context):ListView(padding:const EdgeInsets.all(20),children:[
  const NuTitle('Your semester starts here',subtitle:'Keep your registered courses in one place.'),
  WorkspaceConflictNotice(workspace:widget.workspace),
  Text(widget.workspace.canSync?'Your courses work offline and synchronise with your account across devices.${widget.workspace.syncPending?' Changes are waiting to sync.':''}':'This course list is saved on this device. Sign in to synchronise it across devices.'),const SizedBox(height:16),
  TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:InputDecoration(labelText:'Course code',hintText:'For example, CIT411',errorText:error)),const SizedBox(height:10),
  FilledButton.icon(onPressed:saving?null:(){final c=code.text.replaceAll(' ','').toUpperCase();if(!RegExp(r'^[A-Z]{2,5}[0-9]{3}$').hasMatch(c)){setState(()=>error='Enter a course code such as CIT411.');return;}if(widget.workspace.courses.contains(c)){setState(()=>error='This course is already saved.');return;}update([...widget.workspace.courses,c]);},icon:const Icon(Icons.add),label:const Text('Add course')),
  const SizedBox(height:20),if(widget.workspace.courses.isEmpty)const NuPanel(child:Text('No courses added yet. Add your first registered course above.')),
  for(final c in widget.workspace.courses)NuPanel(padding:0,child:ListTile(title:Text(c),subtitle:Text(saved.contains(bookmarkKey(c))?'Saved course hub':'Open Course Hub'),onTap:()=>hub(c),leading:const Icon(Icons.school_outlined),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(tooltip:saved.contains(bookmarkKey(c))?'Remove saved course':'Save course hub',onPressed:bookmarksReady?()=>toggleBookmark(c):null,icon:Icon(saved.contains(bookmarkKey(c))?Icons.bookmark_rounded:Icons.bookmark_border_rounded)),IconButton(tooltip:'Remove $c',onPressed:saving?null:() async {final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text('Remove $c?'),content:const Text('This removes it from your saved course list on synchronised devices too.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Remove'))]));if(yes==true)await update(widget.workspace.courses.where((v)=>v!=c).toList());},icon:const Icon(Icons.close))]))),
 ])));
}

class GlassCourseOverview extends StatefulWidget {
  const GlassCourseOverview({super.key,required this.api,required this.code,required this.openResource,this.userId,this.programme,this.faculty});
  final ApiClient api;
  final String code;
  final String? userId,programme,faculty;
  final void Function(String id,String label) openResource;
  @override State<GlassCourseOverview> createState()=>_GlassCourseOverviewState();
}
class _GlassCourseOverviewState extends State<GlassCourseOverview>{
  String tab='Overview';
  late Future<Map<String,dynamic>?> material=fetch();
  Future<Map<String,dynamic>?> fetch()async{
    final data=unpack(await widget.api.getJson('/materials?q=${Uri.encodeQueryComponent(widget.code)}'));
    for(final row in records(data['items'])){
      if('${row['course_code']}'.replaceAll(' ','').toUpperCase()==widget.code.toUpperCase())return row;
    }
    return null;
  }
  void openPdf(Map<String,dynamic> row)=>pushNu(context,NativePdf(api:widget.api,path:'/materials/${row['id']}/pdf',title:'${widget.code} – Course Material'));
  @override Widget build(BuildContext context)=>NuPage(title:widget.code,child:FutureBuilder(
    future:material,builder:(context,result){
      final row=result.data;
      final title='${row?['title']??'Course workspace'}';
      return ListView(padding:const EdgeInsets.fromLTRB(15,8,15,26),children:[
        GlassHero(title:widget.code,subtitle:title,icon:Icons.menu_book_rounded),
        const SizedBox(height:10),
        Wrap(spacing:6,children:[for(final name in ['Overview','Materials','Summary','Past Qs'])
          ChoiceChip(showCheckmark:false,label:Text(name),selected:name==tab,onSelected:(_)=>setState(()=>tab=name))]),
        const SizedBox(height:7),
        if(result.connectionState==ConnectionState.waiting)const LinearProgressIndicator(),
        if(result.hasError)AsyncError('Course materials could not load.',()=>setState(()=>material=fetch())),
        if(tab=='Overview')...[
          GlassRow(icon:Icons.tag_rounded,title:'Course code',subtitle:widget.code),
          if(row?['title']!=null)GlassRow(icon:Icons.menu_book_outlined,title:'Course title',subtitle:title),
          if(row?['units']!=null)GlassRow(icon:Icons.format_list_numbered_rounded,title:'Units',subtitle:'${row!['units']}'),
          if(widget.programme?.trim().isNotEmpty==true)GlassRow(icon:Icons.school_outlined,title:'Your programme',subtitle:widget.programme),
          if(widget.faculty?.trim().isNotEmpty==true)GlassRow(icon:Icons.account_balance_outlined,title:'Your faculty',subtitle:widget.faculty),
          const SizedBox(height:8),GlassAction(label:'View Course Materials',icon:Icons.menu_book_outlined,onPressed:()=>setState(()=>tab='Materials')),
        ]else if(tab=='Materials')...[
          if(row!=null&&int.tryParse('${row['id']}')!=null)...[
            GlassRow(icon:Icons.picture_as_pdf_outlined,title:'Main course material',subtitle:'PDF · open in native reader',
              tone:nuRed,onTap:()=>openPdf(row)),
            GlassRow(icon:Icons.edit_note_rounded,title:'Study units and notes',onTap:()=>pushNu(context,
              NativeStudy(api:widget.api,row:row,userId:widget.userId))),
            GlassAction(label:'Open in Reader',icon:Icons.menu_book_rounded,onPressed:()=>openPdf(row)),
          ]else if(result.connectionState==ConnectionState.done&&!result.hasError)
            const NuPanel(child:Text('There is no matched PDF in the course library yet.')),
        ]else if(tab=='Summary')...[
          GlassRow(icon:Icons.auto_stories_outlined,title:'Course Summary',subtitle:'Review key concepts by unit',
            onTap:()=>pushNu(context,NativeSummary(api:widget.api,code:widget.code,signedIn:widget.userId!=null,userId:widget.userId))),
          GlassRow(icon:Icons.description_outlined,title:'Exam Summary',subtitle:'Open the exam revision catalogue',
            onTap:()=>widget.openResource('exam-summary','Exam Summary')),
        ]else
          GlassRow(icon:Icons.assignment_outlined,title:'Past Questions',onTap:()=>widget.openResource('past-questions','Past Questions')),
      ]);
    }));
}

class WorkspaceConflictNotice extends StatelessWidget {
 const WorkspaceConflictNotice({super.key,required this.workspace});final StudentWorkspace workspace;
 @override Widget build(BuildContext context)=>ListenableBuilder(listenable:workspace,builder:(context,_){
  if(workspace.conflict==null)return const SizedBox.shrink();
  return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('Your workspace changed on another device',style:TextStyle(fontWeight:FontWeight.w800)),
   const Text('Your device copy is safe. Review both copies before synchronising.'),
   TextButton(onPressed:workspace.syncing?null:()=>review(context),child:const Text('Review workspace copies')),
  ]));
 });
 Future<void> review(BuildContext context)async{
  final remote=workspace.conflict;if(remote==null)return;
  String describe(Map details,List courses,List pins)=>[for(final e in details.entries)'${e.key}: ${e.value}','Courses: ${courses.join(', ')}','Pinned tools: ${pins.join(', ')}'].join('\n');
  final choice=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Choose which workspace to keep'),content:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('THIS DEVICE',style:TextStyle(fontWeight:FontWeight.w800)),Text(describe(workspace.details,workspace.courses,workspace.pins.toList())),const SizedBox(height:16),
   const Text('YOUR ACCOUNT',style:TextStyle(fontWeight:FontWeight.w800)),Text(describe(remote['details'] as Map? ?? {},remote['courses'] as List? ?? [],remote['pins'] as List? ?? [])),
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Decide later')),TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Use account copy')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Keep device copy'))]));
  if(choice==null)return;
  if(!identical(remote,workspace.conflict)){if(context.mounted)nuMessage(context,'Your account copy changed. Review it again.');return;}
  try{await workspace.resolveConflict(choice);}catch(e){if(context.mounted)nuMessage(context,e);}
 }
}

