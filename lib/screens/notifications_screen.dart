import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({required this.alerts, super.key});

  final List<StudentAlert> alerts;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Your alerts'),
          actions: [
            TextButton(onPressed: () {}, child: const Text('Mark all read')),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Card(
              color: alert.isRead ? Colors.white : AppColours.mint,
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColours.green700,
                  child: Icon(_iconFor(alert.type)),
                ),
                title: Text(alert.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(alert.message),
                ),
                trailing: alert.isRead
                    ? null
                    : const CircleAvatar(
                        radius: 4,
                        backgroundColor: AppColours.green600,
                      ),
                onTap: () {},
              ),
            );
          },
        ),
      );

  IconData _iconFor(String type) => switch (type) {
        'tma' => Icons.task_alt_rounded,
        'study' => Icons.school_rounded,
        'resource' => Icons.auto_stories_rounded,
        _ => Icons.notifications_rounded,
      };
}
