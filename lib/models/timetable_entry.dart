class TimetableEntry {
  final String day;
  final String course;
  final String code;
  final String instructor;
  final String location;
  final String startTime;
  final String endTime;

  TimetableEntry({
    required this.day,
    required this.course,
    required this.code,
    required this.instructor,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableEntry.fromMap(Map<String, dynamic> data) {
    return TimetableEntry(
      day: data['day'] ?? '',
      course: data['course'] ?? '',
      code: data['code'] ?? '',
      instructor: data['instructor'] ?? '',
      location: data['location'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
    );
  }
}