import 'package:flutter/material.dart';

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
  });

  final String currentPeriod;
  final String? sourcePeriod;
  final bool periodMismatch;
  final List<TimetableEntry> items;
  final List<String> missingCourses;
  final TimetableEntry? nextExam;

  static Future<TimetableSnapshot> fetch(ApiClient api,List<String> courses)async{
    if(courses.isEmpty)return const TimetableSnapshot(currentPeriod:'',sourcePeriod:null,periodMismatch:false,items:[],missingCourses:[],nextExam:null);
    final query=Uri.encodeQueryComponent(courses.join(','));
    final response=await api.getJson('/timetable?courses=$query');
    final data=unpack(response);
    final items=records(data['items']).map(TimetableEntry.fromJson).toList(growable:false);
    final rawNext=data['next_exam'];
    return TimetableSnapshot(
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
  const NativeTimetable({super.key,required this.api,required this.courses,required this.onManageCourses});
  final ApiClient api;
  final List<String> courses;
  final VoidCallback onManageCourses;
  @override State<NativeTimetable> createState()=>_NativeTimetableState();
}

class _NativeTimetableState extends State<NativeTimetable>{
  late Future<TimetableSnapshot> future;
  @override void initState(){super.initState();future=TimetableSnapshot.fetch(widget.api,widget.courses);}
  void reload()=>setState(()=>future=TimetableSnapshot.fetch(widget.api,widget.courses));
  Color _tone(String type)=>switch(type){'POP'=>const Color(0xff2466a8),'Practical'=>const Color(0xffb77b16),_=>const Color(0xff137044)};

  @override Widget build(BuildContext context)=>NuPage(title:'Personalised Timetable',child:widget.courses.isEmpty
    ?ListView(padding:const EdgeInsets.all(20),children:[
      const ServiceHero(title:'Your exam schedule, simplified.',subtitle:'Add your registered courses and NOUN Update will match them against the currently imported timetable.',icon:Icons.calendar_month_rounded),
      const SizedBox(height:18),const NuPanel(child:Text('No registered courses are saved yet. Add My Courses first; the timetable will update automatically from the same synced course list.')),
      FilledButton.icon(onPressed:widget.onManageCourses,icon:const Icon(Icons.add),label:const Text('Add My Courses')),
    ])
    :FutureBuilder<TimetableSnapshot>(future:future,builder:(context,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:AsyncError('Your timetable could not be loaded. Please retry.',reload)));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final t=s.data!;
      return RefreshIndicator(onRefresh:()async{reload();await future;},child:ListView(padding:const EdgeInsets.fromLTRB(18,18,18,30),children:[
        ServiceHero(title:'${t.currentPeriod.isEmpty?'Current':t.currentPeriod} Exam Timetable',subtitle:'Matched directly from the timetable records currently imported into NOUN Update.',icon:Icons.event_available_rounded),
        if(t.periodMismatch)const Padding(padding:EdgeInsets.only(top:12),child:NuPanel(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.warning_amber_rounded),SizedBox(width:10),Expanded(child:Text('The imported timetable appears to belong to a different academic period. Recheck this schedule before relying on it; NOUN Update will not relabel older records as the current semester.'))]))),
        const SizedBox(height:18),
        const NuTitle('Next examination'),
        if(t.nextExam==null)NuPanel(child:Text(t.nextExamSummary)) else _examCard(t.nextExam!,featured:true),
        const NuTitle('Your matched schedule'),
        if(t.items.isEmpty)const NuPanel(child:Text('None of your registered courses has a timetable record yet. This can happen before the timetable import is complete.')),
        for(final exam in t.items)_examCard(exam),
        if(t.missingCourses.isNotEmpty)...[
          const NuTitle('Courses not found'),
          NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('These saved courses are not in the currently imported timetable:'),const SizedBox(height:10),Wrap(spacing:7,runSpacing:7,children:[for(final code in t.missingCourses)Chip(label:Text(code))]),const SizedBox(height:8),const Text('Keep them in My Courses. They will appear here automatically when matching timetable records are imported.',style:TextStyle(fontSize:12))])),
        ],
        const SizedBox(height:12),OutlinedButton.icon(onPressed:widget.onManageCourses,icon:const Icon(Icons.school_outlined),label:const Text('Manage My Courses')),
      ]));
    }));

  Widget _examCard(TimetableEntry exam,{bool featured=false}){
    final tone=_tone(exam.examType);
    final fill=featured?Color.lerp(Theme.of(context).colorScheme.surface,tone,.10)!:Theme.of(context).colorScheme.surface;
    return Padding(padding:const EdgeInsets.only(bottom:10),child:NuPanel(color:fill,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[GlossIcon(Icons.event_note_rounded,color:tone,size:featured?48:42),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(exam.courseCode,style:TextStyle(fontSize:featured?20:17,fontWeight:FontWeight.w900)),Text(exam.courseTitle,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))])),Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:tone.withValues(alpha:.12),borderRadius:BorderRadius.circular(999)),child:Text(exam.examType,style:TextStyle(color:tone,fontSize:10,fontWeight:FontWeight.w900)))]),
      const SizedBox(height:12),Wrap(spacing:14,runSpacing:8,children:[_detail(Icons.calendar_today_outlined,exam.date),_detail(Icons.schedule_outlined,exam.time),if(exam.day.isNotEmpty)_detail(Icons.today_outlined,exam.day)]),
      if(exam.isPast)const Padding(padding:EdgeInsets.only(top:8),child:Text('Completed / past date',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700))),
    ])));
  }
  Widget _detail(IconData icon,String text)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15),const SizedBox(width:5),Text(text,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))]);
}
