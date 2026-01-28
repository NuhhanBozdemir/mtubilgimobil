import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableModel {
  final String id;
  final String day;
  final String course;
  final String code;
  final String instructor;
  final String location;
  final String startTime;
  final String endTime;

  TimetableModel({
    required this.id,
    required this.day,
    required this.course,
    required this.code,
    required this.instructor,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableModel.fromMap(String id, Map<String, dynamic> data) {
    return TimetableModel(
      id: id,
      day: data['day'] ?? '',
      course: data['course'] ?? '',
      code: data['code'] ?? '',
      instructor: data['instructor'] ?? '',
      location: data['location'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'course': course,
      'code': code,
      'instructor': instructor,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}