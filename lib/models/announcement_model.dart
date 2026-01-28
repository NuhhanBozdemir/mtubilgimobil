import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String? imageUrl; // 🔹 yeni alan

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.imageUrl,
  });

  factory AnnouncementModel.fromMap(String id, Map<String, dynamic> data) {
    return AnnouncementModel(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'], // 🔹 ekleme
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl, // 🔹 ekleme
    };
  }
}