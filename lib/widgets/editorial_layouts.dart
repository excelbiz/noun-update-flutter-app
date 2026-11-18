import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/premium_service.dart';
import '../core/skin_theme.dart';
import '../core/study_state_store.dart';
import '../screens/profile_cosmetics.dart';
import 'native_ui.dart';

const editorialGreen = Color(0xff005037);
const editorialRed = Color(0xffa01724);
const editorialGold = Color(0xffc79b40);

String editorialMoney(dynamic kobo) {
  final amount = (num.tryParse('$kobo') ?? 0) / 100;
  final parts = amount.abs().toStringAsFixed(2).split('.');
  final digits = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${amount < 0 ? '−' : ''}₦$digits.${parts[1]}';
}

TextStyle editorialText(BuildContext context, {double size = 13, Color? color, FontWeight weight = FontWeight.w400}) => TextStyle(fontFamily: 'NUSans', fontSize: size, height: 1.25, color: color ?? SkinTokens.of(context).ink, fontWeight: weight);

class EditorialLogo extends StatelessWidget {
  const EditorialLogo({super.key, this.size = 46});
  final double size;
  @override Widget build(BuildContext context) => Image.asset('assets/images/skins/editorial-emblem.webp', width: size, height: size, fit: BoxFit.contain, semanticLabel: 'NOUN Update Educational Consultant');
}

class EditorialCrown extends StatelessWidget {
  const EditorialCrown({super.key});
  @override Widget build(BuildContext context) => Semantics(label: 'Premium', child: const SizedBox(width: 31, height: 31, child: CustomPaint(painter: _CrownPainter())));
}
class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xfff2db92), Color(0xffc29639)]).createShader(Offset.zero & size);
    final path = Path()..moveTo(size.width * .12, size.height * .72)..lineTo(size.width * .06, size.height * .3)..lineTo(size.width * .31, size.height * .47)..lineTo(size.width * .5, size.height * .15)..lineTo(size.width * .69, size.height * .47)..lineTo(size.width * .94, size.height * .3)..lineTo(size.width * .88, size.height * .72)..close();
    canvas.drawPath(path, paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .13, size.height * .8, size.width * .74, size.height * .08), const Radius.circular(1.5)), paint);
    for (final point in [Offset(size.width * .06, size.height * .24), Offset(size.width * .5, size.height * .09), Offset(size.width * .94, size.height * .24)]) {canvas.drawCircle(point, size.width * .055, paint);}
  }
  @override bool shouldRepaint(covariant _CrownPainter oldDelegate) => false;
}

class EditorialTopBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorialTopBar({super.key, required this.page, required this.greeting, required this.onNotifications, required this.onSettings, this.textScale = 1});
  final double textScale;
  final int page;
  final String greeting;
  final VoidCallback onNotifications, onSettings;
  @override Size get preferredSize => Size.fromHeight(page == 0 ? 100 + (textScale - 1).clamp(0, 3) * 90 : 64 + (textScale - 1).clamp(0, 3) * 30);
  @override Widget build(BuildContext context) => AppBar(
    toolbarHeight: preferredSize.height,
    backgroundColor: const Color(0xff003c29), foregroundColor: Colors.white,
    elevation: 0, scrolledUnderElevation: 0, titleSpacing: 18,
    title: page == 4 ? Text('Wallet & Profile', style: editorialText(context, size: 20, color: Colors.white, weight: FontWeight.w700)) : Row(children: [
      EditorialLogo(size: page == 0 ? 54 : 46), const SizedBox(width: 12),
      Expanded(child: page == 0 ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back,', style: editorialText(context, size: 12, color: const Color(0xffe6efdf))),
        const SizedBox(height: 3), Text(greeting, maxLines: 2, overflow: TextOverflow.ellipsis, style: editorialText(context, size: 18, color: Colors.white, weight: FontWeight.w700)),
        const SizedBox(height: 6), Text('Stay consistent. Success is a process.', maxLines: 1, overflow: TextOverflow.ellipsis, style: editorialText(context, size: 10, color: const Color(0xffe6efdf))),
      ]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('NOUN UPDATE', style: TextStyle(fontFamily: 'NUReading', fontSize: 21, color: Colors.white, fontWeight: FontWeight.w600)),
        Text('Excellence in your academics', style: editorialText(context, size: 9, color: const Color(0xffefe4c0))),
      ])),
    ]),
    actions: [IconButton(tooltip: page == 4 ? 'Appearance & settings' : 'Notifications', onPressed: page == 4 ? onSettings : onNotifications, icon: Icon(page == 4 ? Icons.settings_outlined : Icons.notifications_none_rounded, size: 22)), const SizedBox(width: 6)],
  );
}

