import 'package:cloud_firestore/cloud_firestore.dart';

class CanteenModel {
  final String id;
  final String day;
  final String soup;
  final String main;
  final String side;
  final String dessert;

  CanteenModel({
    required this.id,
    required this.day,
    required this.soup,
    required this.main,
    required this.side,
    required this.dessert,
  });

  factory CanteenModel.fromMap(String id, Map<String, dynamic> data) {
    return CanteenModel(
      id: id,
      day: data['day'] ?? '',
      soup: data['soup'] ?? '',
      main: data['main'] ?? '',
      side: data['side'] ?? '',
      dessert: data['dessert'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'soup': soup,
      'main': main,
      'side': side,
      'dessert': dessert,
    };
  }
}