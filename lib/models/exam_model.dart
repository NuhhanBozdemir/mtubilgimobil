import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Timestamp için gerekli

class ExamModel {
  final String id;
  final String course;
  final DateTime date;
  final String location;
  final String type;

  ExamModel({
    required this.id,
    required this.course,
    required this.date,
    required this.location,
    required this.type,
  });

  // Firestore'dan gelen 'date' hem Timestamp hem String/DateTime olabilir → güvenli dönüştürme
  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Unsupported date type: ${value.runtimeType}');
  }

  factory ExamModel.fromMap(String id, Map<String, dynamic> data) {
    return ExamModel(
      id: id,
      course: (data['course'] ?? '').toString(),
      date: _toDate(data['date']),
      location: (data['location'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'course': course,
      'date': Timestamp.fromDate(date), // ✅ Firestore için Timestamp yazıyoruz
      'location': location,
      'type': type,
    };
  }
}