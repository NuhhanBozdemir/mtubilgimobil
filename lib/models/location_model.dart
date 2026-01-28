import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;      // Firestore doc id
  final String name;    // Konum adı
  final String address; // Adres bilgisi
  final double lat;     // Enlem
  final double lng;     // Boylam

  LocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  // 🔹 Firestore'dan DocumentSnapshot'tan model oluşturma
  factory LocationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      name: data['name'] ?? 'Konum',
      address: data['address'] ?? 'Adres bilgisi yok',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
    );
  }

  // 🔹 Firestore'a kaydetmek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}