class EditorialPanel extends StatelessWidget {
  const EditorialPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), boxShadow: [BoxShadow(color: const Color(0xff51401e).withValues(alpha: .035), blurRadius: 12, offset: const Offset(0, 3))]), child: Material(
      color: t.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: BorderSide(color: t.gold.withValues(alpha: .15))),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Padding(padding: padding, child: child)),
    ));
  }
}

class EditorialSearch extends StatelessWidget {
  const EditorialSearch({super.key, required this.onTap, this.label = 'Search courses, topics, or materials…'});
  final VoidCallback onTap;
  final String label;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: EditorialPanel(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), onTap: onTap, child: Row(children: [Icon(Icons.search, size: 21, color: SkinTokens.of(context).ink), const SizedBox(width: 9), Expanded(child: Text(label, style: editorialText(context, size: 12, color: SkinTokens.of(context).ink.withValues(alpha: .65))))])));
}

class EditorialHeading extends StatelessWidget {
  const EditorialHeading(this.title, {super.key, this.action, this.actionLabel = 'See All'});
  final String title, actionLabel;
  final VoidCallback? action;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 9), child: Row(children: [Expanded(child: Text(title, style: editorialText(context, size: 17, weight: FontWeight.w700))), if (action != null) InkWell(onTap: action, child: Padding(padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4), child: Text(actionLabel, style: editorialText(context, size: 11, color: SkinTokens.of(context).primary))))]));
}

class EditorialExamCard extends StatelessWidget {
  const EditorialExamCard({super.key, required this.summary, required this.onTap, this.exam, this.centre});
  final String summary;
  final Map<String, dynamic>? exam;
  final String? centre;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) {
    final date = DateTime.tryParse('${exam?['exam_datetime'] ?? ''}');
    final remaining = date == null ? null : date.difference(DateTime.now());
    final days = remaining == null || remaining.isNegative ? null : (remaining.inSeconds / 86400).ceil();
    Widget detail(IconData icon, String value) => Padding(padding: const EdgeInsets.only(top: 5), child: Row(children: [Icon(icon, color: Colors.white.withValues(alpha: .85), size: 13), const SizedBox(width: 6), Expanded(child: Text(value, style: editorialText(context, size: 11, color: Colors.white)))]));
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xffab1726), Color(0xff7d0d17)]), boxShadow: [BoxShadow(color: editorialRed.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 4))]), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.calendar_month_outlined, size: 19, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text('Next Exam', style: editorialText(context, size: 17, color: Colors.white, weight: FontWeight.w700))), Text('View All', style: editorialText(context, size: 10, color: Colors.white))]), const SizedBox(height: 12),
      if (exam == null) Text(summary, style: editorialText(context, size: 13, color: Colors.white)) else Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${exam!['course_code']}', style: editorialText(context, size: 20, color: Colors.white, weight: FontWeight.w700)), const SizedBox(height: 3), Text('${exam!['course_title']}', style: editorialText(context, size: 12, color: Colors.white)),
        detail(Icons.calendar_today_outlined, '${exam!['date']}'), detail(Icons.schedule_outlined, '${exam!['time']}'), if (centre?.isNotEmpty == true) detail(Icons.location_on_outlined, centre!),
        // Retain the verified summary for screen readers and existing callers.
        Semantics(label: summary, child: const SizedBox.shrink()),
      ])), if (days != null) ...[const SizedBox(width: 12), Container(width: 70, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withValues(alpha: .25))), child: Column(children: [Text('$days', style: editorialText(context, size: 27, color: Colors.white)), Text('Days Left', style: editorialText(context, size: 10, color: Colors.white))]))]],
      ),
    ])))));
  }
}

