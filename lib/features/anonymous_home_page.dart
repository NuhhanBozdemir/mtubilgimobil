import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart'; // ✅ Tarih formatı için eklendi
import '../models/location_model.dart';

class AnonymousHomePage extends StatelessWidget {
  final String pageType;
  // "announcements", "timetable", "canteen", "transport", "events", "exams", "feedback", "map"

  const AnonymousHomePage({super.key, required this.pageType});

  // 🔹 Türkçe başlık eşleştirmeleri
  static const Map<String, String> pageTitles = {
    "announcements": "📢 Duyurular",
    "timetable": "📅 Ders Programı",
    "canteen": "🍽️ Yemekhane",
    "transport": "🚌 Ulaşım",
    "events": "🎉 Etkinlikler",
    "exams": "📖 Sınav Takvimi",
    "feedback": "📝 Geri Bildirim",
    "map": "🗺️ Harita",
  };

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (pageType) {
      case "announcements":
        content = _buildAnnouncements(context);
        break;
      case "timetable":
        content = _buildTimetable(context);
        break;
      case "canteen":
        content = _buildCanteen(context);
        break;
      case "transport":
        content = _buildTransport(context);
        break;
      case "events":
        content = _buildEvents(context);
        break;
      case "exams":
        content = _buildExams(context);
        break;
      case "feedback":
        content = _buildFeedback(context);
        break;
      case "map":
        content = _buildMap(context);
        break;
      default:
        content = const Center(child: Text("Sayfa bulunamadı"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[pageType] ?? "Anonim"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  // 📢 Duyurular ekranı
  Widget _buildAnnouncements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "📢 Duyurular",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Henüz duyuru yok"));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: const Icon(Icons.campaign),
                      title: Text(data['title'] ?? 'Başlıksız'),
                      subtitle: Text("${date.day}.${date.month}.${date.year}"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data['imageUrl'] != null &&
                                      (data['imageUrl'] as String).isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 200,
                                        child: Image.network(
                                          data['imageUrl'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    data['title'] ?? 'Başlıksız',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['content'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${date.day}.${date.month}.${date.year}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 🗺️ Harita Ekranı
  Widget _buildMap(BuildContext context) {
    final mapController = MapController();

    // 🔹 Tile URL seçenekleri
    final Map<String, String> mapLayers = {
      "Normal Harita":
      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
      "Uydu Harita":
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    };

    String selectedLayer = "Normal Harita";

    return StatefulBuilder(
      builder: (context, setState) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('locations').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            LatLng initialLocation = const LatLng(38.325196, 38.205567); // MTÜ default
            List<LocationModel> locations = [];

            if (docs.isNotEmpty) {
              locations = docs.map((doc) => LocationModel.fromDoc(doc)).toList();
              initialLocation = LatLng(locations.first.lat, locations.first.lng);
            }

            return Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialLocation,
                    initialZoom: 13,
                  ),
                  children: [
                    // 🔹 Seçilen tile katmanı
                    TileLayer(
                      urlTemplate: mapLayers[selectedLayer]!,
                      subdomains: selectedLayer == "Normal Harita"
                          ? const ['a', 'b', 'c', 'd']
                          : const [],
                      userAgentPackageName: 'com.example.app',
                    ),

                    // 🔹 Adminin tanımladığı markerlar
                    MarkerLayer(
                      markers: locations.map((loc) {
                        return Marker(
                          point: LatLng(loc.lat, loc.lng),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(loc.name),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Adres: ${loc.address}"), // ✅ Adres bilgisi
                                      const SizedBox(height: 8),
                                      Text("Lat: ${loc.lat}"),
                                      Text("Lng: ${loc.lng}"),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Kapat"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // 🔹 Üstte Dropdown menüsü
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: selectedLayer,
                      underline: const SizedBox(),
                      items: mapLayers.keys.map((layer) {
                        return DropdownMenuItem(
                          value: layer,
                          child: Text(layer),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedLayer = val);
                        }
                      },
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
                        heroTag: "zoomInAnon",
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
                        heroTag: "zoomOutAnon",
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
        );
      },
    );
  }

  // 📅 Ders Programı ekranı
  Widget _buildTimetable(BuildContext context) {
    String? selectedDepartment;
    int currentDayIndex = 0; // 0= Pazartesi, 1=Salı, ..., 4=Cuma
    final days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"];

    return StatefulBuilder(
      builder: (context, setState) {
        void _nextDay() {
          setState(() {
            currentDayIndex = (currentDayIndex + 1) % days.length;
          });
        }

        void _previousDay() {
          setState(() {
            currentDayIndex = (currentDayIndex - 1 + days.length) % days.length;
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Başlık ve departman seçimi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    "📅 Ders Programı",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Expanded( // 🔹 Overflow fix: Expanded ile sarmaladık
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('departments')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final departments = snapshot.data!.docs
                            .map((d) => d['name'] as String)
                            .toList();
                        final safeValue = (selectedDepartment != null &&
                            departments.contains(selectedDepartment))
                            ? selectedDepartment
                            : null;
                        return DropdownButtonFormField<String>(
                          value: safeValue,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          hint: const Text("Departman Seç"),
                          items: departments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => selectedDepartment = val),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Gün seçimi (sağ/sol oklarla)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: _previousDay, icon: const Icon(Icons.arrow_back)),
                  Text(
                    days[currentDayIndex],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(onPressed: _nextDay, icon: const Icon(Icons.arrow_forward)),
                ],
              ),
            ),

            // 🔹 Ders listesi (kartlara hiç dokunmadım)
            Expanded(
              child: selectedDepartment == null
                  ? const Center(child: Text("Lütfen departman seçiniz"))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('departments')
                    .doc(selectedDepartment)
                    .collection('timetable')
                    .where('day', isEqualTo: days[currentDayIndex])
                    .orderBy('startTime')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Bu gün için ders programı yok"));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.book, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${data['code']} — ${data['course']}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(data['instructor'],
                                      style: const TextStyle(color: Colors.black87)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.meeting_room, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(data['location'],
                                      style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Theme.of(context).colorScheme.primary),
                                    ),
                                    child: Text(
                                      "${data['startTime']} - ${data['endTime']}",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  // 🍽️ Yemekhane ekranı
  Widget _buildCanteen(BuildContext context) {
    DateTime currentDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setState) {
        Future<DocumentSnapshot?> _getMenuForDate(DateTime date) async {
          // ✅ Firestore'daki day alanı "26 Ocak 2026" formatında tutuluyor
          final formattedDay = DateFormat("d MMMM yyyy", "tr_TR").format(date);
          final snapshot = await FirebaseFirestore.instance
              .collection('canteen')
              .where('day', isEqualTo: formattedDay)
              .limit(1)
              .get();
          return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
        }

        void _nextDay() {
          setState(() => currentDate = currentDate.add(const Duration(days: 1)));
        }

        void _previousDay() {
          setState(() => currentDate = currentDate.subtract(const Duration(days: 1)));
        }

        final formattedDay = DateFormat("d MMMM yyyy", "tr_TR").format(currentDate);
        final dayName = DateFormat("EEEE", "tr_TR").format(currentDate); // ✅ Gün adı

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "🍽️ Menü",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // 🔹 Tarih üstte ortada, yanında sağ/sol oklar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: _previousDay, icon: const Icon(Icons.arrow_back)),
                  Column(
                    children: [
                      Text(
                        formattedDay,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        dayName, // ✅ Gün adı gösteriliyor
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(onPressed: _nextDay, icon: const Icon(Icons.arrow_forward)),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<DocumentSnapshot?>(
                future: _getMenuForDate(currentDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text("Bu gün için menü bulunamadı"));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCanteenCard("Çorba", data['soup'], Icons.ramen_dining, Colors.orange),
                      _buildCanteenCard("Ana Yemek", data['main'], Icons.restaurant, Colors.green),
                      _buildCanteenCard("Yan Yemek", data['side'], Icons.fastfood, Colors.blue),
                      _buildCanteenCard("Tatlı", data['dessert'], Icons.cake, Colors.pink),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

// 🔹 Modern tasarımlı kart
  Widget _buildCanteenCard(String title, String? value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          value ?? "-",
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  // 🚌 Ulaşım ekranı
  Widget _buildTransport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "🚌 Ulaşım",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transport')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Henüz ulaşım bilgisi yok"));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: Text(data['lineName'] ?? 'Hat'),
                      subtitle: Text("${data['departure']} → ${data['arrival']}"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(data['lineName'] ?? 'Hat'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Kalkış: ${data['departure']}"),
                                  Text("Varış: ${data['arrival']}"),
                                  const SizedBox(height: 12),
                                  const Text("Duraklar:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...((data['stops'] ?? []) as List).map((s) => Text("• $s")),
                                  const SizedBox(height: 12),
                                  const Text("Gün içindeki kalkış saatleri:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: ((data['dailyTimes'] ?? []) as List)
                                        .map<Widget>((t) => Chip(label: Text(t)))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Kapat"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  // 🎉 Etkinlikler ekranı
  Widget _buildEvents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "🎉 Etkinlikler",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Henüz etkinlik yok"));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(data['title'] ?? 'Etkinlik'),
                      subtitle: Text(
                        "${date.day}.${date.month}.${date.year} • ${data['location']}",
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data['imageUrl'] != null &&
                                      (data['imageUrl'] as String).isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 200, // ✅ sabit yükseklik
                                        child: Image.network(
                                          data['imageUrl'],
                                          fit: BoxFit.contain, // 🔹 kırpmadan sığdırır
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    data['title'] ?? 'Etkinlik',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['description'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "${date.day}.${date.month}.${date.year} • ${data['location']}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 📖 Sınav Takvimi ekranı
  Widget _buildExams(BuildContext context) {
    String? selectedDepartment;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "📖 Sınav Takvimi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('departments')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final departments = snapshot.data!.docs
                            .map((d) => d['name'] as String)
                            .toList();
                        final safeValue = (selectedDepartment != null &&
                            departments.contains(selectedDepartment))
                            ? selectedDepartment
                            : null;
                        return DropdownButton<String>(
                          value: safeValue,
                          isExpanded: true,
                          hint: const Text("Departman Seç"),
                          items: departments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => selectedDepartment = val),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedDepartment == null
                    ? null
                    : FirebaseFirestore.instance
                    .collection('departments')
                    .doc(selectedDepartment)
                    .collection('exams')
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text("Henüz sınav bilgisi yok"));
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("Henüz sınav bilgisi yok"));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: const Icon(Icons.school),
                          title: Text("${data['course']} (${data['type']})"),
                          subtitle: Text(
                              "${date.day}.${date.month}.${date.year} • ${data['location']}"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 📝 Geri Bildirim ekranı
  Widget _buildFeedback(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Anonim olarak giriş yaptığınız için geri bildirimde bulunamazsınız.\n\n"
              "Lütfen kayıt olup oturum açın.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent),
        ),
      ),
    );
  }
}