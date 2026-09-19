import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';

class ToolScreen extends StatelessWidget {
  const ToolScreen({required this.tool, super.key, this.courseCode});

  final AppTool tool;
  final String? courseCode;

  @override
  Widget build(BuildContext context) {
    final content = switch (tool.id) {
      'result' => const _ResultCheckerPreview(),
      'fee-checker' => const _FeeCheckerPreview(),
      'ai-tutor' => _AiTutorPreview(courseCode: courseCode),
      _ => _GenericToolPreview(tool: tool, courseCode: courseCode),
    };
    return Scaffold(
      appBar: AppBar(title: Text(tool.label)),
      body: content,
    );
  }
}

class _ToolIntro extends StatelessWidget {
  const _ToolIntro({required this.tool, this.courseCode});

  final AppTool tool;
  final String? courseCode;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColours.green900, AppColours.green700],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: .14),
              foregroundColor: Colors.white,
              child: Icon(tool.icon),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseCode == null ? tool.label : '$courseCode ${tool.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GenericToolPreview extends StatelessWidget {
  const _GenericToolPreview({required this.tool, this.courseCode});

  final AppTool tool;
  final String? courseCode;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ToolIntro(tool: tool, courseCode: courseCode),
          const SizedBox(height: 18),
          TextField(
            decoration: InputDecoration(
              hintText: courseCode ?? 'Enter a course code, e.g. ACC210',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Native module ready for integration',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'The screen, secure API route and premium guard will connect to the corresponding NOUN Update service.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Waiting for the production API endpoint.')),
            ),
            child: const Text('Continue'),
          ),
        ],
      );
}

class _ResultCheckerPreview extends StatefulWidget {
  const _ResultCheckerPreview();

  @override
  State<_ResultCheckerPreview> createState() => _ResultCheckerPreviewState();
}

class _ResultCheckerPreviewState extends State<_ResultCheckerPreview> {
  String programme = 'Undergraduate';
  String year = '2026';
  String semester = 'Second Semester';

  @override
  Widget build(BuildContext context) {
    const tool = AppTool(
      id: 'result',
      label: 'Check Result',
      subtitle: 'Securely retrieve and analyse your result',
      icon: Icons.fact_check_outlined,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _ToolIntro(tool: tool),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: programme,
                  decoration: const InputDecoration(labelText: 'Programme type'),
                  items: const [
                    DropdownMenuItem(value: 'Undergraduate', child: Text('Undergraduate')),
                    DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate')),
                  ],
                  onChanged: (value) => setState(() => programme = value!),
                ),
                const SizedBox(height: 12),
                const TextField(
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Matriculation number',
                    hintText: 'Enter your matriculation number',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: year,
                  decoration: const InputDecoration(labelText: 'Academic year'),
                  items: const [
                    DropdownMenuItem(value: '2026', child: Text('2026')),
                    DropdownMenuItem(value: '2025', child: Text('2025')),
                    DropdownMenuItem(value: '2024', child: Text('2024')),
                  ],
                  onChanged: (value) => setState(() => year = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: semester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: const [
                    DropdownMenuItem(value: 'First Semester', child: Text('First Semester')),
                    DropdownMenuItem(value: 'Second Semester', child: Text('Second Semester')),
                  ],
                  onChanged: (value) => setState(() => semester = value!),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Result API integration is pending.')),
                    ),
                    child: const Text('Check result'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.shield_outlined, color: AppColours.green700),
            title: Text('Privacy first'),
            subtitle: Text('Result credentials are not stored in analytics or notifications.'),
          ),
        ),
      ],
    );
  }
}

class _FeeCheckerPreview extends StatefulWidget {
  const _FeeCheckerPreview();

  @override
  State<_FeeCheckerPreview> createState() => _FeeCheckerPreviewState();
}

class _FeeCheckerPreviewState extends State<_FeeCheckerPreview> {
  final controller = TextEditingController(text: '18');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tool = AppTool(
      id: 'fee-checker',
      label: 'Fees Checker',
      subtitle: 'Plan your semester registration cost',
      icon: Icons.calculate_outlined,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _ToolIntro(tool: tool),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Registered units',
                    suffixText: 'units',
                  ),
                ),
                const SizedBox(height: 14),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Add course codes',
                    hintText: 'ACC210, GST302, ECO212',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('The live fees database will calculate this total.'),
                      ),
                    ),
                    child: const Text('Calculate fees'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AiTutorPreview extends StatelessWidget {
  const _AiTutorPreview({this.courseCode});

  final String? courseCode;

  @override
  Widget build(BuildContext context) {
    final code = courseCode ?? 'your course';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 22),
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColours.mint,
                child: Icon(Icons.smart_toy_rounded, size: 52, color: AppColours.green700),
              ),
              const SizedBox(height: 18),
              Text(
                'Your $code AI Tutor',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 7),
              const Text(
                'Answers are grounded in the selected NOUN course material.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...[
                'Explain the current unit like I am a beginner',
                'Test me with 10 practice questions',
                'Show important concepts in this unit',
                'Compare this topic with past questions',
              ].map(
                (prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(15),
                      side: const BorderSide(color: Color(0xFFDCE7E1)),
                    ),
                    child: Text(prompt),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ask about $code…',
                suffixIcon: IconButton.filled(
                  onPressed: () {},
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