class EditorialQuickTools extends StatelessWidget {
  const EditorialQuickTools({super.key, required this.services, required this.onOpen});
  final List<Map<String, dynamic>> services;
  final void Function(Map<String, dynamic>) onOpen;
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final wideText = MediaQuery.textScalerOf(context).scale(12) > 16;
    final items = services.take(4).toList();
    Widget tile(int i) {
      final s = items[i], id = '${s['id']}';
      final tone = switch(id) {'past-questions' => editorialGreen, 'courses' => editorialRed, 'personalized-timetable' => editorialGold, _ => editorialGreen};
      final label = switch(id) {'courses' => 'Study Materials', 'personalized-timetable' => 'Exam Timetable', 'result' => 'Results Checker', _ => serviceLabel(id, '${s['label']}')};
      return EditorialPanel(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5), onTap: () => onOpen(s), child: Column(children: [Container(width: 38, height: 38, decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.lerp(tone, Colors.white, .1)!, tone]), borderRadius: BorderRadius.circular(10)), child: Icon(serviceIcon(id), size: 21, color: Colors.white)), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, maxLines: 3, style: editorialText(context, size: 10))]));
    }
    if (wideText) return Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < items.length; i++) SizedBox(width: (constraints.maxWidth - 8) / 2, child: tile(i))]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 7), Expanded(child: tile(i))]]);
  });
}

class EditorialContinueCourse extends StatefulWidget {
  const EditorialContinueCourse({super.key, required this.api, required this.onTap, this.courseCode, this.userId, this.preview = false});
  final bool preview;
  final ApiClient api;
  final String? courseCode, userId;
  final VoidCallback onTap;
  @override State<EditorialContinueCourse> createState() => _EditorialContinueCourseState();
}
class _EditorialContinueCourseState extends State<EditorialContinueCourse> {
  int? done, total;
  String? title;
  @override void initState() {super.initState(); load();}
  @override void didUpdateWidget(covariant EditorialContinueCourse oldWidget) {super.didUpdateWidget(oldWidget); if (oldWidget.courseCode != widget.courseCode || oldWidget.userId != widget.userId) {done = null; total = null; title = null; load();}}
  Future<void> load() async {
    final code = widget.courseCode, userId = widget.userId;
    if (code == null) return;
    try {
      final state = StudyStateStore(api: widget.api, courseCode: code, userId: userId);
      if (widget.preview) {
        final sample = unpack(await widget.api.getJson('/study/$code/state'));
        state.done = (sample['done'] as List? ?? []).whereType<num>().map((n) => n.toInt()).toSet();
      } else {
        await state.load();
      }
      final data = unpack(await widget.api.getJson('/study/$code'));
      final sections = records(data['sections']);
      final indices = sections.map((s) => s['index']).whereType<num>().map((n) => n.toInt()).toSet();
      if (mounted && widget.courseCode == code && widget.userId == userId) setState(() {total = indices.length; done = state.done.intersection(indices).length; title = data['course_title']?.toString();});
    } catch (_) {/* Keep the course link usable when progress cannot be verified. */}
  }
  @override Widget build(BuildContext context) => EditorialPanel(onTap: widget.onTap, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 45, height: 48, decoration: BoxDecoration(color: editorialGreen, borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.menu_book_outlined, size: 27, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.courseCode ?? 'Choose your next course', style: editorialText(context, size: 16, weight: FontWeight.w700)), const SizedBox(height: 3), Text(title ?? (widget.courseCode == null ? 'Add your courses to begin.' : 'Open your course resources'), style: editorialText(context, size: 11)),
    if (total != null && total! > 0) ...[const SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: done! / total!, color: editorialGreen, backgroundColor: editorialGreen.withValues(alpha: .13), minHeight: 6)), const SizedBox(height: 5), Align(alignment: Alignment.centerRight, child: Text('${(done! / total! * 100).round()}% complete', style: editorialText(context, size: 10, color: SkinTokens.of(context).primary)))],
  ])), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 20)]));
}

