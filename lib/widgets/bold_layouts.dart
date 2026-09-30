import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/premium_service.dart';
import '../core/skin_theme.dart';
import '../core/study_state_store.dart';
import 'editorial_layouts.dart' show EditorialCrown, editorialMoney;
import 'native_ui.dart';

const boldGreen = Color(0xff007046);
const boldPurple = Color(0xff5926a5);
const boldBlue = Color(0xff1769c5);
const boldRed = Color(0xffbc2932);
const boldGold = Color(0xffdcaa17);

TextStyle boldText(BuildContext context, {double size = 13, Color? color,
    FontWeight weight = FontWeight.w400}) => TextStyle(fontFamily: 'NUSans',
    fontSize: size, height: 1.22, color: color ?? SkinTokens.of(context).ink,
    fontWeight: weight);

Color boldToolTone(String id) => switch (id) {
  'course-summary' || 'pas-status' => boldPurple,
  'exam-summary' || 'mock' => boldBlue,
  'past-questions' || 'personalized-timetable' => boldRed,
  'courses' => boldGold,
  'result' => const Color(0xffec8a16),
  _ => boldGreen,
};

IconData boldToolIcon(String id) => switch (id) {
  'fees' => Icons.account_balance_wallet_outlined,
  'pas-status' || 'course-summary' => Icons.description_outlined,
  'personalized-timetable' => Icons.calendar_month_outlined,
  'mock' || 'exam-summary' => Icons.fact_check_outlined,
  'past-questions' => Icons.help_outline_rounded,
  'courses' => Icons.folder_open_rounded,
  'study-hub' => Icons.groups_outlined,
  'result' => Icons.person_search_outlined,
  'cgpa-calculator' => Icons.calculate_outlined,
  _ => serviceIcon(id),
};

class BoldPanel extends StatelessWidget {
  const BoldPanel({super.key, required this.child, this.onTap,
    this.padding = const EdgeInsets.all(13)});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  @override Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
      boxShadow: [BoxShadow(color: t.ink.withValues(alpha: .045), blurRadius: 12,
        offset: const Offset(0, 3))]), child: Material(color: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: t.ink.withValues(alpha: .065))),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13),
        child: Padding(padding: padding, child: child))));
  }
}

class BoldGlyph extends StatelessWidget {
  const BoldGlyph(this.icon, {super.key, this.tone = boldGreen, this.size = 43});
  final IconData icon;
  final Color tone;
  final double size;
  @override Widget build(BuildContext context) => Container(width: size, height: size,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .24),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color.lerp(tone, Colors.white, .22)!, tone, Color.lerp(tone, Colors.black, .17)!]),
      border: Border.all(color: Colors.white.withValues(alpha: .30)),
      boxShadow: [BoxShadow(color: tone.withValues(alpha: .13), blurRadius: 7,
        offset: const Offset(0, 3))]),
    child: Icon(icon, size: size * .62, color: Colors.white));
}

class BoldHeading extends StatelessWidget {
  const BoldHeading(this.title, {super.key, this.onAll, this.action = 'See All'});
  final String title, action;
  final VoidCallback? onAll;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 9), child: Row(children: [
      Expanded(child: Text(title, style: boldText(context, size: 16, weight: FontWeight.w700))),
      if (onAll != null) InkWell(onTap: onAll, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Text(action, style: boldText(context, size: 11, color: SkinTokens.of(context).primary)))),
    ]));
}

