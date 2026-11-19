import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../widgets/native_ui.dart';

class TimetableEntry {
  const TimetableEntry({
    required this.courseCode,
    required this.courseTitle,
    required this.day,
    required this.date,
    required this.time,
    required this.examType,
    required this.examDateTime,
    required this.isPast,
  });

  final String courseCode;
  final String courseTitle;
  final String day;
  final String date;
  final String time;
  final String examType;
  final DateTime? examDateTime;
  final bool isPast;

  factory TimetableEntry.fromJson(Map<String,dynamic> row)=>TimetableEntry(
    courseCode:'${row['course_code']??''}',
    courseTitle:'${row['course_title']??''}',
    day:'${row['day']??''}',
    date:'${row['date']??''}',
    time:'${row['time']??''}',
    examType:'${row['exam_type']??''}',
    examDateTime:DateTime.tryParse('${row['exam_datetime']??''}'),
    isPast:row['is_past']==true,
  );
}

class TimetableSnapshot {
  const TimetableSnapshot({
    required this.currentPeriod,
    required this.sourcePeriod,
    required this.periodMismatch,
    required this.items,
    required this.missingCourses,
    required this.nextExam,
    this.facultyOptions=const [],this.facultyId,this.batch,this.batchUnresolved=const [],
  });

  final String currentPeriod;
  final String? sourcePeriod;
  final bool periodMismatch;
  final List<TimetableEntry> items;
  final List<String> missingCourses;
  final TimetableEntry? nextExam;
  final List<Map<String,dynamic>> facultyOptions;
  final String? facultyId,batch;
  final List<String> batchUnresolved;

  Map<String,dynamic> toJson()=> {
    'current_period':currentPeriod,'source_period':sourcePeriod,'period_mismatch':periodMismatch,
    'items':items.map((item)=>{'course_code':item.courseCode,'course_title':item.courseTitle,'day':item.day,
      'date':item.date,'time':item.time,'exam_type':item.examType,
      'exam_datetime':item.examDateTime?.toIso8601String(),'is_past':item.isPast}).toList(),
    'missing_courses':missingCourses,'faculty_options':facultyOptions,'faculty_id':facultyId,
    'exam_batch':batch,'batch_unresolved_courses':batchUnresolved,
  };

  static Future<TimetableSnapshot> fetch(ApiClient api,List<String> courses,{String? faculty})async{
    if(courses.isEmpty)return const TimetableSnapshot(currentPeriod:'',sourcePeriod:null,periodMismatch:false,items:[],missingCourses:[],nextExam:null);
    final query=Uri(queryParameters:{'courses':courses.join(','),if(faculty!=null&&faculty.trim().isNotEmpty)'faculty':faculty}).query;
    final response=await api.getJson('/timetable?$query');
    return fromJson(unpack(response));
  }

  static TimetableSnapshot fromJson(Map<String,dynamic> data){
    final items=records(data['items']).map(TimetableEntry.fromJson).toList(growable:false);
    final rawNext=data['next_exam'];
    return TimetableSnapshot(
      facultyOptions:records(data['faculty_options']),
      facultyId:data['faculty_id'] as String?,batch:data['exam_batch'] as String?,
      batchUnresolved:(data['batch_unresolved_courses'] as List? ?? const []).map((value)=>'$value').toList(),
      currentPeriod:'${data['current_period']??''}',
      sourcePeriod:data['source_period']==null?null:'${data['source_period']}',
      periodMismatch:data['period_mismatch']==true,
      items:items,
      missingCourses:(data['missing_courses'] as List? ?? const []).map((v)=>'$v').toList(growable:false),
      nextExam:rawNext is Map?TimetableEntry.fromJson(Map<String,dynamic>.from(rawNext)):null,
    );
  }

  String get nextExamSummary {
    final exam=nextExam;
    if(exam==null){
      if(items.isEmpty)return 'No verified timetable record is available for your registered courses yet.';
      return 'No upcoming exam remains in the currently imported timetable.';
    }
    return '${exam.courseCode} · ${exam.date} · ${exam.time}';
  }
}

