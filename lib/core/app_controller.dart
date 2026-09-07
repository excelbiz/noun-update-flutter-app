import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/app_repository.dart';

class AppController extends ChangeNotifier {
  AppController(this._repository);

  final AppRepository _repository;

  AppBootstrap? bootstrap;
  bool isLoading = true;
  bool isUsingDemoData = false;
  String? loadError;
  int selectedTab = 0;

  Future<void> initialise() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final result = await _repository.loadBootstrap();
      bootstrap = result.data;
      isUsingDemoData = result.isDemo;
    } on Object {
      loadError = 'NOUN Update could not load your dashboard.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  void toggleSaved(LearningResource resource) {
    final current = bootstrap;
    if (current == null) return;
    final items = [...current.saved];
    final index = items.indexWhere((item) => item.id == resource.id);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.insert(0, resource);
    }
    bootstrap = AppBootstrap(
      profile: current.profile,
      dashboard: current.dashboard,
      wallet: current.wallet,
      saved: items,
      alerts: current.alerts,
    );
    notifyListeners();
  }
}
