import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';
import '../repositories/app_repository.dart';
import '../widgets/shared_widgets.dart';
import 'tool_screen.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({required this.course, super.key});

  final CourseProgress course;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(course.code),
            actions: [
              IconButton(
                tooltip: 'Save course',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course saved for quick access.')),
                ),
                icon: const Icon(Icons.bookmark_border_rounded),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Resources'),
                Tab(text: 'Study Mode'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _OverviewTab(course: course),
              _ResourcesTab(course: course),
              _StudyModeTab(course: course),
            ],
          ),
        ),
      );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.course});

  final CourseProgress course;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColours.green900, AppColours.green700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.code,
                        style: const TextStyle(
                          color: AppColours.green500,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '200 Level • 3 Units • First Semester',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ReadinessRing(value: course.readiness),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Course status'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatusRow(
                    label: 'Official course material',
                    ready: course.materialReady,
                  ),
                  _StatusRow(label: 'TMA resources', ready: course.tmaReady),
                  _StatusRow(
                    label: 'Past questions',
                    ready: course.pastQuestionsReady,
                  ),
                  _StatusRow(
                    label: 'Smart summary',
                    ready: course.summaryReady,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Exam intelligence'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.insights_rounded, color: AppColours.green700),
                      SizedBox(width: 10),
                      Text(
                        'Topic needing attention',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    course.weakTopic,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'This is based on your practice history, not an exam prediction.',
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ready, this.isLast = false});

  final String label;
  final bool ready;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEDF0EE))),
        ),
        child: Row(
          children: [
            Icon(
              ready ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: ready ? AppColours.green600 : AppColours.warning,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(
              ready ? 'Available' : 'Pending',
              style: TextStyle(
                color: ready ? AppColours.green700 : AppColours.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.course});

  final CourseProgress course;

  @override
  Widget build(BuildContext context) {
    final courseResources = AppCatalogue.resources
        .where((item) => item.courseCode == course.code)
        .toList();
    const toolIds = [
      'materials',
      'past-questions',
      'tma',
      'summaries',
      'mock',
      'ai-tutor',
    ];
    final tools = AppCatalogue.tools.where((tool) => toolIds.contains(tool.id));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Everything for this course'),
        const SizedBox(height: 10),
        ...tools.map(
          (tool) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColours.mint,
                  foregroundColor: AppColours.green700,
                  child: Icon(tool.icon),
                ),
                title: Text(tool.label),
                subtitle: Text('${tool.subtitle} • ${course.code}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ToolScreen(tool: tool, courseCode: course.code),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (courseResources.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionHeader(title: 'Recommended resources'),
          const SizedBox(height: 10),
          ...courseResources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ResourceCard(
                resource: resource,
                onTap: () {},
                onSave: () {},
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StudyModeTab extends StatelessWidget {
  const _StudyModeTab({required this.course});

  final CourseProgress course;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Read', 'Continue the current unit summary', Icons.menu_book_rounded),
      ('Learn', 'Ask the course-grounded AI Tutor', Icons.smart_toy_outlined),
      ('Practise', 'Complete a 10-question topic quiz', Icons.task_alt_rounded),
      ('Past questions', 'Review historical question patterns', Icons.history_edu_rounded),
      ('Mock', 'Take a timed course examination', Icons.timer_outlined),
      ('Review', 'Study explanations and weak topics', Icons.insights_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColours.mint,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STUDY MODE',
                style: TextStyle(
                  color: AppColours.green700,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A connected path for ${course.code}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text('Complete one focused step at a time. Your progress syncs across devices.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...steps.indexed.map(
          (entry) {
            final index = entry.$1;
            final step = entry.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Card(
                child: ListTile(
                  minTileHeight: 76,
                  leading: CircleAvatar(
                    backgroundColor: index == 0
                        ? AppColours.green700
                        : AppColours.mint,
                    foregroundColor: index == 0
                        ? Colors.white
                        : AppColours.green700,
                    child: Icon(step.$3),
                  ),
                  title: Text('${index + 1}. ${step.$1}'),
                  subtitle: Text(step.$2),
                  trailing: Icon(
                    index == 0
                        ? Icons.play_circle_fill_rounded
                        : Icons.lock_open_rounded,
                    color: AppColours.green700,
                  ),
                  onTap: () {},
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Study session will connect to the live Study Hub API.'),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Continue ${course.code}'),
        ),
      ],
    );
  }
}

