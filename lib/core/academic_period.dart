class AcademicPeriod {
  const AcademicPeriod({required this.year, required this.part});

  final int year;
  final int part;

  factory AcademicPeriod.forDate(DateTime localDate) => AcademicPeriod(
        year: localDate.year,
        part: localDate.month <= 6 ? 1 : 2,
      );

  String get sessionKey => '${year}_$part';
  String get semesterLabel => part == 1 ? 'First Semester' : 'Second Semester';
  String get displayLabel => '$sessionKey · $semesterLabel';
}