class BoldTopBar extends StatelessWidget implements PreferredSizeWidget {
  const BoldTopBar({super.key, required this.page, required this.name,
    required this.onNotifications, required this.onSettings, this.textScale = 1});
  final int page;
  final String name;
  final double textScale;
  final VoidCallback onNotifications, onSettings;
  @override Size get preferredSize => Size.fromHeight(70 + math.max(0, textScale - 1) * 70);
  @override Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    final heading = switch (page) {1 => 'Study', 2 => 'Tools & Wallet', 3 => 'Updates', 5 => 'Wallet', _ => 'Profile'};
    final subtitle = switch (page) {1 => 'Learn · Prepare · Excel', 2 => 'More tools. A smoother NOUN experience.', 3 => 'Stay informed. Stay ahead.', 5 => 'One account. One balance.', _ => 'Your student life, organised.'};
    return AppBar(backgroundColor: t.background, foregroundColor: t.ink,
      elevation: 0, scrolledUnderElevation: 0, toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: page == 0 ? Row(children: [
        const BoldGlyph(Icons.person_rounded, size: 40), const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${DateTime.now().hour < 12 ? 'Good morning' : DateTime.now().hour < 18 ? 'Good afternoon' : 'Good evening'},',
            style: boldText(context, size: 11, color: t.ink.withValues(alpha: .65))),
          Text('${name.isEmpty ? 'NOUN Student' : name}! 👋', maxLines: 2,
            overflow: TextOverflow.ellipsis, style: boldText(context, size: 17, weight: FontWeight.w800)),
          const SizedBox(height: 3), Text('Discipline today. Brighter tomorrow.', maxLines: 1,
            overflow: TextOverflow.ellipsis, style: boldText(context, size: 9, color: t.ink.withValues(alpha: .60))),
        ])),
      ]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: boldText(context, size: 25, weight: FontWeight.w800)),
        const SizedBox(height: 4), Text(subtitle, maxLines: 2,
          style: boldText(context, size: 11, color: t.ink.withValues(alpha: .68))),
      ]),
      actions: [if (page == 0 || page == 3) IconButton(tooltip: 'Notifications',
        onPressed: onNotifications, icon: const Icon(Icons.notifications_none_rounded, size: 22)),
        if (page == 4 || page == 5) IconButton(tooltip: 'Appearance & settings',
          onPressed: onSettings, icon: const Icon(Icons.settings_outlined, size: 22))]);
  }
}

class BoldUpdateBanner extends StatefulWidget {
  const BoldUpdateBanner({super.key, required this.feed, required this.onOpen});
  final Future<Map<String, dynamic>> feed;
  final void Function(Map<String, dynamic>) onOpen;
  @override State<BoldUpdateBanner> createState() => _BoldUpdateBannerState();
}
class _BoldUpdateBannerState extends State<BoldUpdateBanner> {
  final controller = PageController();
  bool dismissed = false;
  int page = 0;
  @override void didUpdateWidget(covariant BoldUpdateBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed != widget.feed) {dismissed = false; page = 0; if (controller.hasClients) controller.jumpToPage(0);}
  }
  @override void dispose() {controller.dispose(); super.dispose();}
  @override Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: widget.feed, builder: (context, snapshot) {
      final rows = records(snapshot.data?['items']).take(5).toList();
      if (dismissed || rows.isEmpty) return const SizedBox.shrink();
      final dark = Theme.of(context).brightness == Brightness.dark;
      final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
      return Column(children: [Container(height: 118 + math.max(0, scale - 1) * 140,
        decoration: BoxDecoration(color: dark ? const Color(0xff301b20) : const Color(0xfffff6f6),
          borderRadius: BorderRadius.circular(13), border: Border.all(color: boldRed.withValues(alpha: .14))),
        child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Stack(children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: boldRed)),
          PageView.builder(controller: controller, itemCount: rows.length,
            onPageChanged: (value) => setState(() => page = value), itemBuilder: (context, i) => InkWell(
              onTap: () => widget.onOpen(rows[i]), child: Padding(padding: const EdgeInsets.fromLTRB(12, 13, 30, 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.campaign_rounded, color: boldRed, size: 36), const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('IMPORTANT UPDATE', style: boldText(context, size: 10,
                      color: dark ? const Color(0xffffa4a8) : boldRed, weight: FontWeight.w800)),
                    const SizedBox(height: 5), Text('${rows[i]['title']}', maxLines: 3,
                      overflow: TextOverflow.ellipsis, style: boldText(context, size: 13, weight: FontWeight.w700)),
                    const Spacer(), Text('Tap to view details →', style: boldText(context, size: 10)),
                  ])),
                ])))),
          Positioned(top: 0, right: 0, child: IconButton(tooltip: 'Dismiss update',
            onPressed: () => setState(() => dismissed = true), icon: Icon(Icons.close,
              size: 16, color: SkinTokens.of(context).ink.withValues(alpha: .45)))),
        ]))),
        if (rows.length > 1) Padding(padding: const EdgeInsets.only(top: 9), child: Row(
          mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < rows.length; i++)
            Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: i == page ? boldGreen : SkinTokens.of(context).ink.withValues(alpha: .18)))])),
        const SizedBox(height: 13),
      ]);
    });
}

class BoldLatestUpdate extends StatelessWidget {
  const BoldLatestUpdate({super.key, required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => BoldPanel(onTap: onTap, child: Row(children: [
    const BoldGlyph(Icons.description_outlined, tone: Color(0xff167f8c), size: 42),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Latest Update', style: boldText(context, size: 12, weight: FontWeight.w700)),
      const SizedBox(height: 4), Text('${item['title']}', maxLines: 2, overflow: TextOverflow.ellipsis,
        style: boldText(context, size: 12)), const SizedBox(height: 4),
      Text('Read the published notice', style: boldText(context, size: 10,
        color: SkinTokens.of(context).ink.withValues(alpha: .62))),
    ])), const Icon(Icons.chevron_right, size: 20),
  ]));
}