class NativeTimetable extends StatefulWidget {
  const NativeTimetable({super.key,required this.api,required this.courses,required this.onManageCourses,this.scope='guest',this.faculty});
  final ApiClient api;
  final List<String> courses;
  final VoidCallback onManageCourses;
  final String scope;
  final String? faculty;
  @override State<NativeTimetable> createState()=>_NativeTimetableState();
}

class _NativeTimetableState extends State<NativeTimetable>{
  late Future<(TimetableSnapshot,DateTime?)> future;
  bool saving=false;
  late String? faculty=widget.faculty;
  String get _cacheKey=>'nu-timetable-v1-${widget.scope}';
  String get _courseKey=>([...widget.courses]..sort()).join(',');
  @override void initState(){super.initState();future=_initialise();}
  Future<(TimetableSnapshot,DateTime?)> _initialise()async{
    try{
      final saved=(await SharedPreferences.getInstance()).getString(_cacheKey);
      if(saved!=null){
        final stored=jsonDecode(saved) as Map;
        if(stored['courses']==_courseKey&&stored['profile_faculty']==widget.faculty&&stored['faculty'] is String){
          faculty=stored['faculty'] as String;
        }
      }
    }catch(_){/* Corrupt cache must not prevent the live timetable. */}
    return _fetch();
  }
  void reload()=>setState(()=>future=_fetch());
  Future<(TimetableSnapshot,DateTime?)> _fetch()async{
    try{return (await TimetableSnapshot.fetch(widget.api,widget.courses,faculty:faculty),null);}
    catch(_){
      final raw=(await SharedPreferences.getInstance()).getString(_cacheKey);
      if(raw==null)rethrow;
      final cache=jsonDecode(raw) as Map;
      final saved=DateTime.tryParse('${cache['saved_at']}');
      if(saved==null||cache['courses']!=_courseKey||cache['faculty']!=faculty)rethrow;
      return (TimetableSnapshot.fromJson(Map<String,dynamic>.from(cache['data'] as Map)),saved);
    }
  }
  Future<void> _save(TimetableSnapshot timetable)async{
    if(saving||timetable.periodMismatch)return;
    setState(()=>saving=true);
    try{
      final ok=await (await SharedPreferences.getInstance()).setString(_cacheKey,jsonEncode({
        'courses':_courseKey,'faculty':faculty,'profile_faculty':widget.faculty,'saved_at':DateTime.now().toIso8601String(),'data':timetable.toJson(),
      }));
      if(!ok)throw StateError('Save failed');
      if(mounted)nuMessage(context,'Timetable saved on this device.');
    }catch(_){if(mounted)nuMessage(context,'The timetable could not be saved.');}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Color _tone(String type)=>switch(type){'POP'=>const Color(0xff2466a8),'Practical'=>const Color(0xffb77b16),_=>const Color(0xff137044)};

  @override Widget build(BuildContext context)=>NuPage(title:'Personalised Timetable',child:widget.courses.isEmpty
    ?ListView(padding:const EdgeInsets.all(20),children:[
      const ServiceHero(title:'Your exam schedule, simplified.',subtitle:'Add your registered courses and NOUN Update will match them against the currently imported timetable.',icon:Icons.calendar_month_rounded),
      const SizedBox(height:18),const NuPanel(child:Text('No registered courses are saved yet. Add My Courses first; the timetable will update automatically from the same synced course list.')),
      FilledButton.icon(onPressed:widget.onManageCourses,icon:const Icon(Icons.add),label:const Text('Add My Courses')),
    ])
    :FutureBuilder<(TimetableSnapshot,DateTime?)>(future:future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:AsyncError('Your timetable could not be loaded. Please retry.',reload)));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final (t,savedAt)=s.data!;
      return RefreshIndicator(onRefresh:()async{reload();try{await future;}catch(_){/* The builder shows the retry state. */}},child:ListView(padding:const EdgeInsets.fromLTRB(18,18,18,30),children:[
        ServiceHero(title:'${t.currentPeriod.isEmpty?'Current':t.currentPeriod} Exam Timetable',subtitle:savedAt==null?'Matched from the timetable records currently imported into NOUN Update.':'Saved timetable · offline copy',icon:Icons.event_available_rounded),
        if(t.facultyOptions.isNotEmpty&&savedAt==null)NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          DropdownButtonFormField<String>(key:ValueKey(t.facultyId),initialValue:t.facultyId,isExpanded:true,
            decoration:const InputDecoration(labelText:'Faculty'),
            items:[for(final option in t.facultyOptions)DropdownMenuItem(value:option['id'] as String,
              child:Text('${option['label']}',overflow:TextOverflow.ellipsis))],
            onChanged:(value){faculty=value;reload();}),
          const SizedBox(height:8),
          Text(t.batch==null?'Choose your faculty to include batch-specific exams.':'Batch ${t.batch} · ${t.currentPeriod} general-course sittings'),
        ])),
        if(t.batchUnresolved.isNotEmpty)NuPanel(child:Text(
          'A verified batch is required for ${t.batchUnresolved.join(', ')}. Select your faculty or confirm with your study centre.')),
        if(t.periodMismatch)const Padding(padding:EdgeInsets.only(top:12),child:NuPanel(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.warning_amber_rounded),SizedBox(width:10),Expanded(child:Text('The imported timetable appears to belong to a different academic period. Recheck this schedule before relying on it; NOUN Update will not relabel older records as the current semester.'))]))),
        const SizedBox(height:18),
        if(savedAt!=null)NuPanel(child:Text('Saved ${MaterialLocalizations.of(context).formatMediumDate(savedAt)}. Reconnect to check for changes before relying on this timetable.'))
        else ...[
          const NuTitle('Next examination'),
          if(t.nextExam==null)NuPanel(child:Text(t.nextExamSummary)) else _examCard(t.nextExam!,featured:true),
        ],
        const NuTitle('Your matched schedule'),
        if(t.items.isEmpty)const NuPanel(child:Text('None of your registered courses has a timetable record yet. This can happen before the timetable import is complete.')),
        for(final exam in t.items)_examCard(exam,showStatus:savedAt==null),
        if(t.missingCourses.isNotEmpty)...[
          const NuTitle('Courses not found'),
          NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('These saved courses are not in the currently imported timetable:'),const SizedBox(height:10),Wrap(spacing:7,runSpacing:7,children:[for(final code in t.missingCourses)Chip(label:Text(code))]),const SizedBox(height:8),const Text('Keep them in My Courses. They will appear here automatically when matching timetable records are imported.',style:TextStyle(fontSize:12))])),
        ],
        if(savedAt==null&&!t.periodMismatch&&t.items.isNotEmpty)
          FilledButton.icon(onPressed:saving?null:()=>_save(t),icon:const Icon(Icons.download_outlined),label:const Text('Save timetable offline')),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:widget.onManageCourses,icon:const Icon(Icons.school_outlined),label:const Text('Manage My Courses')),
      ]));
    }));

  Widget _examCard(TimetableEntry exam,{bool featured=false,bool showStatus=true}){
    final tone=_tone(exam.examType);
    final fill=featured?Color.lerp(Theme.of(context).colorScheme.surface,tone,.10)!:Theme.of(context).colorScheme.surface;
    return Padding(padding:const EdgeInsets.only(bottom:10),child:NuPanel(color:fill,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[GlossIcon(Icons.event_note_rounded,color:tone,size:featured?48:42),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(exam.courseCode,style:TextStyle(fontSize:featured?20:17,fontWeight:FontWeight.w900)),Text(exam.courseTitle,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))])),Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:tone.withValues(alpha:.12),borderRadius:BorderRadius.circular(999)),child:Text(exam.examType,style:TextStyle(color:tone,fontSize:10,fontWeight:FontWeight.w900)))]),
      const SizedBox(height:12),Wrap(spacing:14,runSpacing:8,children:[_detail(Icons.calendar_today_outlined,exam.date),_detail(Icons.schedule_outlined,exam.time),if(exam.day.isNotEmpty)_detail(Icons.today_outlined,exam.day)]),
      if(showStatus&&exam.isPast)const Padding(padding:EdgeInsets.only(top:8),child:Text('Completed / past date',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700))),
    ])));
  }
  Widget _detail(IconData icon,String text)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15),const SizedBox(width:5),Text(text,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))]);
}

