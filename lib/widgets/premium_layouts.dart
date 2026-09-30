import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/skin_theme.dart';
import 'native_ui.dart';
import 'skin_art.dart';
import 'editorial_layouts.dart';
import 'bold_layouts.dart';

class PremiumTopBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumTopBar({super.key, required this.onTools, required this.onRefresh, required this.onNotifications});
  final VoidCallback onTools;
  final VoidCallback onRefresh;
  final VoidCallback onNotifications;
  @override Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lightShell = <AppSkin>{AppSkin.smartCampus, AppSkin.studentFriendly, AppSkin.minimalAcademic, AppSkin.elegantEditorial, AppSkin.friendlyModern, AppSkin.boldPremium}.contains(t.skin) && !dark;
    final background = lightShell ? t.surface.withValues(alpha: .97) : Color.lerp(t.background, t.primary, .14)!.withValues(alpha: .97);
    final foreground = ThemeData.estimateBrightnessForColor(background) == Brightness.light ? t.ink : Colors.white;
    final tech = t.skin == AppSkin.futureTech;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: background,
      foregroundColor: foreground,
      titleSpacing: 16,
      title: Row(children: [
        BrandLogo(size: t.skin == AppSkin.minimalAcademic ? 31 : 36),
        const SizedBox(width: 10),
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NOUN Update', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: t.displayFont, fontWeight: t.headingWeight, letterSpacing: t.headingTracking, color: foreground, height: 1.05)),
          const SizedBox(height: 3),
          Text(t.shellTagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontFamily: t.bodyFont, fontSize: 8.5, letterSpacing: t.labelTracking, color: foreground.withValues(alpha: .72))),
        ])),
      ]),
      actions: [
        _TopAction(Icons.search_rounded, 'Search tools', foreground, tech, onTools),
        _TopAction(Icons.refresh_rounded, 'Refresh', foreground, tech, onRefresh),
        _TopAction(Icons.notifications_none_rounded, 'Notifications', foreground, tech, onNotifications),
        const SizedBox(width: 5),
      ],
      bottom: t.skin == AppSkin.boldPremium ? PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [t.primary, t.gold, t.primary])))) : null,
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction(this.icon, this.tooltip, this.foreground, this.tech, this.tap);
  final IconData icon;
  final String tooltip;
  final Color foreground;
  final bool tech;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: tap,
        icon: Container(
          padding: tech ? const EdgeInsets.all(7) : EdgeInsets.zero,
          decoration: tech ? BoxDecoration(border: Border.all(color: SkinTokens.of(context).primary.withValues(alpha: .45)), borderRadius: BorderRadius.circular(9)) : null,
          child: Icon(icon, size: 20, color: foreground),
        ),
      );
}

class PremiumBottomNavigation extends StatelessWidget {
  const PremiumBottomNavigation({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  static const items = <({IconData icon, IconData selected, String label})>[
    (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Home'),
    (icon: Icons.menu_book_outlined, selected: Icons.menu_book_rounded, label: 'Study'),
    (icon: Icons.grid_view_rounded, selected: Icons.grid_view_rounded, label: 'Tools'),
    (icon: Icons.newspaper_outlined, selected: Icons.newspaper_rounded, label: 'Updates'),
    (icon: Icons.person_outline_rounded, selected: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tech = t.skin == AppSkin.futureTech;
    final glass = t.skin == AppSkin.glassmorphism;
    final editorial = t.skin == AppSkin.elegantEditorial;
    final bold = t.skin == AppSkin.boldPremium;
    final destinations = editorial ? <({IconData icon, IconData selected, String label})>[
      items[0], items[1], items[3],
      (icon: Icons.account_balance_wallet_outlined, selected: Icons.account_balance_wallet_rounded, label: 'Wallet'),
      (icon: Icons.more_horiz, selected: Icons.more_horiz, label: 'More'),
    ] : bold ? <({IconData icon, IconData selected, String label})>[items[0],items[1],items[2],(icon:Icons.account_balance_wallet_outlined,selected:Icons.account_balance_wallet_rounded,label:'Wallet'),items[4]] : items;
    final order = editorial ? [0, 1, 3, 4, 2] : bold ? [0, 1, 2, 5, 4] : [0, 1, 2, 3, 4];
    final background = dark ? Color.lerp(t.surface, Colors.black, .10)! : t.surface;
    final bar = SafeArea(
      top: false,
      child: Container(
        height: editorial || bold ? 61 + (MediaQuery.textScalerOf(context).scale(12) / 12 - 1).clamp(0, 3) * 20 : 68,
        padding: EdgeInsets.symmetric(horizontal: tech ? 8 : 10, vertical: 7),
        decoration: BoxDecoration(color: background.withValues(alpha: glass ? .78 : 1), border: Border(top: BorderSide(color: (tech ? t.primary : t.gold).withValues(alpha: tech ? .36 : .16)))),
        child: Row(children: [for (var i = 0; i < destinations.length; i++) Expanded(child: _NavItem(item: destinations[i], selected: order[i] == index, onTap: () => onChanged(order[i])))]),
      ),
    );
    if (!glass) return bar;
    return ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: bar));
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.selected, required this.onTap});
  final ({IconData icon, IconData selected, String label}) item;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    final tech = t.skin == AppSkin.futureTech;
    final friendly = t.skin == AppSkin.friendlyModern || t.skin == AppSkin.studentFriendly;
    final active = t.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(friendly ? 22 : 12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: selected && t.skin != AppSkin.elegantEditorial && t.skin != AppSkin.boldPremium ? (tech ? active.withValues(alpha: .12) : Color.lerp(t.surface, active, .12)) : Colors.transparent, borderRadius: BorderRadius.circular(friendly ? 22 : 12), border: tech && selected ? Border.all(color: active.withValues(alpha: .45)) : null),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(selected ? item.selected : item.icon, size: selected && tech ? 23 : 21, color: selected ? active : t.ink.withValues(alpha: .62)),
            const SizedBox(height: 3),
            Text(item.label, maxLines: 1, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontFamily: t.bodyFont, fontSize: 9, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, letterSpacing: tech ? .5 : 0, color: selected ? active : t.ink.withValues(alpha: .72))),
          ]),
        ),
      ),
    );
  }
}

