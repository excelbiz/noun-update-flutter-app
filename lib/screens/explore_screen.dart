import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../repositories/app_repository.dart';
import '../widgets/shared_widgets.dart';
import 'course_screen.dart';
import 'tool_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalised = query.trim().toLowerCase();
    final courses = widget.controller.bootstrap!.dashboard.courses.where(
      (course) => normalised.isEmpty ||
          course.code.toLowerCase().contains(normalised) ||
          course.title.toLowerCase().contains(normalised),
    );
    final tools = AppCatalogue.tools.where(
      (tool) => normalised.isEmpty ||
          tool.label.toLowerCase().contains(normalised) ||
          tool.subtitle.toLowerCase().contains(normalised),
    );
    final resources = AppCatalogue.resources.where(
      (resource) => normalised.isEmpty ||
          resource.title.toLowerCase().contains(normalised) ||
          resource.category.toLowerCase().contains(normalised) ||
          (resource.courseCode?.toLowerCase().contains(normalised) ?? false),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore NOUN'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          TextField(
            controller: searchController,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Search anything about NOUN',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          if (normalised.isEmpty) ...[
            _JourneyCard(onOpen: _openJourney),
            const SizedBox(height: 24),
          ],
          if (courses.isNotEmpty) ...[
            SectionHeader(
              title: normalised.isEmpty ? 'Your courses' : 'Courses',
            ),
            const SizedBox(height: 9),
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColours.mint,
                      foregroundColor: AppColours.green700,
                      child: const Icon(Icons.school_outlined),
                    ),
                    title: Text(course.code),
                    subtitle: Text(course.title),
                    trailing: Text(
                      '${course.readiness}%',
                      style: const TextStyle(
                        color: AppColours.green700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CourseScreen(course: course)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (tools.isNotEmpty) ...[
            const SectionHeader(title: 'Student tools'),
            const SizedBox(height: 9),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tools.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .92,
              ),
              itemBuilder: (context, index) {
                final tool = tools.elementAt(index);
                return ToolTile(
                  tool: tool,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ToolScreen(tool: tool)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          if (resources.isNotEmpty) ...[
            const SectionHeader(title: 'Resources and guides'),
            const SizedBox(height: 9),
            ...resources.map(
              (resource) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ResourceCard(
                  resource: resource,
                  onTap: () {},
                  onSave: () => widget.controller.toggleSaved(resource),
                ),
              ),
            ),
          ],
          if (courses.isEmpty && tools.isEmpty && resources.isEmpty)
            const _NoResults(),
        ],
      ),
    );
  }

  void _openJourney() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _JourneySheet(),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColours.green900,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: AppColours.green700,
              child: Icon(Icons.route_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOUN Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Your guided path from admission to graduation.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ],
        ),
      );
}

class _JourneySheet extends StatelessWidget {
  const _JourneySheet();

  @override
  Widget build(BuildContext context) {
    const stages = [
      ('Admission', Icons.workspace_premium_outlined),
      ('Registration and fees', Icons.how_to_reg_outlined),
      ('Course materials', Icons.menu_book_outlined),
      ('TMA', Icons.task_alt_outlined),
      ('Exam preparation', Icons.quiz_outlined),
      ('Results and CGPA', Icons.insights_outlined),
      ('Graduation', Icons.celebration_outlined),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your NOUN Journey',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Every stage connects to the right NOUN Update tools and resources.',
              ),
              const SizedBox(height: 16),
              ...stages.indexed.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColours.mint,
                    foregroundColor: AppColours.green700,
                    child: Icon(entry.$2.$2),
                  ),
                  title: Text('${entry.$1 + 1}. ${entry.$2.$1}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppColours.green700),
            SizedBox(height: 12),
            Text(
              'No matching NOUN resource yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            SizedBox(height: 5),
            Text('Try a course code or a shorter search phrase.'),
          ],
        ),
      );
}

