import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../widgets/shared_widgets.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.bootstrap!.saved;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: items.isEmpty
          ? const _EmptySaved()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Text(
                  'Your resources stay organised and can later be made available offline.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: const [
                    Chip(label: Text('All')),
                    Chip(label: Text('Guides')),
                    Chip(label: Text('Past questions')),
                    Chip(label: Text('Summaries')),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ResourceCard(
                      resource: resource,
                      onTap: () {},
                      onSave: () => controller.toggleSaved(resource),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 62, color: AppColours.green700),
              SizedBox(height: 15),
              Text(
                'Nothing saved yet',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text('Bookmark useful materials, summaries, questions and guides.'),
            ],
          ),
        ),
      );
}