class PremiumHomeLayout extends StatelessWidget {
  const PremiumHomeLayout({super.key, required this.greeting, required this.meta, required this.nextExamSummary, this.nextExam, this.studyCentre, this.continueCourse, this.onSearch, this.onTopUp, this.importantUpdate=const SizedBox.shrink(), this.workspaceStatus=const SizedBox.shrink(), required this.courseCount, required this.walletBalance, required this.setupNeeded, required this.quickServices, required this.birthday, required this.motivation, required this.latestUpdates, required this.onSetup, required this.onCourses, required this.onExam, required this.onStudy, required this.onWallet, required this.onOpen});
  final Widget importantUpdate;
  final VoidCallback? onTopUp;
  final Map<String, dynamic>? nextExam;
  final String? studyCentre;
  final Widget? continueCourse;
  final VoidCallback? onSearch;
  final Widget workspaceStatus;
  final String nextExamSummary;
  final String greeting;
  final String meta;
  final int courseCount;
  final String walletBalance;
  final bool setupNeeded;
  final List<Map<String, dynamic>> quickServices;
  final Widget birthday;
  final Widget motivation;
  final Widget latestUpdates;
  final VoidCallback onSetup;
  final VoidCallback onCourses;
  final VoidCallback onExam;
  final VoidCallback onStudy;
  final VoidCallback onWallet;
  final void Function(Map<String, dynamic>) onOpen;

  @override
  Widget build(BuildContext context) => switch (SkinTokens.of(context).skin) {
        AppSkin.premiumDark => _premiumDark(context),
        AppSkin.glassmorphism => _glass(context),
        AppSkin.studentFriendly => _studentFriendly(context),
        AppSkin.minimalAcademic => _minimal(context),
        AppSkin.elegantEditorial => _editorial(context),
        AppSkin.productivityDashboard => _productivity(context),
        AppSkin.friendlyModern => _friendly(context),
        AppSkin.futureTech => _futureTech(context),
        AppSkin.boldPremium => _bold(context),
        _ => _smartCampus(context),
      };

  Widget _page(List<Widget> children) => ListView(key: const PageStorageKey('home'), padding: const EdgeInsets.fromLTRB(18, 18, 18, 28), children: [children.first, workspaceStatus, birthday, motivation, ...children.skip(1)]);