class BoldHomeLayout extends StatelessWidget {
  const BoldHomeLayout({super.key, required this.balance, required this.nextExamSummary,
    required this.services, required this.onOpen, required this.onWallet, required this.onTopUp,
    required this.onExam, required this.onCourses, required this.onTools, required this.continueCourse,
    required this.importantUpdate, required this.latestUpdate, required this.birthday,
    required this.workspaceStatus, required this.motivation, this.nextExam, this.setup});
  final String balance, nextExamSummary;
  final Map<String, dynamic>? nextExam;
  final List<Map<String, dynamic>> services;
  final void Function(Map<String, dynamic>) onOpen;
  final VoidCallback onWallet, onTopUp, onExam, onCourses, onTools;
  final Widget continueCourse, importantUpdate, latestUpdate, birthday, workspaceStatus, motivation;
  final Widget? setup;
  Widget _balance(BuildContext c) => BoldPanel(onTap: onWallet, child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [
      const Icon(Icons.account_balance_wallet_rounded, size: 19, color: boldGreen), const SizedBox(width: 6),
      Expanded(child: Text('Wallet Balance', style: boldText(c, size: 11, color: SkinTokens.of(c).primary, weight: FontWeight.w600))),
    ]), const SizedBox(height: 12), Text(balance, style: boldText(c, size: 22, weight: FontWeight.w800)),
    const Spacer(), InkWell(onTap: onTopUp, child: Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('${balance == '—' ? 'Sign in' : 'Top Up Wallet'} →', style: boldText(c,
        size: 11, color: SkinTokens.of(c).primary, weight: FontWeight.w700)))),
  ]));
  Widget _exam(BuildContext c) {
    final date = DateTime.tryParse('${nextExam?['exam_datetime']}');
    final remaining = date?.difference(DateTime.now());
    final days = remaining == null || remaining.isNegative ? null : (remaining.inSeconds / 86400).ceil();
    return BoldPanel(onTap: onExam, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xff1684a9)),
        const SizedBox(width: 6), Expanded(child: Text('Next Exam', style: boldText(c, size: 11, weight: FontWeight.w700)))]),
      const SizedBox(height: 10), if (nextExam == null) Expanded(child: Text(nextExamSummary,
        maxLines: 5, overflow: TextOverflow.ellipsis, style: boldText(c, size: 11))) else ...[
        Text('${nextExam!['course_code']}', style: boldText(c, size: 18, weight: FontWeight.w800)),
        const SizedBox(height: 4), Text('${nextExam!['date']}', style: boldText(c, size: 10)),
        const Spacer(), if (days != null) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: boldGreen, borderRadius: BorderRadius.circular(20)),
          child: Text('$days ${days == 1 ? 'day' : 'days'} left', style: boldText(c, size: 11, color: Colors.white))),
      ],
    ]));
  }
  @override Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final extent = 146 + math.max(0, scale - 1) * 100;
    return ListView(key: const PageStorageKey('home'), padding: const EdgeInsets.fromLTRB(16, 9, 16, 24), children: [
      workspaceStatus, birthday, importantUpdate,
      if (scale > 1.3) ...[SizedBox(height: extent, child: _balance(context)), const SizedBox(height: 10),
        SizedBox(height: extent, child: _exam(context))]
      else SizedBox(height: extent, child: Row(children: [Expanded(child: _balance(context)),
        const SizedBox(width: 11), Expanded(child: _exam(context))])),
      BoldHeading('Continue Studying', onAll: onCourses, action: 'View All'), continueCourse,
      BoldHeading('Quick Tools', onAll: onTools), BoldQuickTools(services: services, onOpen: onOpen),
      const SizedBox(height: 17), latestUpdate, const SizedBox(height: 15), motivation,
      if (setup != null) setup!,
    ]);
  }
}

