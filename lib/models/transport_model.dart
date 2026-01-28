import 'package:cloud_firestore/cloud_firestore.dart';

class TransportModel {
  final String id;
  final String lineName;
  final String departure;
  final String arrival;
  final List<String> stops;
  final List<String> dailyTimes;

  TransportModel({
    required this.id,
    required this.lineName,
    required this.departure,
    required this.arrival,
    required this.stops,
    required this.dailyTimes,
  });

  factory TransportModel.fromMap(String id, Map<String, dynamic> data) {
    return TransportModel(
      id: id,
      lineName: data['lineName'] ?? '',
      departure: data['departure'] ?? '',
      arrival: data['arrival'] ?? '',
      stops: List<String>.from(data['stops'] ?? []),
      dailyTimes: List<String>.from(data['dailyTimes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lineName': lineName,
      'departure': departure,
      'arrival': arrival,
      'stops': stops,
      'dailyTimes': dailyTimes,
    };
  }
}