  Widget _heading(BuildContext context, String text, {String? subtitle}) {
    final t = SkinTokens.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.headingWeight, letterSpacing: t.headingTracking, height: t.headingHeight)),
      if (subtitle != null && subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .68)))),
    ]));
  }

  Widget _setupCard(BuildContext context) => !setupNeeded ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(bottom: 12), child: _actionCard(context, title: 'Complete your student profile', subtitle: 'Programme, level, study centre and semester.', icon: Icons.badge_outlined, onTap: onSetup));

  Widget _actionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap, Color? tone, bool darkCard = false}) {
    final t = SkinTokens.of(context); final colour = tone ?? t.primary;
    return Material(color: darkCard ? Color.lerp(t.surface, Colors.black, .17) : Color.lerp(t.surface, colour, .07), borderRadius: BorderRadius.circular(t.radius), child: InkWell(borderRadius: BorderRadius.circular(t.radius), onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: colour.withValues(alpha: .14), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: colour)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.titleWeight)), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .68)))])),
      Icon(Icons.chevron_right_rounded, color: t.ink.withValues(alpha: .48)),
    ]))));
  }

  Widget _metrics(BuildContext context, List<(String label, String value, IconData icon, Color colour)> values) {
    final t = SkinTokens.of(context);
    return Row(children: [for (var i = 0; i < values.length; i++) ...[
      if (i > 0) const SizedBox(width: 8),
      Expanded(child: Container(height: 94, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Color.lerp(t.surface, values[i].colour, .08), borderRadius: BorderRadius.circular(t.radius), border: Border.all(color: values[i].colour.withValues(alpha: .15))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(values[i].icon, size: 20, color: values[i].colour), const Spacer(),
        Text(values[i].value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: t.numberFont, fontWeight: FontWeight.w800)),
        Text(values[i].label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .64))),
      ]))),
    ]]);
  }

  Widget _quickTools(BuildContext context) {
    final t = SkinTokens.of(context); final items = quickServices.take(4).toList();
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: t.skin == AppSkin.friendlyModern ? 132 : 116), itemBuilder: (_, i) {
      final service = items[i]; final id = '${service['id']}'; final tone = skinServiceColour(id);
      return Material(color: Color.lerp(t.surface, tone, .09), borderRadius: BorderRadius.circular(t.radius), child: InkWell(borderRadius: BorderRadius.circular(t.radius), onTap: () => onOpen(service), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(serviceIcon(id), color: tone, size: 25), const Spacer(), Text(serviceLabel(id, '${service['label']}'), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.titleWeight))]))));
    });
  }

  Widget _tail(BuildContext context, String heading) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 18), _heading(context, heading), _quickTools(context), const SizedBox(height: 18), _heading(context, 'Latest updates'), latestUpdates]);

  Widget _smartCampus(BuildContext c) => _page([_heading(c, greeting, subtitle: meta), _setupCard(c), _metrics(c, [('Wallet', walletBalance, Icons.account_balance_wallet_rounded, SkinTokens.of(c).primary), ('Courses', '$courseCount', Icons.menu_book_rounded, Colors.green)]), const SizedBox(height: 12), _actionCard(c, title: 'Next examination', subtitle: nextExamSummary, icon: Icons.calendar_month_rounded, onTap: onExam, tone: Colors.red), const SizedBox(height: 10), _actionCard(c, title: 'Continue studying', subtitle: 'Open your courses and choose the next chapter.', icon: Icons.play_circle_fill_rounded, onTap: onStudy, tone: Colors.green), _tail(c, 'Quick tools')]);

  Widget _premiumDark(BuildContext c) { final t = SkinTokens.of(c); return _page([_heading(c, greeting, subtitle: meta), _setupCard(c), _actionCard(c, title: 'Next examination', subtitle: nextExamSummary, icon: Icons.event_rounded, onTap: onExam, tone: t.gold, darkCard: true), const SizedBox(height: 10), _actionCard(c, title: 'Continue studying', subtitle: courseCount == 0 ? 'Add your courses to begin.' : '$courseCount courses ready in your library.', icon: Icons.auto_stories_rounded, onTap: onStudy, tone: Colors.greenAccent, darkCard: true), const SizedBox(height: 12), _metrics(c, [('Wallet', walletBalance, Icons.wallet_rounded, t.gold), ('Courses', '$courseCount', Icons.school_rounded, t.primary)]), _tail(c, 'Quick actions')]); }

  Widget _glass(BuildContext c) { final t = SkinTokens.of(c); Widget panel(Widget child) => ClipRRect(borderRadius: BorderRadius.circular(28), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: t.surface.withValues(alpha: .58), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .34))), child: child))); return _page([_heading(c, greeting, subtitle: meta), panel(Column(children: [_metrics(c, [('Wallet', walletBalance, Icons.wallet_rounded, t.gold), ('Courses', '$courseCount', Icons.auto_stories_rounded, t.primary)])])), const SizedBox(height: 13), _setupCard(c), panel(Column(children: [_actionCard(c, title: 'Next exam', subtitle: nextExamSummary, icon: Icons.calendar_month_rounded, onTap: onExam, tone: Colors.redAccent), const SizedBox(height: 9), _actionCard(c, title: 'Continue studying', subtitle: 'Pick up where you left off.', icon: Icons.play_arrow_rounded, onTap: onStudy, tone: t.primary)])), _tail(c, 'Shortcuts')]); }

  Widget _studentFriendly(BuildContext c) => _page([_heading(c, greeting, subtitle: meta), _setupCard(c), _actionCard(c, title: 'Next examination', subtitle: nextExamSummary, icon: Icons.campaign_rounded, onTap: onExam, tone: Colors.red), const SizedBox(height: 10), _metrics(c, [('Courses', '$courseCount', Icons.menu_book_rounded, Colors.green), ('My wallet', walletBalance, Icons.wallet_rounded, Colors.amber)]), const SizedBox(height: 12), _actionCard(c, title: 'Continue studying', subtitle: courseCount == 0 ? 'Add your first course.' : 'Choose from $courseCount saved courses.', icon: Icons.menu_book_rounded, onTap: onStudy, tone: Colors.green), _tail(c, 'Quick tools')]);

  Widget _minimal(BuildContext c) { final t = SkinTokens.of(c); return _page([_heading(c, greeting, subtitle: meta), _setupCard(c), Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(border: Border(top: BorderSide(color: t.ink.withValues(alpha: .10)), bottom: BorderSide(color: t.ink.withValues(alpha: .10)))), child: _actionCard(c, title: 'Next examination', subtitle: nextExamSummary, icon: Icons.calendar_today_outlined, onTap: onExam, tone: t.primary)), const SizedBox(height: 18), _metrics(c, [('Courses', '$courseCount', Icons.book_outlined, t.primary), ('Wallet', walletBalance, Icons.account_balance_wallet_outlined, t.gold)]), _tail(c, 'Quick actions')]); }

  Widget _editorial(BuildContext c) => ListView(key: const PageStorageKey('home'), padding: const EdgeInsets.fromLTRB(16, 14, 16, 28), children: [
    EditorialSearch(onTap: onSearch ?? onStudy, label: 'Search for courses, updates, resources…'),
    workspaceStatus, birthday,
    EditorialExamCard(summary: nextExamSummary, exam: nextExam, centre: studyCentre, onTap: onExam),
    const SizedBox(height: 12), latestUpdates,
    EditorialHeading('Continue Studying', action: onCourses),
    continueCourse ?? EditorialPanel(onTap: onStudy, child: Row(children: [const Icon(Icons.menu_book_outlined, color: editorialGreen), const SizedBox(width: 10), Expanded(child: Text(courseCount == 0 ? 'Add your courses to begin.' : '$courseCount courses in your library', style: editorialText(c, size: 13))), const Icon(Icons.arrow_forward, size: 19)])),
    const EditorialHeading('Quick Tools'), EditorialQuickTools(services: quickServices, onOpen: onOpen),
    const SizedBox(height: 16), motivation,
    if (setupNeeded) _setupCard(c),
  ]);

  Widget _productivity(BuildContext c) { final t = SkinTokens.of(c); return _page([_heading(c, greeting, subtitle: meta), _setupCard(c), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: t.heroSurface, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEXT EXAM', style: Theme.of(c).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: .82), letterSpacing: 1.2)), const SizedBox(height: 6), Text(nextExamSummary, style: Theme.of(c).textTheme.titleLarge?.copyWith(color: Colors.white, fontFamily: t.displayFont, fontWeight: FontWeight.w800)), const SizedBox(height: 12), FilledButton.tonal(onPressed: onExam, child: const Text('View timetable'))])), const SizedBox(height: 12), _metrics(c, [('Tasks', '$courseCount courses', Icons.checklist_rounded, Colors.red), ('Wallet', walletBalance, Icons.wallet_rounded, Colors.teal), ('Study', 'Resume', Icons.play_arrow_rounded, Colors.blue)]), const SizedBox(height: 12), _actionCard(c, title: 'Continue studying', subtitle: 'Move one course forward today.', icon: Icons.menu_book_rounded, onTap: onStudy, tone: t.primary), _tail(c, 'Command shortcuts')]); }

  Widget _friendly(BuildContext c) => _page([_heading(c, greeting, subtitle: meta), _setupCard(c), _actionCard(c, title: 'Upcoming exam', subtitle: nextExamSummary, icon: Icons.calendar_month_rounded, onTap: onExam, tone: Colors.green), const SizedBox(height: 9), _actionCard(c, title: 'Latest academic notice', subtitle: 'Stay ahead of deadlines and important changes.', icon: Icons.notifications_active_rounded, onTap: () => onOpen({'id': 'news', 'label': 'News'}), tone: Colors.redAccent), const SizedBox(height: 12), _actionCard(c, title: 'Continue studying', subtitle: courseCount == 0 ? 'Start by adding your courses.' : '$courseCount courses are ready for you.', icon: Icons.play_circle_rounded, onTap: onStudy, tone: Colors.green), _tail(c, 'My quick tools')]);

  Widget _futureTech(BuildContext c) { final t = SkinTokens.of(c); return _page([_heading(c, greeting, subtitle: meta), _setupCard(c), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .24), borderRadius: BorderRadius.circular(16), border: Border.all(color: t.primary.withValues(alpha: .42)), boxShadow: [BoxShadow(color: t.primary.withValues(alpha: .10), blurRadius: 18)]), child: _metrics(c, [('Courses', '$courseCount', Icons.school_rounded, t.primary), ('Wallet', walletBalance, Icons.wallet_rounded, t.gold)])), const SizedBox(height: 11), _actionCard(c, title: 'NEXT EXAM', subtitle: nextExamSummary, icon: Icons.calendar_month_rounded, onTap: onExam, tone: Colors.redAccent, darkCard: true), const SizedBox(height: 9), _actionCard(c, title: 'CONTINUE STUDY', subtitle: 'Resume your academic workspace.', icon: Icons.play_circle_outline_rounded, onTap: onStudy, tone: t.primary, darkCard: true), _tail(c, 'QUICK MODULES')]); }

  Widget _bold(BuildContext c) => BoldHomeLayout(balance:walletBalance,nextExamSummary:nextExamSummary,nextExam:nextExam,
    services:quickServices,onOpen:onOpen,onWallet:onWallet,onTopUp:onTopUp??onWallet,onExam:onExam,
    onCourses:onCourses,onTools:onSearch??onStudy,continueCourse:continueCourse??const SizedBox.shrink(),
    importantUpdate:importantUpdate,latestUpdate:latestUpdates,birthday:birthday,workspaceStatus:workspaceStatus,
    motivation:motivation,setup:setupNeeded?_setupCard(c):null);

}