class BoldQuickTools extends StatelessWidget {
  const BoldQuickTools({super.key, required this.services, required this.onOpen});
  final List<Map<String, dynamic>> services;
  final void Function(Map<String, dynamic>) onOpen;
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final large = MediaQuery.textScalerOf(context).scale(12) > 16;
    final items = services.take(4).toList();
    Widget cell(int i) {
      final s = items[i], id = '${s['id']}';
      final label = switch (id) {'mock' => 'Mock e-Exam', _ => serviceLabel(id, '${s['label']}')};
      return InkWell(onTap: () => onOpen(s), borderRadius: BorderRadius.circular(12), child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2), child: Column(children: [
          BoldGlyph(boldToolIcon(id), tone: boldToolTone(id), size: 48), const SizedBox(height: 8),
          Text(label, maxLines: 3, textAlign: TextAlign.center, style: boldText(context, size: 10, weight: FontWeight.w600)),
        ])));
    }
    if (large) return Wrap(spacing: 9, runSpacing: 12, children: [for (var i = 0; i < items.length; i++)
      SizedBox(width: (box.maxWidth - 9) / 2, child: cell(i))]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < items.length; i++)
      Expanded(child: cell(i))]);
  });
}

class BoldContinueCourse extends StatefulWidget {
  const BoldContinueCourse({super.key, required this.api, required this.onTap,
    this.courseCode, this.userId, this.preview = false});
  final ApiClient api;
  final String? courseCode, userId;
  final bool preview;
  final VoidCallback onTap;
  @override State<BoldContinueCourse> createState() => _BoldContinueCourseState();
}
class _BoldContinueCourseState extends State<BoldContinueCourse> {
  String? title;
  double? progress;
  @override void initState() {super.initState(); load();}
  @override void didUpdateWidget(covariant BoldContinueCourse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseCode != widget.courseCode || oldWidget.userId != widget.userId) {
      title = null; progress = null; load();
    }
  }
  Future<void> load() async {
    final code = widget.courseCode, userId = widget.userId;
    if (code == null) return;
    try {
      final state = StudyStateStore(api: widget.api, courseCode: code, userId: userId);
      if (widget.preview) {
        final sample = unpack(await widget.api.getJson('/study/$code/state'));
        state.done = (sample['done'] as List? ?? []).whereType<num>().map((n) => n.toInt()).toSet();
      } else {await state.load();}
      final data = unpack(await widget.api.getJson('/study/$code'));
      final indices = records(data['sections']).map((s) => s['index']).whereType<num>().map((n) => n.toInt()).toSet();
      if (mounted && widget.courseCode == code && widget.userId == userId) setState(() {
        title = data['course_title']?.toString();
        progress = indices.isEmpty ? null : state.done.intersection(indices).length / indices.length;
      });
    } catch (_) {/* Retain the course link if progress cannot be verified. */}
  }
  @override Widget build(BuildContext context) => BoldPanel(onTap: widget.onTap, child: Row(children: [
    const BoldGlyph(Icons.play_circle_fill_rounded, tone: Color(0xff217aa5), size: 47), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.courseCode ?? 'Choose your next course', style: boldText(context, size: 15, weight: FontWeight.w700)),
      const SizedBox(height: 4), Text(title ?? 'Open your registered course resources', maxLines: 2,
        overflow: TextOverflow.ellipsis, style: boldText(context, size: 11)),
      if (progress != null) ...[const SizedBox(height: 8), Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
          value: progress, minHeight: 6, color: boldGreen, backgroundColor: boldGreen.withValues(alpha: .13)))),
        const SizedBox(width: 6), Text('${(progress! * 100).round()}% complete', style: boldText(context, size: 9)),
      ])],
    ])), const SizedBox(width: 6), const Icon(Icons.chevron_right, size: 20),
  ]));
}