class EditorialStudyLayout extends StatelessWidget {
  const EditorialStudyLayout({super.key, required this.services, required this.onOpen, required this.onCourses, required this.onSearch, required this.onSaved, required this.onDownloads, required this.onFocus, this.motivation = const SizedBox.shrink()});
  final List<Map<String, dynamic>> services;
  final void Function(Map<String, dynamic>) onOpen;
  final VoidCallback onCourses, onSearch, onSaved, onDownloads, onFocus;
  final Widget motivation;
  @override Widget build(BuildContext context) {
    const ids = ['course-summary', 'exam-summary', 'past-questions', 'courses', 'study-hub', 'my-courses'];
    final cells = <({String label, String caption, IconData icon, Color tone, bool ivory, VoidCallback tap})>[];
    for (final id in ids) {
      if (id == 'my-courses') {cells.add((label: 'My Courses', caption: 'View and manage your registered courses', icon: Icons.school_rounded, tone: editorialGreen, ivory: true, tap: onCourses)); continue;}
      final matches = services.where((s) => s['id'] == id);
      if (matches.isEmpty) continue;
      final s = matches.first;
      cells.add((label: serviceLabel(id, '${s['label']}'), caption: switch(id) {'course-summary' => 'Concise notes and key points', 'exam-summary' => 'Key areas, tips and revision resources', 'past-questions' => 'Years of past questions with answers', 'courses' => 'Download and read course content', _ => 'Study tips, guides and useful resources'}, icon: switch(id) {'course-summary' => Icons.menu_book_outlined, 'exam-summary' || 'courses' => Icons.description_rounded, 'past-questions' => Icons.help_rounded, _ => Icons.groups_rounded}, tone: switch(id) {'exam-summary' || 'study-hub' => editorialGold, 'past-questions' => editorialRed, _ => editorialGreen}, ivory: false, tap: () => onOpen(s)));
    }
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    // Keep the poster's compact card proportions on taller phones too.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final tileHeight = (MediaQuery.sizeOf(context).width < 350 ? 182.0 : 164.0) + (textScale - 1).clamp(0, 1) * 100;
    return ListView(key: const PageStorageKey('study'), padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
      EditorialSearch(onTap: onSearch),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cells.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: large ? 1 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: large ? 200 : tileHeight), itemBuilder: (context, i) {
        final cell = cells[i], ink = cell.ivory ? SkinTokens.of(context).ink : Colors.white;
        return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), boxShadow: [BoxShadow(color: cell.tone.withValues(alpha: .09), blurRadius: 12, offset: const Offset(0, 4))], gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cell.ivory ? [SkinTokens.of(context).surface, SkinTokens.of(context).background] : [Color.lerp(cell.tone, Colors.white, .08)!, Color.lerp(cell.tone, Colors.black, .12)!]), border: Border.all(color: cell.ivory ? editorialGold.withValues(alpha: .16) : Colors.white.withValues(alpha: .10))), child: Material(color: Colors.transparent, child: InkWell(onTap: cell.tap, borderRadius: BorderRadius.circular(13), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Align(alignment: Alignment.center, child: Icon(cell.icon, size: 43, color: cell.ivory ? SkinTokens.of(context).primary : const Color(0xfffff8e4))), const SizedBox(height: 18), Text(cell.label, style: editorialText(context, size: 16, color: ink, weight: FontWeight.w700)), const SizedBox(height: 6), Text(cell.caption, maxLines: 3, overflow: TextOverflow.ellipsis, style: editorialText(context, size: 11, color: ink.withValues(alpha: .94)))])))));
      }),
      const SizedBox(height: 17), motivation,
      EditorialHeading('Your library'),
      EditorialPanel(padding: EdgeInsets.zero, child: Column(children: [ListTile(title: const Text('Saved resources'), leading: const Icon(Icons.bookmark_border), onTap: onSaved), ListTile(title: const Text('Downloads'), leading: const Icon(Icons.download_outlined), onTap: onDownloads), ListTile(title: const Text('Focus timer'), leading: const Icon(Icons.timer_outlined), onTap: onFocus)])),
      for (final s in services.where((s) => !ids.contains(s['id']))) Padding(padding: const EdgeInsets.only(top: 10), child: EditorialPanel(onTap: () => onOpen(s), child: Row(children: [Icon(serviceIcon('${s['id']}'), color: SkinTokens.of(context).primary), const SizedBox(width: 12), Expanded(child: Text(serviceLabel('${s['id']}', '${s['label']}'))), const Icon(Icons.chevron_right)]))),
    ]);
  }
}