class PremiumStudyLayout extends StatelessWidget {
  const PremiumStudyLayout({super.key, required this.courseCount, required this.services, required this.onCourses, required this.onOpen, required this.onSaved, required this.onDownloads, required this.onFocus, this.onSearch, this.motivation = const SizedBox.shrink()});
  final VoidCallback? onSearch;
  final Widget motivation;
  final int courseCount;
  final List<Map<String, dynamic>> services;
  final VoidCallback onCourses;
  final void Function(Map<String, dynamic>) onOpen;
  final VoidCallback onSaved;
  final VoidCallback onDownloads;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final t = SkinTokens.of(context);
    if (t.skin == AppSkin.elegantEditorial) return EditorialStudyLayout(services: services, onOpen: onOpen, onCourses: onCourses, onSearch: onSearch ?? onCourses, onSaved: onSaved, onDownloads: onDownloads, onFocus: onFocus, motivation: motivation);
    if(t.skin==AppSkin.boldPremium)return BoldStudyLayout(services:services,onOpen:onOpen,onCourses:onCourses,onSearch:onSearch??onCourses,onSaved:onSaved,onDownloads:onDownloads,onFocus:onFocus,motivation:motivation);
    final grid = <AppSkin>{AppSkin.glassmorphism, AppSkin.studentFriendly, AppSkin.elegantEditorial, AppSkin.productivityDashboard, AppSkin.friendlyModern, AppSkin.boldPremium}.contains(t.skin);
    return ListView(key: const PageStorageKey('study'), padding: const EdgeInsets.fromLTRB(18, 18, 18, 28), children: [
      _StudyHeader(courseCount: courseCount, onCourses: onCourses),
      const SizedBox(height: 17),
      if (t.skin == AppSkin.productivityDashboard) ...[_StudyMetrics(courseCount: courseCount), const SizedBox(height: 18)],
      _SectionTitle('Study resources', subtitle: t.skin == AppSkin.futureTech ? 'ACADEMIC MODULES' : 'Everything you need to prepare with confidence.'),
      const SizedBox(height: 10),
      grid ? _resourceGrid(context) : _resourceList(context),
      const SizedBox(height: 20),
      _SectionTitle(t.skin == AppSkin.elegantEditorial ? 'Your library' : 'Study workspace'),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _mini(context, 'Saved', Icons.bookmark_border, onSaved)), const SizedBox(width: 8), Expanded(child: _mini(context, 'Downloads', Icons.download_outlined, onDownloads)), const SizedBox(width: 8), Expanded(child: _mini(context, 'Focus', Icons.timer_outlined, onFocus))]),
    ]);
  }

  Widget _resourceList(BuildContext c) => Column(children: [for (final s in services) Padding(padding: const EdgeInsets.only(bottom: 10), child: _resource(c, s, false))]);
  Widget _resourceGrid(BuildContext c) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: services.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.textScalerOf(c).scale(14) > 18 ? 1 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 150), itemBuilder: (_, i) => _resource(c, services[i], true));

  Widget _resource(BuildContext c, Map<String, dynamic> service, bool grid) {
    final t = SkinTokens.of(c); final id = '${service['id']}'; final tone = skinServiceColour(id); final tech = t.skin == AppSkin.futureTech; final glass = t.skin == AppSkin.glassmorphism;
    final mix = glass ? .12 : .08; final fill = tech ? Colors.black.withValues(alpha: .22) : Color.lerp(t.surface, tone, mix); final borderColour = tech ? t.primary : tone;
    final body = grid ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(serviceIcon(id), color: tone, size: 30), const Spacer(), Text(serviceLabel(id, '${service['label']}'), style: Theme.of(c).textTheme.titleSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.titleWeight)), const SizedBox(height: 4), Text(serviceCaption(id), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .68)))]) : Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: tone.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)), child: Icon(serviceIcon(id), color: tone)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(serviceLabel(id, '${service['label']}'), style: Theme.of(c).textTheme.titleSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.titleWeight)), const SizedBox(height: 4), Text(serviceCaption(id), style: Theme.of(c).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .68)))])), Icon(Icons.chevron_right_rounded, color: t.ink.withValues(alpha: .52))]);
    return Material(color: fill, borderRadius: BorderRadius.circular(t.radius), child: InkWell(borderRadius: BorderRadius.circular(t.radius), onTap: () => onOpen(service), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(t.radius), border: Border.all(color: borderColour.withValues(alpha: tech ? .40 : .14))), child: body)));
  }

  Widget _mini(BuildContext c, String label, IconData icon, VoidCallback tap) { final t = SkinTokens.of(c); return Material(color: t.surface, borderRadius: BorderRadius.circular(t.radius), child: InkWell(borderRadius: BorderRadius.circular(t.radius), onTap: tap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6), child: Column(children: [Icon(icon, color: t.primary), const SizedBox(height: 7), Text(label, maxLines: 1, style: Theme.of(c).textTheme.labelMedium?.copyWith(fontFamily: t.bodyFont, fontWeight: FontWeight.w700))])))); }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({required this.courseCount, required this.onCourses});
  final int courseCount; final VoidCallback onCourses;
  @override
  Widget build(BuildContext c) {
    final t = SkinTokens.of(c); final photo = <AppSkin>{AppSkin.glassmorphism, AppSkin.studentFriendly, AppSkin.friendlyModern}.contains(t.skin);
    return ConstrainedBox(constraints: BoxConstraints(minHeight: photo ? 190 : 158), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(t.radius), gradient: LinearGradient(colors: [t.heroSurface, Color.lerp(t.heroSurface, t.gold, .12)!])), child: ClipRRect(borderRadius: BorderRadius.circular(t.radius), child: Stack(children: [
      if (photo) Positioned.fill(child: Opacity(opacity: .38, child: Image.asset(t.heroAsset, fit: BoxFit.cover, alignment: Alignment.centerRight))),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [t.heroSurface.withValues(alpha: .95), t.heroSurface.withValues(alpha: .80), Colors.transparent])))),
      Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('STUDY', style: Theme.of(c).textTheme.labelSmall?.copyWith(fontFamily: t.bodyFont, color: Colors.white.withValues(alpha: .82), letterSpacing: t.labelTracking + 1)), const SizedBox(height: 8), Text(t.studyHeadline, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.headingWeight, letterSpacing: t.headingTracking, height: t.headingHeight, color: Colors.white)), const SizedBox(height: 7), Text('$courseCount registered courses · revision tools in one place.', style: Theme.of(c).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: Colors.white.withValues(alpha: .82))), const SizedBox(height: 14), FilledButton.tonal(onPressed: onCourses, child: const Text('My Courses'))])),
    ]))));
  }
}