class BoldStudyLayout extends StatelessWidget {
  const BoldStudyLayout({super.key, required this.services, required this.onOpen,
    required this.onCourses, required this.onSearch, required this.onSaved,
    required this.onDownloads, required this.onFocus, required this.motivation});
  final List<Map<String, dynamic>> services;
  final void Function(Map<String, dynamic>) onOpen;
  final VoidCallback onCourses, onSearch, onSaved, onDownloads, onFocus;
  final Widget motivation;
  @override Widget build(BuildContext context) {
    const ids = ['my-courses', 'course-summary', 'exam-summary', 'past-questions', 'courses', 'study-hub'];
    final cells = <({String id, String title, String caption, IconData icon, Color tone, VoidCallback tap})>[];
    for (final id in ids) {
      if (id == 'my-courses') {cells.add((id: id, title: 'My Courses', caption: 'View all your registered courses',
        icon: Icons.menu_book_outlined, tone: boldGreen, tap: onCourses)); continue;}
      final matches = services.where((s) => s['id'] == id);
      if (matches.isEmpty) continue;
      final s = matches.first;
      cells.add((id: id, title: serviceLabel(id, '${s['label']}'), caption: switch (id) {
        'course-summary' => 'Concise notes for faster revision',
        'exam-summary' => 'Key points, exam questions & tips',
        'past-questions' => 'Practise with past questions & answers',
        'courses' => 'Access PDFs, videos & resources',
        _ => 'Study tips, guides and discussions',
      }, icon: boldToolIcon(id), tone: boldToolTone(id), tap: () => onOpen(s)));
    }
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final large = scale > 1.3;
    final tileHeight = (MediaQuery.sizeOf(context).width < 350 ? 170.0 : 156.0) + math.max(0, scale - 1) * 100;
    return ListView(key: const PageStorageKey('study'), padding: const EdgeInsets.fromLTRB(16, 5, 16, 24), children: [
      BoldPanel(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), onTap: onSearch,
        child: Row(children: [Expanded(child: Text('Search for courses, materials, topics…',
          style: boldText(context, size: 11, color: SkinTokens.of(context).ink.withValues(alpha: .62)))),
          const SizedBox(width: 6), const Icon(Icons.search, size: 20)])),
      const SizedBox(height: 13), GridView.builder(shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), itemCount: cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: large ? 1 : 2,
          mainAxisExtent: tileHeight, crossAxisSpacing: 11, mainAxisSpacing: 11),
        itemBuilder: (context, i) {final cell = cells[i]; return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color.lerp(cell.tone, Colors.white, .08)!, cell.tone, Color.lerp(cell.tone, Colors.black, .22)!]),
            border: Border.all(color: Colors.white.withValues(alpha: .20)),
            boxShadow: [BoxShadow(color: cell.tone.withValues(alpha: .14), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Material(color: Colors.transparent, child: InkWell(onTap: cell.tap,
            borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(15),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(cell.icon, size: 35, color: const Color(0xffeef8e9)), const SizedBox(height: 13),
                Text(cell.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: boldText(context, size: 15, color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 5), Expanded(child: Text(cell.caption, maxLines: 3,
                  overflow: TextOverflow.ellipsis, style: boldText(context, size: 10, color: Colors.white))),
                const Icon(Icons.arrow_forward, size: 17, color: Colors.white),
              ])))));}),
      const SizedBox(height: 18), motivation,
      const BoldHeading('Your library'), BoldPanel(padding: EdgeInsets.zero, child: Column(children: [
        ListTile(leading: const Icon(Icons.bookmark_border), title: const Text('Saved resources'), onTap: onSaved),
        ListTile(leading: const Icon(Icons.download_outlined), title: const Text('Downloads'), onTap: onDownloads),
        ListTile(leading: const Icon(Icons.timer_outlined), title: const Text('Focus timer'), onTap: onFocus),
      ])),
      for (final s in services.where((s) => !ids.contains(s['id']))) Padding(padding: const EdgeInsets.only(top: 10),
        child: BoldPanel(onTap: () => onOpen(s), child: Row(children: [
          BoldGlyph(boldToolIcon('${s['id']}'), tone: boldToolTone('${s['id']}'), size: 34), const SizedBox(width: 10),
          Expanded(child: Text(serviceLabel('${s['id']}', '${s['label']}'), style: boldText(context, weight: FontWeight.w600))),
          const Icon(Icons.chevron_right, size: 20),
        ]))),
    ]);
  }
}

class BoldBalanceStrip extends StatelessWidget {
  const BoldBalanceStrip({super.key, required this.balance, required this.onTopUp, this.signedIn = false});
  final String balance;
  final bool signedIn;
  final VoidCallback onTopUp;
  @override Widget build(BuildContext context) {
    final wideText = MediaQuery.textScalerOf(context).scale(12) > 16;
    final info = Row(children:[
      const BoldGlyph(Icons.account_balance_wallet_outlined, tone: Color(0xff086661), size: 44),
      const SizedBox(width:11), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Wallet Balance',style:boldText(context,size:10)),const SizedBox(height:4),
        Text(balance,style:boldText(context,size:20,weight:FontWeight.w800)),
      ])),
    ]);
    final button = FilledButton(style:FilledButton.styleFrom(backgroundColor:const Color(0xff005331),foregroundColor:Colors.white,
      minimumSize:const Size(0,38),padding:const EdgeInsets.symmetric(horizontal:13),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),
      onPressed:onTopUp,child:Text(signedIn?'Top Up':'Sign in',style:const TextStyle(fontFamily:'NUSans',fontSize:12)));
    return BoldPanel(child:wideText?Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[info,const SizedBox(height:10),Align(alignment:Alignment.centerRight,child:button)])
      :Row(children:[Expanded(child:info),const SizedBox(width:8),button]));
  }
}

