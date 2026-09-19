import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../repositories/app_repository.dart';
import '../widgets/shared_widgets.dart';
import 'course_screen.dart';
import 'notifications_screen.dart';
import 'tool_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.bootstrap!;
    final firstName = data.profile.name.split(' ').first;
    final unread = data.alerts.where((item) => !item.isRead).length;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.initialise,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        const BrandMark(compact: true),
                        const Spacer(),
                        IconButton.filledTonal(
                          tooltip: 'Notifications',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationsScreen(
                                alerts: data.alerts,
                              ),
                            ),
                          ),
                          icon: Badge(
                            isLabelVisible: unread > 0,
                            label: Text('$unread'),
                            backgroundColor: AppColours.danger,
                            child: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Hello, $firstName! 👋',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data.profile.programme} • ${data.profile.level}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (controller.isUsingDemoData) ...[
                      const SizedBox(height: 14),
                      const DemoDataBanner(),
                    ],
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => controller.selectTab(1),
                      child: const AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search course code, TMA, result or anything NOUN',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MyNounCard(dashboard: data.dashboard),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Popular tools',
                      actionLabel: 'See all',
                      onAction: () => controller.selectTab(1),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.builder(
                  itemCount: AppCatalogue.tools.take(9).length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .92,
                  ),
                  itemBuilder: (context, index) {
                    final tool = AppCatalogue.tools[index];
                    return ToolTile(
                      tool: tool,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ToolScreen(tool: tool)),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                sliver: SliverList.list(
                  children: [
                    const SectionHeader(title: 'My courses'),
                    const SizedBox(height: 10),
                    ...data.dashboard.courses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseCard(course: course),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PremiumCard(isPremium: data.profile.isPremium),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyNounCard extends StatelessWidget {
  const _MyNounCard({required this.dashboard});

  final DashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColours.green900, AppColours.green700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColours.green900.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY NOUN',
                        style: TextStyle(
                          color: AppColours.green500,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Semester readiness',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${dashboard.nextExamCode} is your next focus • ${dashboard.daysToNextExam} days',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ReadinessRing(value: dashboard.readiness),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColours.green500),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      dashboard.recommendation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final CourseProgress course;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CourseScreen(course: course)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColours.mint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    course.code.substring(0, 3),
                    style: const TextStyle(
                      color: AppColours.green700,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.code, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: course.readiness / 100,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE6ECE8),
                          color: course.readiness < 60
                              ? AppColours.warning
                              : AppColours.green600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${course.readiness}%',
                  style: const TextStyle(
                    color: AppColours.green700,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColours.green900,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.diamond_rounded, color: Color(0xFF59E0E7), size: 44),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium is active' : 'Upgrade to Premium',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPremium
                        ? 'Your premium study tools are unlocked.'
                        : 'Unlock summaries, Study Hub, AI Tutor and advanced mock tests.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      );
}