class EditorialWallet extends StatelessWidget {
  const EditorialWallet({super.key, required this.balance, required this.onFund, required this.onPremium, required this.onHistory, required this.transactions, required this.signedIn});
  final String balance;
  final bool signedIn;
  final List<Map<String, dynamic>> transactions;
  final VoidCallback onFund, onPremium, onHistory;
  @override Widget build(BuildContext context) => Column(children: [
    Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff006042), Color(0xff003821)]), boxShadow: [BoxShadow(color: editorialGreen.withValues(alpha: .13), blurRadius: 14, offset: const Offset(0, 5))]), child: Row(children: [Container(width: 59, height: 59, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xff53d6af), Color(0xff008969)])), child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 31)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Wallet Balance', style: editorialText(context, size: 12, color: Colors.white)), const SizedBox(height: 4), Text(balance, style: editorialText(context, size: 26, color: Colors.white, weight: FontWeight.w700)), const SizedBox(height: 10), FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xffe9cc7e), foregroundColor: const Color(0xff193221), minimumSize: const Size(125, 35), padding: const EdgeInsets.symmetric(horizontal: 22), shape: const StadiumBorder()), onPressed: onFund, child: Text(signedIn ? 'Fund Wallet' : 'Sign in', style: editorialText(context, size: 12, color: const Color(0xff193221), weight: FontWeight.w700)))]))])),
    const SizedBox(height: 12),
    ListenableBuilder(listenable: PremiumService.instance, builder: (context, _) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xff002d20), borderRadius: BorderRadius.circular(13)), child: InkWell(onTap: onPremium, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const EditorialCrown(), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('NOUN Update Premium', style: editorialText(context, size: 13, color: Colors.white, weight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: PremiumService.instance.isPremium ? const Color(0xffa7e7bd) : const Color(0xffe9cc7e), borderRadius: BorderRadius.circular(20)), child: Text(PremiumService.instance.isPremium ? 'Active' : 'Explore', style: editorialText(context, size: 10, color: const Color(0xff143423), weight: FontWeight.w700)))]), const SizedBox(height: 5), Text(PremiumService.instance.isPremium ? 'Your premium appearance is active' : 'Choose your premium experience', style: editorialText(context, size: 10, color: Colors.white.withValues(alpha: .84))), const SizedBox(height: 9), for (final benefit in ['Ten exclusive skins and profile styles', 'Ad-free experience', 'Personal study analytics']) Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [const Icon(Icons.verified_user_outlined, size: 12, color: Color(0xffd7ebdb)), const SizedBox(width: 6), Expanded(child: Text(benefit, style: editorialText(context, size: 10, color: Colors.white.withValues(alpha: .9))))]))]))])))),
    EditorialHeading('Transaction History', action: onHistory),
    EditorialPanel(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), child: transactions.isEmpty ? Padding(padding: const EdgeInsets.all(12), child: Text(signedIn ? 'No wallet transactions yet.' : 'Sign in to view your transactions.', style: editorialText(context, size: 12))) : Column(children: [for (var i = 0; i < transactions.take(3).length; i++) ...[if (i > 0) Divider(height: 1, color: SkinTokens.of(context).gold.withValues(alpha: .13)), _transaction(context, transactions[i])]])),
  ]);
  Widget _transaction(BuildContext context, Map<String, dynamic> row) {
    final rawStatus = row['status']?.toString();
    final success = ['credited', 'successful', 'success', 'completed', 'posted'].contains(rawStatus?.toLowerCase());
    final topup = '${row['type'] ?? row['title']}'.toLowerCase().contains('top');
    final date = DateTime.tryParse('${row['created_at'] ?? ''}');
    final dateLabel = date == null ? '${row['created_at'] ?? ''}' : '${date.day} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month-1]} ${date.year}';
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [CircleAvatar(radius: 20, backgroundColor: topup ? const Color(0xffd9efd7) : const Color(0xfff3e8c6), child: Icon(topup ? Icons.add : Icons.description_rounded, color: topup ? editorialGreen : editorialGold, size: 23)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${row['title'] ?? 'Wallet transaction'}', style: editorialText(context, size: 12, weight: FontWeight.w700)), const SizedBox(height: 4), Text(dateLabel, style: editorialText(context, size: 10, color: SkinTokens.of(context).ink.withValues(alpha: .65)))])), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(editorialMoney(row['amount_kobo']), style: editorialText(context, size: 12, weight: FontWeight.w700)), if (rawStatus != null) ...[const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: success ? const Color(0xffd5efcf) : const Color(0xfff3e8c6), borderRadius: BorderRadius.circular(6)), child: Text(success ? 'Successful' : rawStatus, style: editorialText(context, size: 9, color: const Color(0xff243b28))))]])]));
  }
}

class EditorialProfileDetails extends StatelessWidget {
  const EditorialProfileDetails({super.key, required this.profile, required this.details, required this.onEdit});
  final Map<String, dynamic>? profile;
  final Map<String, String> details;
  final VoidCallback onEdit;
  @override Widget build(BuildContext context) => Column(children: [EditorialHeading('Profile Details', action: onEdit, actionLabel: 'Edit'), EditorialPanel(child: Column(children: [
    Row(children: [PremiumProfileAvatar(name: '${profile?['name'] ?? details['Name'] ?? 'Student'}', size: 56), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${profile?['name'] ?? details['Name'] ?? 'Your student profile'}', style: editorialText(context, size: 16, weight: FontWeight.w700)), const SizedBox(height: 3), Text('${profile?['matric_number'] ?? profile?['email'] ?? 'Complete your student details'}', style: editorialText(context, size: 11)), const SizedBox(height: 6), Text(profile == null ? 'Guest' : 'Signed in', style: editorialText(context, size: 10, color: SkinTokens.of(context).primary))]))]), const SizedBox(height: 12),
    for (final item in [(Icons.school_outlined, 'Programme', details['Programme'] ?? profile?['programme']), (Icons.bar_chart_rounded, 'Level', details['Level'] ?? profile?['level']), (Icons.location_on_outlined, 'Study Centre', details['Study centre'])]) ...[Divider(height: 1, color: SkinTokens.of(context).gold.withValues(alpha: .14)), Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Icon(item.$1, size: 17, color: SkinTokens.of(context).primary), const SizedBox(width: 9), Text(item.$2, style: editorialText(context, size: 11, weight: FontWeight.w700)), const SizedBox(width: 12), Expanded(child: Text('${item.$3 ?? 'Add details'}', textAlign: TextAlign.right, style: editorialText(context, size: 11)))]))],
  ]))]);
}