class BoldMembershipBanner extends StatelessWidget {
  const BoldMembershipBanner({super.key, required this.onOpen});
  final VoidCallback onOpen;
  @override Widget build(BuildContext context) => ListenableBuilder(listenable: PremiumService.instance,
    builder: (context, _) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
      gradient: const LinearGradient(colors: [Color(0xff171109), Color(0xff573c07), Color(0xffbd8517)]),
      border: Border.all(color: boldGold.withValues(alpha: .32))), child: Material(color: Colors.transparent,
        child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(13), child: Padding(
          padding: const EdgeInsets.all(13), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const EditorialCrown(), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NOUN Update Premium', style: boldText(context, size: 13, color: const Color(0xffffdc76), weight: FontWeight.w700)),
              const SizedBox(height: 6), Text('Unlock more features, extra insights\nand a better learning experience.',
                style: boldText(context, size: 10, color: const Color(0xfff7eed8))),
            ])), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xffffd464), borderRadius: BorderRadius.circular(16)),
              child: Text(PremiumService.instance.isPremium ? 'Active' : 'Explore',
                style: boldText(context, size: 10, color: const Color(0xff302508), weight: FontWeight.w700))),
          ]))))));
}

class BoldTransactions extends StatelessWidget {
  const BoldTransactions({super.key, required this.rows, required this.onAll, this.limit});
  final List<Map<String, dynamic>> rows;
  final VoidCallback onAll;
  final int? limit;
  @override Widget build(BuildContext context) {
    final selected = limit == null ? rows : rows.take(limit!).toList();
    return Column(children: [BoldHeading('Recent Transactions', onAll: onAll),
      BoldPanel(padding: const EdgeInsets.all(11), child: Column(children: [
        if (selected.isEmpty) Align(alignment: Alignment.centerLeft, child: Text('No wallet transactions yet.', style: boldText(context))),
        for (var i = 0; i < selected.length; i++) ...[
          if (i > 0) Divider(height: 17, color: SkinTokens.of(context).ink.withValues(alpha: .08)),
          Builder(builder: (context) {
            final row = selected[i], amount = num.tryParse('${selected[i]['amount_kobo']}') ?? 0;
            final tone = amount >= 0 ? boldGreen : '${row['title']}'.toLowerCase().contains('mock') ? boldBlue : boldPurple;
            final date = DateTime.tryParse('${row['created_at']}');
            final dateText = date == null ? '${row['created_at'] ?? ''}' : '${date.day} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month - 1]} ${date.year}';
            return Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(
              color: tone.withValues(alpha: .10), shape: BoxShape.circle),
              child: Icon(amount >= 0 ? Icons.account_balance_wallet_rounded : Icons.shopping_bag_outlined, size: 19, color: tone)),
              const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${row['title']}', style: boldText(context, size: 11, weight: FontWeight.w700)),
                const SizedBox(height: 3), Text(dateText, style: boldText(context, size: 9, color: SkinTokens.of(context).ink.withValues(alpha: .62))),
                if (row['status'] != null && row['status'] != 'posted') Text('${row['status']}', style: boldText(context, size: 9)),
              ])), const SizedBox(width: 7), Text('${amount > 0 ? '+' : ''}${editorialMoney(amount)}',
                style: boldText(context, size: 11, color: amount >= 0 ? SkinTokens.of(context).primary : const Color(0xffd8484c), weight: FontWeight.w700)),
            ]);
          }),
        ],
      ])),
    ]);
  }
}

