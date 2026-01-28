import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location_model.dart';

class MapAdminPage extends StatefulWidget {
  const MapAdminPage({super.key});

  @override
  State<MapAdminPage> createState() => _MapAdminPageState();
}

class _MapAdminPageState extends State<MapAdminPage> {
  final mapController = MapController();
  String selectedLayer = "Normal Harita";
  bool addMode = false; // 🔹 Konum ekleme modu açık/kapalı

  final Map<String, String> mapLayers = {
    "Normal Harita":
    "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
    "Uydu Harita":
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
  };

  Future<void> _addLocationDialog(LatLng tappedPoint) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yeni Konum Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Ad"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Adres"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final address = addressController.text.trim();
              if (name.isNotEmpty && address.isNotEmpty) {
                await FirebaseFirestore.instance.collection('locations').add({
                  'name': name,
                  'address': address,
                  'lat': tappedPoint.latitude,
                  'lng': tappedPoint.longitude,
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _showMarkerDialog(LocationModel loc) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Adres: ${loc.address}"),
            const SizedBox(height: 8),
            Text("Lat: ${loc.lat}"),
            Text("Lng: ${loc.lng}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('locations')
                  .doc(loc.id)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🗺️ Harita Yönetimi"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(addMode ? Icons.close : Icons.add_location_alt),
            onPressed: () {
              setState(() {
                addMode = !addMode; // 🔹 Konum ekleme modunu aç/kapat
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('locations').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data!.docs
              .map((doc) => LocationModel.fromDoc(doc))
              .toList();

          LatLng initialLocation = const LatLng(38.325196, 38.205567);
          if (locations.isNotEmpty) {
            initialLocation = LatLng(locations.first.lat, locations.first.lng);
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: initialLocation,
                  initialZoom: 13,
                  onTap: (tapPosition, latlng) {
                    if (addMode) {
                      _addLocationDialog(
                          latlng); // 🔹 sadece addMode açıkken ekleme yapılır
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapLayers[selectedLayer]!,
                    subdomains: selectedLayer == "Normal Harita"
                        ? const ['a', 'b', 'c', 'd']
                        : const [],
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: locations.map((loc) {
                      return Marker(
                        point: LatLng(loc.lat, loc.lng),
                        child: GestureDetector(
                          onTap: () => _showMarkerDialog(
                              loc), // 🔹 marker’a tıklanınca kutu açılır
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 30),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 🔹 Dropdown (Normal / Uydu)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: selectedLayer,
                    underline: const SizedBox(),
                    items: mapLayers.keys.map((layer) {
                      return DropdownMenuItem(value: layer, child: Text(layer));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedLayer = val!),
                  ),
                ),
              ),

              // 🔹 Sağ alt köşeye zoom butonları
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "zoomInAdmin",
                      mini: true,
                      onPressed: () {
                        mapController.move(
                          mapController.camera.center,
                          mapController.camera.zoom + 1,
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: "zoomOutAdmin",
                      mini: true,
                      onPressed: () {
                        mapController.move(
                          mapController.camera.center,
                          mapController.camera.zoom - 1,
                        );
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}