class _StudyMetrics extends StatelessWidget {
  const _StudyMetrics({required this.courseCount});
  final int courseCount;
  @override
  Widget build(BuildContext c) {
    final t = SkinTokens.of(c);
    final items = <({String label, String value, IconData icon, Color colour})>[(label: 'Courses', value: '$courseCount', icon: Icons.menu_book_rounded, colour: Colors.green), (label: 'Revision', value: 'Ready', icon: Icons.insights_rounded, colour: Colors.blue), (label: 'Focus', value: 'Start', icon: Icons.timer_rounded, colour: Colors.orange)];
    return Row(children: [for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(width: 7),
      Expanded(child: Container(height: 92, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Color.lerp(t.surface, items[i].colour, .08), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(items[i].icon, color: items[i].colour, size: 20), const Spacer(), Text(items[i].value, style: Theme.of(c).textTheme.titleSmall?.copyWith(fontFamily: t.numberFont, fontWeight: FontWeight.w800)), Text(items[i].label, style: Theme.of(c).textTheme.labelSmall)]))),
    ]]);
  }
}

class PremiumToolsLayout extends StatelessWidget {
  const PremiumToolsLayout({super.key, required this.rows, required this.pinned, required this.onSearch, required this.onOpen, required this.onTogglePin, required this.walletBalance, required this.onWallet});
  final List<Map<String, dynamic>> rows; final Set<String> pinned; final ValueChanged<String> onSearch; final void Function(Map<String, dynamic>) onOpen; final void Function(Map<String, dynamic>) onTogglePin; final String walletBalance; final VoidCallback onWallet;