class BoldToolsLayout extends StatefulWidget {
  const BoldToolsLayout({super.key, required this.services, required this.balance, required this.signedIn,
    required this.transactions, required this.onOpen, required this.onTopUp, required this.onPremium,
    required this.onHistory, required this.onUpdates, required this.search, required this.onSearch,
    required this.pinned, required this.onTogglePin});
  final List<Map<String, dynamic>> services, transactions;
  final String balance, search;
  final bool signedIn;
  final Set<String> pinned;
  final ValueChanged<String> onSearch;
  final void Function(Map<String, dynamic>) onOpen, onTogglePin;
  final VoidCallback onTopUp, onPremium, onHistory, onUpdates;
  @override State<BoldToolsLayout> createState() => _BoldToolsLayoutState();
}
class _BoldToolsLayoutState extends State<BoldToolsLayout> {
  final searchKey = GlobalKey();
  List<Map<String,dynamic>> get services => widget.services;
  List<Map<String,dynamic>> get transactions => widget.transactions;
  String get balance => widget.balance;
  bool get signedIn => widget.signedIn;
  Set<String> get pinned => widget.pinned;
  ValueChanged<String> get onSearch => widget.onSearch;
  void Function(Map<String,dynamic>) get onOpen => widget.onOpen;
  void Function(Map<String,dynamic>) get onTogglePin => widget.onTogglePin;
  VoidCallback get onTopUp => widget.onTopUp;
  VoidCallback get onPremium => widget.onPremium;
  VoidCallback get onHistory => widget.onHistory;
  VoidCallback get onUpdates => widget.onUpdates;
  @override Widget build(BuildContext context) {
    const ids = ['fees', 'pas-status', 'personalized-timetable', 'mock', 'result', 'cgpa-calculator'];
    final essential = [for (final id in ids) ...services.where((s) => s['id'] == id).take(1)];
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final rest = services.where((s) => !ids.contains(s['id'])).toList();
    return SingleChildScrollView(key: const PageStorageKey('tools'), padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BoldBalanceStrip(balance: balance, signedIn: signedIn, onTopUp: onTopUp), const SizedBox(height: 13),
      BoldMembershipBanner(onOpen: onPremium), BoldHeading('Essential Tools', onAll: () {
        Scrollable.ensureVisible(searchKey.currentContext!, alignment: .1);
      }),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: essential.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: scale > 1.3 ? 1 : 2,
          mainAxisExtent: (MediaQuery.sizeOf(context).width < 350 ? 129.0 : 120.0) + math.max(0, scale - 1) * 90,
          crossAxisSpacing: 10, mainAxisSpacing: 10), itemBuilder: (context, i) {
          final s = essential[i], id = '${s['id']}';
          final label = id == 'mock' ? 'Mock e-Exam' : serviceLabel(id, '${s['label']}');
          final caption = switch (id) {'fees' => 'Check school fees and payment info',
            'pas-status' => 'Check your assessment status', 'personalized-timetable' => 'Create and manage your study schedule',
            'mock' => 'Practise with real exam experience', 'result' => 'Check your results instantly', _ => 'Calculate your CGPA easily'};
          return BoldPanel(padding: const EdgeInsets.all(11), onTap: () => onOpen(s), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [BoldGlyph(boldToolIcon(id), tone: boldToolTone(id), size: 32),
              const SizedBox(height: 7), Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: boldText(context, size: 12, weight: FontWeight.w700)), const SizedBox(height: 3),
              Expanded(child: Text(caption, maxLines: 3, overflow: TextOverflow.ellipsis, style: boldText(context, size: 10))),
            ]));
        }),
      BoldTransactions(rows: transactions, onAll: onHistory, limit: 3),
      BoldHeading('Latest updates', onAll: onUpdates), BoldPanel(onTap: onUpdates,
        child: Row(children: [const Icon(Icons.newspaper_outlined, color: boldGreen), const SizedBox(width: 10),
          Expanded(child: Text('News, guides and scholarships', style: boldText(context))), const Icon(Icons.chevron_right)])),
      const BoldHeading('All tools'), TextField(key: searchKey, onChanged: onSearch,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Find a tool')),
      if (services.isEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Text('No tools match your search.', style: boldText(context))),
      for (final s in [...services.where((s) => pinned.contains('${s['id']}')), ...rest.where((s) => !pinned.contains('${s['id']}'))])
        Padding(padding: const EdgeInsets.only(top: 10), child: BoldPanel(padding: EdgeInsets.zero,
          child: ListTile(leading: BoldGlyph(boldToolIcon('${s['id']}'), tone: boldToolTone('${s['id']}'), size: 34),
            title: Text(serviceLabel('${s['id']}', '${s['label']}'), style: boldText(context, weight: FontWeight.w600)),
            onTap: () => onOpen(s), trailing: IconButton(tooltip: pinned.contains('${s['id']}') ? 'Unpin tool' : 'Pin tool',
              onPressed: () => onTogglePin(s), icon: Icon(pinned.contains('${s['id']}') ? Icons.push_pin : Icons.push_pin_outlined, size: 19))))),
    ]));
  }
}

