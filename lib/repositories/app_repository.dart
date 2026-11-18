import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import '../models/app_models.dart';

class RepositoryResult<T> {
  const RepositoryResult(this.data, {required this.isDemo});

  final T data;
  final bool isDemo;
}

abstract class AppRepository {
  Future<RepositoryResult<AppBootstrap>> loadBootstrap();
}

class HybridAppRepository implements AppRepository {
  HybridAppRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<RepositoryResult<AppBootstrap>> loadBootstrap() async {
    try {
      final payload = await _apiClient.getJson('/app/bootstrap');
      final rawData = payload['data'];
      if (rawData is! Map<String, dynamic>) {
        throw const ApiException('Bootstrap data is missing.');
      }
      return RepositoryResult(_fromApi(rawData), isDemo: false);
    } on Object {
      if (!AppConfig.enableDemoFallback) rethrow;
      return RepositoryResult(DemoData.bootstrap, isDemo: true);
    }
  }

  AppBootstrap _fromApi(Map<String, dynamic> data) {
    final profileMap = data['profile'] as Map<String, dynamic>? ?? const {};
    final walletMap = data['wallet'] as Map<String, dynamic>? ?? const {};
    final demo = DemoData.bootstrap;
    return AppBootstrap(
      profile: StudentProfile.fromJson(profileMap),
      dashboard: demo.dashboard,
      wallet: WalletSnapshot(
        balanceKobo: walletMap['balance_kobo'] as int? ?? 0,
        transactions: demo.wallet.transactions,
      ),
      saved: demo.saved,
      alerts: demo.alerts,
    );
  }
}

class AppCatalogue {
  const AppCatalogue._();

  static const tools = <AppTool>[
    AppTool(
      id: 'result',
      label: 'Check Result',
      subtitle: 'View and analyse results',
      icon: Icons.fact_check_outlined,
    ),
    AppTool(
      id: 'materials',
      label: 'Course Materials',
      subtitle: 'Official courseware library',
      icon: Icons.menu_book_rounded,
    ),
    AppTool(
      id: 'past-questions',
      label: 'Past Questions',
      subtitle: 'Search by course and year',
      icon: Icons.description_outlined,
    ),
    AppTool(
      id: 'mock',
      label: 'Mock Test',
      subtitle: 'Timed exam practice',
      icon: Icons.quiz_outlined,
      premium: true,
    ),
    AppTool(
      id: 'study-hub',
      label: 'Study Hub',
      subtitle: 'Study, practise and review',
      icon: Icons.school_outlined,
      premium: true,
    ),
    AppTool(
      id: 'ai-tutor',
      label: 'AI Tutor',
      subtitle: 'Course-grounded explanations',
      icon: Icons.smart_toy_outlined,
      premium: true,
    ),
    AppTool(
      id: 'summaries',
      label: 'Summaries',
      subtitle: 'Course and exam summaries',
      icon: Icons.auto_stories_outlined,
      premium: true,
    ),
    AppTool(
      id: 'fee-checker',
      label: 'Fees Checker',
      subtitle: 'Plan registration costs',
      icon: Icons.calculate_outlined,
    ),
    AppTool(
      id: 'tma',
      label: 'TMA Archive',
      subtitle: 'Past TMA and explanations',
      icon: Icons.task_alt_outlined,
      premium: true,
    ),
    AppTool(
      id: 'admission',
      label: 'Admission',
      subtitle: 'Eligibility and programmes',
      icon: Icons.workspace_premium_outlined,
    ),
    AppTool(
      id: 'cgpa',
      label: 'CGPA Calculator',
      subtitle: 'Track academic performance',
      icon: Icons.insights_outlined,
    ),
    AppTool(
      id: 'graduation',
      label: 'Graduation Tracker',
      subtitle: 'Units completed and remaining',
      icon: Icons.celebration_outlined,
    ),
  ];

