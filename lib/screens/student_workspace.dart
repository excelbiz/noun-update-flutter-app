import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/academic_period.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';

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
    details=Map<String,String>.from(remote['details'] as Map? ?? const {});
    courses=List<String>.from(remote['courses'] as List? ?? const []);
    pins=Set<String>.from(remote['pins'] as List? ?? const []);
    revision=(remote['revision'] as num?)?.toInt()??0;
    dirty=false;
  }

  Future<Map<String,dynamic>> _remote()async=>unpack(await api.getJson('/workspace'));

  Future<void> _push({int? baseRevision})async{
    _ensureCurrentPeriod();
    final response=unpack(await api.postJson('/workspace',{
      'details':details,
      'courses':courses,
      'pins':pins.toList(),
      'base_revision':baseRevision??revision,
    }));
    _applyRemote(response);
    await _persist();
  }

  Future<void> _syncLoaded({Map<String,dynamic>? bootstrapRemote}) async {
    if(!canSync||syncing)return;
    syncing=true;
    try{
      final remote=bootstrapRemote??await _remote();
      final exists=remote['exists']==true;
      final remoteRevision=(remote['revision'] as num?)?.toInt()??0;
      if(dirty || (!exists && (details.isNotEmpty||courses.isNotEmpty||pins.isNotEmpty))){
        try{
          await _push(baseRevision:remoteRevision);
        }on ApiException catch(e){
          if(e.code!='WORKSPACE_CONFLICT')rethrow;
          final newest=await _remote();
          await _push(baseRevision:(newest['revision'] as num?)?.toInt()??0);
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
    try {
      final raw=(await SharedPreferences.getInstance()).getString(key);
      if(raw!=null){
        final d=jsonDecode(raw) as Map;
        details=Map<String,String>.from(d['details'] as Map? ?? const {});
        courses=List<String>.from(d['courses'] as List? ?? const []);
        pins=Set<String>.from(d['pins'] as List? ?? const []);
        revision=(d['revision'] as num?)?.toInt()??0;
        dirty=d['dirty']==true;
      }
    } catch (_) { details={};courses=[];pins={};revision=0;dirty=false; }
    if(!canSync&&_ensureCurrentPeriod())await _persist();
    notifyListeners();
    await _syncLoaded(bootstrapRemote:bootstrapRemote);
  }

  Future<void> save() async {
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
          final newest=await _remote();
          await _push(baseRevision:(newest['revision'] as num?)?.toInt()??0);
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
  @override void initState(){super.initState();for(final k in ['Name','Programme','Faculty','Level','Study centre']){fields[k]=TextEditingController(text:widget.workspace.details[k]??'');}}
  @override void dispose(){for(final c in fields.values){c.dispose();}super.dispose();}
  @override Widget build(BuildContext context){
    final period=widget.workspace.period;
    return NuPage(title:'Student details',child:ListView(padding:const EdgeInsets.all(20),children:[
      const NuTitle('Make this your dashboard',subtitle:'Add what you know. You can complete optional details later.'),
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
 final code=TextEditingController();String? error;bool saving=false;
 @override void dispose(){code.dispose();super.dispose();}
 Future<void> update(List<String> next) async {if(saving)return;setState(()=>saving=true);final old=List<String>.from(widget.workspace.courses);widget.workspace.courses=next;try{await widget.workspace.save();code.clear();if(mounted)setState(()=>error=null);}catch(_){widget.workspace.courses=old;if(mounted)setState(()=>error='Could not save your courses. Try again.');}finally{if(mounted)setState(()=>saving=false);}}
 void hub(String course)=>pushNu(context,NuPage(title:course,child:ListView(padding:const EdgeInsets.all(20),children:[
  NuTitle('$course Course Hub',subtitle:'Your resources, together.'),
  const NuPanel(child:Text('Exam date and assessment classification have not been verified. A non-examinable course is not automatically a PAS course.')),
  for(final item in [('courses','Course Material'),('course-summary','Course Summary'),('exam-summary','Exam Summary'),('past-questions','Past Questions'),('mock','Mock Examination'),('study-hub','Study Hub')])NuPanel(padding:0,child:ListTile(title:Text(item.$2),subtitle:Text('Open the library and search $course'),leading:const Icon(Icons.menu_book_outlined),trailing:const Icon(Icons.chevron_right),onTap:()=>widget.openResource(item.$1,item.$2))),
 ])));
 @override Widget build(BuildContext context)=>NuPage(title:'My Courses',child:ListenableBuilder(listenable:widget.workspace,builder:(context,_)=>ListView(padding:const EdgeInsets.all(20),children:[
  const NuTitle('Your semester starts here',subtitle:'Keep your registered courses in one place.'),
  Text(widget.workspace.canSync?'Your courses work offline and synchronise with your account across devices.${widget.workspace.syncPending?' Changes are waiting to sync.':''}':'This course list is saved on this device. Sign in to synchronise it across devices.'),const SizedBox(height:16),
  TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:InputDecoration(labelText:'Course code',hintText:'For example, CIT411',errorText:error)),const SizedBox(height:10),
  FilledButton.icon(onPressed:saving?null:(){final c=code.text.replaceAll(' ','').toUpperCase();if(!RegExp(r'^[A-Z]{2,5}[0-9]{3}$').hasMatch(c)){setState(()=>error='Enter a course code such as CIT411.');return;}if(widget.workspace.courses.contains(c)){setState(()=>error='This course is already saved.');return;}update([...widget.workspace.courses,c]);},icon:const Icon(Icons.add),label:const Text('Add course')),
  const SizedBox(height:20),if(widget.workspace.courses.isEmpty)const NuPanel(child:Text('No courses added yet. Add your first registered course above.')),
  for(final c in widget.workspace.courses)NuPanel(padding:0,child:ListTile(title:Text(c),subtitle:const Text('Open Course Hub'),onTap:()=>hub(c),leading:const Icon(Icons.school_outlined),trailing:IconButton(tooltip:'Remove $c',onPressed:saving?null:() async {final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text('Remove $c?'),content:const Text('This removes it from your saved course list on synchronised devices too.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Remove'))]));if(yes==true)await update(widget.workspace.courses.where((v)=>v!=c).toList());},icon:const Icon(Icons.close)))),
 ])));
}