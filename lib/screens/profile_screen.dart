import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.bootstrap!.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColours.mint,
                    foregroundColor: AppColours.green700,
                    child: Text(
                      profile.name.isEmpty ? 'N' : profile.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 3),
                        Text(profile.email),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: profile.isPremium
                                ? const Color(0xFFFFF2D8)
                                : AppColours.mint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.isPremium ? 'Premium member' : 'Free member',
                            style: TextStyle(
                              color: profile.isPremium
                                  ? const Color(0xFF8A5B16)
                                  : AppColours.green700,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Academic identity', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Programme', value: profile.programme),
                  _DetailRow(label: 'Level', value: profile.level),
                  _DetailRow(label: 'Semester', value: profile.semester, isLast: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                _ProfileLink(
                  icon: Icons.notifications_outlined,
                  title: 'Notification settings',
                  subtitle: 'TMA, exam, results and course alerts',
                  onTap: () async {
                    final granted = await NotificationService.requestPermission();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? 'Notifications enabled.'
                              : 'Add the OneSignal App ID to enable notifications.',
                        ),
                      ),
                    );
                  },
                ),
                _ProfileLink(
                  icon: Icons.download_for_offline_outlined,
                  title: 'Offline downloads',
                  subtitle: 'Manage low-data study resources',
                  onTap: () {},
                ),
                _ProfileLink(
                  icon: Icons.support_agent_outlined,
                  title: 'Help and support',
                  subtitle: 'Contact NOUN Update support',
                  onTap: () {},
                ),
                _ProfileLink(
                  icon: Icons.info_outline_rounded,
                  title: 'About NOUN Update',
                  subtitle: 'Version 0.1.0 foundation build',
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColours.danger,
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Color(0xFFF0CACA)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEDF0EE))),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColours.muted)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEDF0EE))),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          leading: Icon(icon, color: AppColours.green700),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}