  static const resources = <LearningResource>[
    LearningResource(
      id: 'res-acc210-material',
      title: 'ACC210 Official Course Material',
      category: 'Course materials',
      description: 'Auditing I courseware, organised by module and unit.',
      icon: Icons.menu_book_rounded,
      courseCode: 'ACC210',
    ),
    LearningResource(
      id: 'res-acc210-summary',
      title: 'ACC210 Smart Course Summary',
      category: 'Summaries',
      description: 'Explained course concepts for focused POP preparation.',
      icon: Icons.auto_stories_outlined,
      courseCode: 'ACC210',
      isPremium: true,
    ),
    LearningResource(
      id: 'res-gst302-pq',
      title: 'GST302 Past Questions: 2023–2026',
      category: 'Past questions',
      description: 'Searchable questions grouped by semester and topic.',
      icon: Icons.description_outlined,
      courseCode: 'GST302',
    ),
    LearningResource(
      id: 'res-calendar',
      title: 'NOUN 2026 Academic Calendar',
      category: 'Documents',
      description: 'Important dates and semester milestones.',
      icon: Icons.calendar_month_outlined,
    ),
    LearningResource(
      id: 'res-exam-guide',
      title: 'How to Prepare for NOUN Exams',
      category: 'Guides',
      description: 'A practical study and exam-day guide.',
      icon: Icons.lightbulb_outline_rounded,
    ),
  ];
}

class DemoData {
  const DemoData._();

  static final bootstrap = AppBootstrap(
    profile: const StudentProfile(
      name: 'Success Chinedu',
      email: 'success@example.com',
      programme: 'B.Sc Accounting',
      level: '200 Level',
      semester: '2026_2 Semester',
      isPremium: true,
    ),
    dashboard: const DashboardSnapshot(
      readiness: 72,
      nextExamCode: 'ACC210',
      daysToNextExam: 14,
      recommendation: 'Study ACC214 Unit 3 for 30 minutes',
      courses: [
        CourseProgress(
          code: 'ACC210',
          title: 'Auditing I',
          materialReady: true,
          tmaReady: true,
          pastQuestionsReady: true,
          summaryReady: true,
          readiness: 82,
          weakTopic: 'Audit evidence',
        ),
        CourseProgress(
          code: 'ACC214',
          title: 'Introduction to Cost Accounting',
          materialReady: true,
          tmaReady: false,
          pastQuestionsReady: true,
          summaryReady: true,
          readiness: 54,
          weakTopic: 'Process costing',
        ),
        CourseProgress(
          code: 'GST302',
          title: 'Business Creation and Growth',
          materialReady: true,
          tmaReady: true,
          pastQuestionsReady: true,
          summaryReady: true,
          readiness: 91,
          weakTopic: 'Financing decisions',
        ),
      ],
    ),
    wallet: WalletSnapshot(
      balanceKobo: 1245000,
      transactions: [
        WalletTransaction(
          title: 'Wallet funding',
          date: DateTime(2026, 9, 5, 9, 15),
          amountKobo: 500000,
        ),
        WalletTransaction(
          title: 'Mock test access',
          date: DateTime(2026, 9, 4, 10, 30),
          amountKobo: -50000,
        ),
        WalletTransaction(
          title: 'Course summary',
          date: DateTime(2026, 9, 2, 14, 20),
          amountKobo: -100000,
        ),
      ],
    ),
    saved: const [
      LearningResource(
        id: 'saved-exam-guide',
        title: 'How to Prepare for NOUN Exams',
        category: 'Guides',
        description: 'A practical study and exam-day guide.',
        icon: Icons.lightbulb_outline_rounded,
        isSaved: true,
      ),
      LearningResource(
        id: 'saved-calendar',
        title: 'NOUN 2026 Academic Calendar',
        category: 'Documents',
        description: 'Important dates and semester milestones.',
        icon: Icons.calendar_month_outlined,
        isSaved: true,
      ),
      LearningResource(
        id: 'saved-acc210',
        title: 'ACC210 Smart Course Summary',
        category: 'Summaries',
        description: 'Explained course concepts for focused preparation.',
        icon: Icons.auto_stories_outlined,
        courseCode: 'ACC210',
        isSaved: true,
        isPremium: true,
      ),
    ],
    alerts: [
      StudentAlert(
        id: 'alert-1',
        title: 'TMA update',
        message: 'Two registered courses have new TMA activity.',
        type: 'tma',
        createdAt: DateTime(2026, 9, 7, 8, 0),
        isRead: false,
      ),
      StudentAlert(
        id: 'alert-2',
        title: 'Study recommendation',
        message: 'ACC214 needs attention before your next mock attempt.',
        type: 'study',
        createdAt: DateTime(2026, 9, 6, 19, 30),
        isRead: false,
      ),
      StudentAlert(
        id: 'alert-3',
        title: 'New course resource',
        message: 'A new GST302 past-question set is available.',
        type: 'resource',
        createdAt: DateTime(2026, 9, 5, 13, 10),
        isRead: true,
      ),
    ],
  );
}

