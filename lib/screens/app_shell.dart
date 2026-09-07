import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';
import 'wallet_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.bootstrap!;
    final pages = [
      HomeScreen(controller: controller),
      ExploreScreen(controller: controller),
      WalletScreen(controller: controller),
      SavedScreen(controller: controller),
      ProfileScreen(controller: controller),
    ];

    return Scaffold(
      body: IndexedStack(index: controller.selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: controller.selectedTab,
        onDestinationSelected: controller.selectTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Explore',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: data.saved.isNotEmpty,
              label: Text('${data.saved.length}'),
              backgroundColor: AppColours.green600,
              child: const Icon(Icons.bookmark_border_rounded),
            ),
            selectedIcon: const Icon(Icons.bookmark_rounded),
            label: 'Saved',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