  @override
  Widget build(BuildContext c) {
    final t = SkinTokens.of(c); final groups = _grouped();
    return ListView(key: const PageStorageKey('tools'), padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
      _header(c), const SizedBox(height: 14), _search(c),
      if (t.skin == AppSkin.boldPremium) ...[const SizedBox(height: 14), _wallet(c)],
      if (pinned.isNotEmpty) ...[const SizedBox(height: 20), const _SectionTitle('Pinned'), const SizedBox(height: 10), _render(c, rows.where((s) => pinned.contains('${s['id']}')).toList(), forceGrid: true)],
      for (final entry in groups.entries) ...[const SizedBox(height: 21), _SectionTitle(entry.key), const SizedBox(height: 10), _render(c, entry.value)],
      if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 34), child: Center(child: Text('No tools match your search.', style: Theme.of(c).textTheme.bodyLarge))),
    ]);
  }

  Map<String, List<Map<String, dynamic>>> _grouped() { final result = <String, List<Map<String, dynamic>>>{}; for (final service in rows) { if (pinned.contains('${service['id']}')) continue; final group = '${service['group'] ?? 'Academic tools'}'; (result[group] ??= []).add(service); } return result; }
  Widget _header(BuildContext c) { final t = SkinTokens.of(c); final upper = t.skin == AppSkin.futureTech || t.skin == AppSkin.boldPremium; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(upper ? 'TOOLS' : 'Tools', style: Theme.of(c).textTheme.headlineMedium?.copyWith(fontFamily: t.displayFont, fontWeight: t.headingWeight, letterSpacing: t.headingTracking, height: t.headingHeight)), const SizedBox(height: 5), Text(t.toolsSubtitle, style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .68), height: 1.35))]); }

  Widget _search(BuildContext c) { final t = SkinTokens.of(c); final tech = t.skin == AppSkin.futureTech; final glass = t.skin == AppSkin.glassmorphism; final radius = glass ? 28.0 : t.radius; final field = TextField(onChanged: onSearch, style: TextStyle(fontFamily: t.bodyFont), decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded, color: t.primary), hintText: 'Find a tool', hintStyle: TextStyle(fontFamily: t.bodyFont), filled: true, fillColor: tech ? Colors.black.withValues(alpha: .24) : t.surface.withValues(alpha: glass ? .66 : 1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: (tech ? t.primary : t.ink).withValues(alpha: tech ? .36 : .10))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: (tech ? t.primary : t.ink).withValues(alpha: tech ? .36 : .10))))); if (!glass) return field; return ClipRRect(borderRadius: BorderRadius.circular(28), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: field)); }

  Widget _wallet(BuildContext c) { final t = SkinTokens.of(c); return Material(color: t.heroSurface, borderRadius: BorderRadius.circular(14), child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onWallet, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: t.gold, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.black87)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('WALLET BALANCE', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 9, letterSpacing: 1.1)), Text(walletBalance, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontFamily: t.numberFont, fontWeight: FontWeight.w900, color: Colors.white))])), const Icon(Icons.chevron_right, color: Colors.white)])))); }

  Widget _render(BuildContext c, List<Map<String, dynamic>> items, {bool forceGrid = false}) { final t = SkinTokens.of(c); final grid = forceGrid || <AppSkin>{AppSkin.studentFriendly, AppSkin.elegantEditorial, AppSkin.productivityDashboard, AppSkin.friendlyModern, AppSkin.boldPremium}.contains(t.skin); if (!grid) return Column(children: [for (final service in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: _listTool(c, service))]); return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.textScalerOf(c).scale(14) > 18 ? 1 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: t.skin == AppSkin.productivityDashboard ? 132 : (t.skin == AppSkin.friendlyModern ? 142 : 126)), itemBuilder: (_, i) => _gridTool(c, items[i])); }

  Widget _listTool(BuildContext c, Map<String, dynamic> service) {
    final t = SkinTokens.of(c); final id = '${service['id']}'; final tone = skinServiceColour(id); final glass = t.skin == AppSkin.glassmorphism; final tech = t.skin == AppSkin.futureTech; final dark = t.skin == AppSkin.premiumDark;
    final radius = glass ? 30.0 : t.radius; final fill = tech ? Colors.black.withValues(alpha: .24) : (dark ? Color.lerp(t.surface, Colors.black, .13) : t.surface.withValues(alpha: glass ? .60 : 1)); final borderColor = tech ? t.primary : (glass ? Colors.white : tone); final iconColor = tech && tone == const Color(0xff17845a) ? t.primary : tone;
    final card = Material(color: fill, borderRadius: BorderRadius.circular(radius), child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: () => onOpen(service), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: Border.all(color: borderColor.withValues(alpha: tech ? .44 : (glass ? .35 : .13)))), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: tone.withValues(alpha: dark || tech ? .20 : .13), borderRadius: BorderRadius.circular(14)), child: Icon(serviceIcon(id), color: iconColor)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(serviceLabel(id, '${service['label']}'), style: Theme.of(c).textTheme.titleSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.titleWeight)), const SizedBox(height: 4), Text(serviceCaption(id), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .68), height: 1.3))])), _pin(c, service)])))); if (!glass) return card; return ClipRRect(borderRadius: BorderRadius.circular(30), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: card));
  }

  Widget _gridTool(BuildContext c, Map<String, dynamic> service) { final t = SkinTokens.of(c); final id = '${service['id']}'; final tone = skinServiceColour(id); final productivity = t.skin == AppSkin.productivityDashboard; final friendly = t.skin == AppSkin.friendlyModern || t.skin == AppSkin.studentFriendly; final bold = t.skin == AppSkin.boldPremium; final mix = bold ? .13 : (friendly ? .08 : .10); return Material(color: Color.lerp(t.surface, tone, mix), borderRadius: BorderRadius.circular(t.radius), child: InkWell(borderRadius: BorderRadius.circular(t.radius), onTap: () => onOpen(service), child: Padding(padding: const EdgeInsets.all(13), child: Stack(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: tone.withValues(alpha: .14), borderRadius: BorderRadius.circular(productivity ? 10 : 13)), child: Icon(serviceIcon(id), color: tone, size: 23)), const Spacer(), Text(serviceLabel(id, '${service['label']}'), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.titleSmall?.copyWith(fontFamily: t.displayFont, fontWeight: t.titleWeight, height: 1.12)), if (!productivity) ...[const SizedBox(height: 3), Text(serviceCaption(id), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, fontSize: 10, color: t.ink.withValues(alpha: .65)))]]), Positioned(top: -8, right: -8, child: _pin(c, service, small: true))])))); }

  Widget _pin(BuildContext c, Map<String, dynamic> service, {bool small = false}) { final id = '${service['id']}'; final on = pinned.contains(id); final t = SkinTokens.of(c); return IconButton(visualDensity: small ? VisualDensity.compact : VisualDensity.standard, tooltip: on ? 'Unpin tool' : 'Pin tool', onPressed: () => onTogglePin(service), icon: Icon(on ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: small ? 17 : 20, color: on ? t.primary : t.ink.withValues(alpha: .48))); }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.subtitle}); final String title; final String? subtitle;
  @override Widget build(BuildContext c) { final t = SkinTokens.of(c); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontFamily: t.displayFont, fontWeight: t.headingWeight, letterSpacing: t.headingTracking)), if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(subtitle!, style: Theme.of(c).textTheme.bodySmall?.copyWith(fontFamily: t.bodyFont, color: t.ink.withValues(alpha: .62))))]); }
}