class EditorialWelcome extends StatelessWidget {
  const EditorialWelcome({super.key, required this.onLogin, required this.onRegister, required this.onGuest});
  final VoidCallback onLogin, onRegister, onGuest;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xfff5f0df), body: LayoutBuilder(builder: (context, constraints) {
    final minimum = 760.0 + (MediaQuery.textScalerOf(context).scale(14) / 14 - 1).clamp(0, 3) * 340;
    final height = constraints.maxHeight < minimum ? minimum : constraints.maxHeight;
    return SingleChildScrollView(child: SizedBox(height: height, child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xff003c29)),
      Positioned(top: height * .15, left: 0, right: 0, bottom: 0, child: ShaderMask(blendMode: BlendMode.dstIn, shaderCallback: (bounds) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black, Colors.black], stops: [0, .16, 1]).createShader(bounds), child: Image.asset('assets/images/skins/editorial-campus.webp', fit: BoxFit.cover))),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33002f20), Colors.transparent, Color(0xfff5f0df), Color(0xfff5f0df)], stops: [0, .67, .85, 1]))),
      SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(children: [
        const SizedBox(height: 18), Align(alignment: Alignment.centerLeft, child: IconButton(tooltip: 'Continue as guest', onPressed: onGuest, icon: const Icon(Icons.arrow_back, color: Colors.white))),
        const SizedBox(height: 12), EditorialLogo(size: height >= 950 ? 230 : 200), const SizedBox(height: 16),
        const Text('Your Academic\nCompanion at NOUN', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'NUReading', fontSize: 28, height: 1.08, color: Colors.white, fontWeight: FontWeight.w500)), const SizedBox(height: 11),
        Text('Updates. Resources. Past Questions.\nA Brighter You Always.', textAlign: TextAlign.center, style: editorialText(context, size: 13, color: Colors.white)),
        const Spacer(),
        SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: editorialGreen, foregroundColor: Colors.white, minimumSize: const Size(0, 49), shape: const StadiumBorder()), onPressed: onLogin, child: Row(children: [const Spacer(), Text('Log In', style: editorialText(context, size: 15, color: Colors.white, weight: FontWeight.w700)), const Spacer(), const Icon(Icons.chevron_right, size: 20)]))), const SizedBox(height: 11),
        SizedBox(width: double.infinity, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: const Color(0xff183526), minimumSize: const Size(0, 49), side: const BorderSide(color: Color(0xff8e977d)), shape: const StadiumBorder()), onPressed: onRegister, child: Text('Create Account', style: editorialText(context, size: 14, color: const Color(0xff183526), weight: FontWeight.w700)))), const SizedBox(height: 15),
        Text('Students Today. Greater Tomorrow.', style: editorialText(context, size: 11, color: const Color(0xff143927))), const SizedBox(height: 17),
        TextButton(onPressed: onGuest, child: Text('Continue as guest', style: editorialText(context, size: 11, color: const Color(0xff143927)))), const SizedBox(height: 12),
      ]))),
    ])));
  }));
}
