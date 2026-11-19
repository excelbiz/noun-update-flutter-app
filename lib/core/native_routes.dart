/// IDs are data, never URLs. The same resolver handles bundled and remote rows.
enum StudentRoute {
  materials, courseSummary, examSummary, studyHub, timetable, calendar,
  fees, cgpa, wallet, courses, home, account, tools, premium, feed, info,
}

StudentRoute? studentRoute(String id) => switch (id) {
  'courses' || 'course-materials' => StudentRoute.materials,
  'course-summary' => StudentRoute.courseSummary,
  'exam-summary' => StudentRoute.examSummary,
  'study-hub' || 'study-planner' => StudentRoute.studyHub,
  'personalized-timetable' || 'personalised-timetable' => StudentRoute.timetable,
  'calendar' => StudentRoute.calendar,
  'fees' || 'fee-check' => StudentRoute.fees,
  'cgpa-calculator' => StudentRoute.cgpa,
  'wallet' => StudentRoute.wallet,
  'my-courses' => StudentRoute.courses,
  'dashboard' => StudentRoute.home,
  'my-account' => StudentRoute.account,
  'search' || 'noun-student-resource-centre' => StudentRoute.tools,
  'premium' => StudentRoute.premium,
  'news' || 'guides' || 'scholarships' || 'career' || 'career-hub' || 'blog' => StudentRoute.feed,
  'about' || 'about-noun' || 'faqs' || 'privacy-policy' || 'terms-of-use' ||
  'editorial-policy' || 'corrections' || 'sources' || 'advertising' => StudentRoute.info,
  _ => null,
};

String? serviceIdFromInternalAction(String value) {
  if (!RegExp(r'^[a-z][a-z0-9-]{0,79}$').hasMatch(value)) return null;
  return studentRoute(value) == null ? null : value;
}