class BoldWelcome extends StatelessWidget {
  const BoldWelcome({super.key, required this.onLogin, required this.onRegister, required this.onGuest});
  final VoidCallback onLogin, onRegister, onGuest;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: SkinTokens.of(context).background,
    body: LayoutBuilder(builder: (context, box) {
      final t = SkinTokens.of(context), scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final height = math.max(box.maxHeight, 820 + math.max(0, scale - 1) * 520);
      return SingleChildScrollView(child: SizedBox(height: height, child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: height * .50, child: ExcludeSemantics(child:
          Image.asset('assets/images/skins/bold-premium-welcome.webp', fit: BoxFit.cover, alignment: Alignment.topCenter))),
        Positioned(top: height * .045, left: 0, right: 0, child: Center(child: Image.asset(
          'assets/images/skins/editorial-emblem.webp', width: height >= 950 ? 240 : 215,
          height: height >= 950 ? 240 : 215, semanticLabel: 'NOUN Update Educational Consultant'))),
        Positioned(top: height * .395, left: 0, right: 0, height: height * .13,
          child: IgnorePointer(child: CustomPaint(painter: _BoldWelcomeWave(t.background)))),
        Positioned(top: height * .515, left: 28, right: 28, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Learn Anytime', textAlign: TextAlign.center, style: boldText(context, size: 29, weight: FontWeight.w800)),
          Text('Go Further', textAlign: TextAlign.center, style: boldText(context, size: 29, color: t.primary, weight: FontWeight.w800)),
          const SizedBox(height: 9), Text('Your complete NOUN student\nsupport app.', textAlign: TextAlign.center, style: boldText(context, size: 14)),
          const SizedBox(height: 27), SizedBox(height: 49 + math.max(0, scale - 1) * 25,
            child: FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xff005532), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onLogin,
              child: Row(children: [const SizedBox(width: 20), Expanded(child: Text('Sign In', textAlign: TextAlign.center,
                style: boldText(context, size: 14, color: Colors.white, weight: FontWeight.w700))), const Icon(Icons.arrow_forward, size: 20)]))),
          const SizedBox(height: 11), SizedBox(height: 49 + math.max(0, scale - 1) * 25,
            child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: t.primary.withValues(alpha: .60)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onRegister,
              child: Text('Create Account', style: boldText(context, size: 14, weight: FontWeight.w600)))),
          const SizedBox(height: 15), Row(children: [Expanded(child: Divider(color: t.ink.withValues(alpha: .20))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: boldText(context, size: 11))),
            Expanded(child: Divider(color: t.ink.withValues(alpha: .20)))]),
          TextButton.icon(onPressed: onGuest, icon: const Icon(Icons.person_outline, size: 19),
            label: Text('Continue as guest', style: boldText(context, size: 13, color: t.primary))),
          const SizedBox(height: 12), Text('Excellence In Your Academics', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'NUReading', fontSize: 22, fontStyle: FontStyle.italic, color: t.primary)),
          const SizedBox(height: 6), const SizedBox(height: 8, child: CustomPaint(painter: _BoldMottoStroke())),
        ])),
        Positioned(top: MediaQuery.paddingOf(context).top + 8, left: 8, child: IconButton(
          tooltip: 'Back', onPressed: onGuest, icon: const Icon(Icons.arrow_back, color: Colors.white))),
      ])));
    }));
}

class _BoldWelcomeWave extends CustomPainter {
  const _BoldWelcomeWave(this.surface);
  final Color surface;
  @override void paint(Canvas canvas, Size s) {
    final edge = Path()..moveTo(0, s.height * .18)
      ..cubicTo(s.width * .15, s.height * 1.08, s.width * .42, s.height * .90, s.width * .61, s.height * .30)
      ..cubicTo(s.width * .75, -s.height * .14, s.width * .92, s.height * .16, s.width, s.height * .50);
    final fill = Path.from(edge)..lineTo(s.width, s.height)..lineTo(0, s.height)..close();
    canvas.drawPath(fill, Paint()..color = surface);
    canvas.drawPath(edge, Paint()..style = PaintingStyle.stroke..strokeWidth = 16
      ..color = const Color(0xffffd253).withValues(alpha: .42)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawPath(edge, Paint()..style = PaintingStyle.stroke..strokeWidth = 7
      ..shader = const LinearGradient(colors: [Color(0xffa97612), Color(0xffffedb3), Color(0xffe6b82e), Color(0xffffe383)])
        .createShader(Offset.zero & s));
    canvas.drawPath(edge, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xfffff2c8));
  }
  @override bool shouldRepaint(covariant _BoldWelcomeWave oldDelegate) => surface != oldDelegate.surface;
}

class _BoldMottoStroke extends CustomPainter {
  const _BoldMottoStroke();
  @override void paint(Canvas canvas, Size s) => canvas.drawPath(Path()..moveTo(s.width * .04, s.height)
    ..quadraticBezierTo(s.width * .48, -s.height * .15, s.width * .96, s.height * .50),
    Paint()..color = boldRed..strokeWidth = 1.6..style = PaintingStyle.stroke);
  @override bool shouldRepaint(covariant _BoldMottoStroke oldDelegate) => false;
}
