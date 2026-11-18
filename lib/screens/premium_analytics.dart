import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api_client.dart';
import '../core/premium_service.dart';
import '../widgets/native_ui.dart';
import 'premium_report.dart';

class PremiumAnalyticsPage extends StatefulWidget {
  const PremiumAnalyticsPage({super.key, required this.api});
  final ApiClient api;
  @override State<PremiumAnalyticsPage> createState() => _PremiumAnalyticsPageState();
}

class _PremiumAnalyticsPageState extends State<PremiumAnalyticsPage> {
  late Future<List<Map<String, dynamic>>> data;
  bool exporting=false;
  @override void initState() { super.initState(); data = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final premium = PremiumService.instance;
    if (!premium.isPremium) throw const _AnalyticsAccessException('Active NOUN Update Premium is required for advanced analytics. Your Mock and POP practice tools remain free.');
    final results = <Map<String, dynamic>>[];
    if (premium.allows('mock_analytics')) results.add(unpack(await widget.api.getJson('/premium/analytics/mock')));
    if (premium.allows('pop_analytics')) results.add(unpack(await widget.api.getJson('/premium/analytics/pop')));
    if (results.isEmpty) throw const _AnalyticsAccessException('Premium analytics is not enabled on your account yet.');
    return results;
  }
  void _retry() => setState(() => data = _load());
  Future<void> _export(List<Map<String,dynamic>> datasets)async{
    if(!PremiumService.instance.allows('reports')){nuMessage(context,'Downloadable reports are not enabled for this Premium account.');return;}
    if(exporting)return;setState(()=>exporting=true);
    try{
      final bytes=await PremiumAnalyticsReport.build(datasets);
      if(!mounted)return;
      final box=context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(ShareParams(
        files:[XFile.fromData(bytes,mimeType:'application/pdf')],
        fileNameOverrides:['noun-update-premium-analytics.pdf'],
        text:'NOUN Update Premium Analytics report',
        sharePositionOrigin:box.localToGlobal(Offset.zero)&box.size,
      ));
    }catch(_){if(mounted)nuMessage(context,'The analytics PDF could not be prepared. Please try again.');}
    finally{if(mounted)setState(()=>exporting=false);}
  }
  @override Widget build(BuildContext context) => NuPage(
    title:'Premium Analytics',
    child:FutureBuilder<List<Map<String,dynamic>>>(future:data,builder:(context,snapshot){
      if(snapshot.hasError){final error=snapshot.error;final message=error is _AnalyticsAccessException?error.message:error is ApiException?error.message:'Your analytics could not be loaded right now.';return ListView(padding:const EdgeInsets.all(20),children:[const ServiceHero(title:'Know where you stand',subtitle:'Real performance insights from your completed NOUN Update practice attempts.',icon:Icons.insights_outlined),const SizedBox(height:16),AsyncError(message,_retry)]);}
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.all(20),children:[
        const ServiceHero(title:'Know where you stand',subtitle:'Advanced analytics uses your real completed practice attempts. It never invents scores or changes your results.',icon:Icons.insights_outlined),
        const SizedBox(height:14),
        if(PremiumService.instance.allows('reports'))FilledButton.icon(onPressed:exporting?null:()=>_export(snapshot.data!),icon:const Icon(Icons.picture_as_pdf_outlined),label:Text(exporting?'Preparing PDF…':'Download / Share PDF Report')),
        if(PremiumService.instance.allows('reports'))const Padding(padding:EdgeInsets.only(top:8,bottom:8),child:Text('The report is generated on your device from the same analytics shown below.')),
        const SizedBox(height:10),for(final result in snapshot.data!)_AnalyticsSection(data:result),
        const NuPanel(child:Text('Analytics is an extra Premium layer only. Mock e-Exam and POP Exam Practice remain available under their normal free-access rules.')),
      ]);
    }),
  );
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({required this.data}); final Map<String,dynamic> data;
  String get source=>'${data['source']}'; bool get isMock=>source=='mock'; String get title=>isMock?'Mock e-Exam Analytics':'POP Exam Practice Analytics';
  String _pct(dynamic value)=>value is num?'${value.toStringAsFixed(value%1==0?0:1)}%':'—';
  String _time(dynamic value){if(value is! num||value<=0)return '—';final seconds=value.round();final hours=seconds~/3600;final minutes=(seconds%3600)~/60;if(hours>0)return '${hours}h ${minutes}m';if(minutes>0)return '${minutes}m';return '${seconds}s';}
  @override Widget build(BuildContext context){
    if(data['source_available']!=true)return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),const Text('This analytics source is not connected on the server yet. Your practice tool itself is unaffected.')]));
    if(data['account_linked']==false)return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),const Text('No matching practice account was found for your central-account email. Use the same email across NOUN Update services, or contact support to link the accounts.')]));
    if(data['has_data']!=true)return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),const Text('Complete at least one practice attempt and your analytics will appear here.')]));
    final summary=Map<String,dynamic>.from(data['summary'] as Map? ?? const {});final courses=records(data['courses']);final trend=records(data['trend']);final difficulty=records(data['difficulty']);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(title,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:12),
      Wrap(spacing:10,runSpacing:10,children:[_Metric(label:'Attempts',value:'${summary['attempts']??0}'),_Metric(label:'Average',value:_pct(summary['average_percentage'])),_Metric(label:'Best',value:_pct(summary['best_percentage'])),if(isMock)_Metric(label:'Practice time',value:_time(summary['total_time_seconds'])),if(isMock)_Metric(label:'Avg. pace',value:summary['seconds_per_question'] is num?'${summary['seconds_per_question']}s/q':'—'),if(!isMock)_Metric(label:'Answer coverage',value:_pct(summary['answer_coverage_percentage']))]),
      if(trend.isNotEmpty)...[const SizedBox(height:18),const NuTitle('Recent performance'),NuPanel(child:_TrendBars(points:trend))],
      if(difficulty.isNotEmpty)...[const NuTitle('Performance by difficulty'),for(final d in difficulty)_ProgressRow(label:'${d['difficulty']}'.toUpperCase(),value:(d['average_percentage'] as num?)?.toDouble()??0,note:'${d['attempts']??0} attempt${d['attempts']==1?'':'s'} · best ${_pct(d['best_percentage'])}')],
      if(courses.isNotEmpty)...[const NuTitle('Courses to focus on'),const Text('Lowest average performance is shown first so you can prioritise revision.'),const SizedBox(height:8),for(final c in courses.take(8))_ProgressRow(label:'${c['course_code']}',value:(c['average_percentage'] as num?)?.toDouble()??0,note:'${c['attempts']??0} attempt${c['attempts']==1?'':'s'} · best ${_pct(c['best_percentage'])}${isMock&&c['average_time_seconds'] is num?' · avg ${_time(c['average_time_seconds'])}':''}')],
      const SizedBox(height:20),
    ]);
  }
}
class _Metric extends StatelessWidget{const _Metric({required this.label,required this.value});final String label,value;@override Widget build(BuildContext context)=>Container(width:145,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerLow,borderRadius:BorderRadius.circular(16),border:Border.all(color:Theme.of(context).dividerColor.withValues(alpha:.6))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(label,style:Theme.of(context).textTheme.bodySmall)]));}
class _ProgressRow extends StatelessWidget{const _ProgressRow({required this.label,required this.value,required this.note});final String label,note;final double value;@override Widget build(BuildContext context){final safe=value.clamp(0,100).toDouble();return NuPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w800))),Text('${safe.toStringAsFixed(safe%1==0?0:1)}%')]),const SizedBox(height:8),LinearProgressIndicator(value:safe/100,minHeight:8,borderRadius:BorderRadius.circular(99)),const SizedBox(height:8),Text(note,style:Theme.of(context).textTheme.bodySmall)]));}}
class _TrendBars extends StatelessWidget{const _TrendBars({required this.points});final List<Map<String,dynamic>> points;@override Widget build(BuildContext context){final visible=points.length>10?points.sublist(points.length-10):points;return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(height:118,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[for(final p in visible)Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:2),child:Tooltip(message:'${p['course_code']} · ${(p['percentage'] as num?)?.toStringAsFixed(1)??'0'}%',child:FractionallySizedBox(heightFactor:((((p['percentage'] as num?)?.toDouble()??0).clamp(4,100))/100).toDouble(),alignment:Alignment.bottomCenter,child:DecoratedBox(decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(6)))))))])),const SizedBox(height:8),Text('Older → newer',style:Theme.of(context).textTheme.bodySmall)]);}}
class _AnalyticsAccessException implements Exception{const _AnalyticsAccessException(this.message);final String message;}
