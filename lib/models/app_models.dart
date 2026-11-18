import 'package:flutter/material.dart';

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.email,
    required this.programme,
    required this.level,
    required this.semester,
    required this.isPremium,
  });

  final String name;
  final String email;
  final String programme;
  final String level;
  final String semester;
  final bool isPremium;

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        name: json['name'] as String? ?? 'NOUN Student',
        email: json['email'] as String? ?? '',
        programme: json['programme'] as String? ?? 'Select programme',
        level: json['level']?.toString() ?? '100',
        semester: json['semester'] as String? ?? 'Current semester',
        isPremium: json['premium'] as bool? ?? false,
      );
}

class CourseProgress {
  const CourseProgress({
    required this.code,
    required this.title,
    required this.materialReady,
    required this.tmaReady,
    required this.pastQuestionsReady,
    required this.summaryReady,
    required this.readiness,
    required this.weakTopic,
  });

  final String code;
  final String title;
  final bool materialReady;
  final bool tmaReady;
  final bool pastQuestionsReady;
  final bool summaryReady;
  final int readiness;
  final String weakTopic;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.readiness,
    required this.nextExamCode,
    required this.daysToNextExam,
    required this.recommendation,
    required this.courses,
  });

  final int readiness;
  final String nextExamCode;
  final int daysToNextExam;
  final String recommendation;
  final List<CourseProgress> courses;
}

class AppTool {
  const AppTool({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.premium = false,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool premium;
}

class LearningResource {
  const LearningResource({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    this.courseCode,
    this.isSaved = false,
    this.isPremium = false,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final String? courseCode;
  final bool isSaved;
  final bool isPremium;
}

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.date,
    required this.amountKobo,
  });

  final String title;
  final DateTime date;
  final int amountKobo;
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.balanceKobo,
    required this.transactions,
  });

  final int balanceKobo;
  final List<WalletTransaction> transactions;
}

class StudentAlert {
  const StudentAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
}

class AppBootstrap {
  const AppBootstrap({
    required this.profile,
    required this.dashboard,
    required this.wallet,
    required this.saved,
    required this.alerts,
  });

  final StudentProfile profile;
  final DashboardSnapshot dashboard;
  final WalletSnapshot wallet;
  final List<LearningResource> saved;
  final List<StudentAlert> alerts;
}

