import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'guest_feedback_form.dart';
import 'dart:convert'; // 🔹 Base64 decode için
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  String? selectedDepartment;
  String currentPage = "menu";
  final user = FirebaseAuth.instance.currentUser;
  String displayName = "Misafir"; // ✅ yeni değişken

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadUserName(); // ✅ uygulama açılırken isim yüklenecek
    _setupLocalNotifications();
  }

  Future<void> _loadUserName() async {
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (snapshot.exists) {
        setState(() {
          displayName = snapshot.data()?['name'] ?? "Misafir";
        });
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    // 🔹 Local notification ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);

    // 🔹 Foreground bildirim dinleyici
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          0,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'guest_channel',
              'Misafir Bildirimleri',
              channelDescription: 'Misafir ekranı için bildirimler',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? "Email yok";

    return Scaffold(
        appBar: AppBar(
        centerTitle: true,
        title: const Text(
        "MTÜ Bilgi Mobil",
        style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
    ),
    ),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Colors.white,
    elevation: 4,
    automaticallyImplyLeading: currentPage != "menu",
    leading: currentPage != "menu"
    ? IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => setState(() => currentPage = "menu"),
    )
        : null,
    ),

    // 🔹 Sosyal medya bar sadece menüde görünsün
    bottomNavigationBar: currentPage == "menu"
    ? Container(
    color: Colors.grey.shade400,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    IconButton(
    icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.blue),
    onPressed: () => _launchUrl("https://www.facebook.com/malatyaturgutozaledu/?locale=tr_TR"),
    ),
    IconButton(
    icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.purple),
    onPressed: () => _launchUrl("https://www.instagram.com/malatyaturgutozaledu/"),
    ),
    IconButton(
    icon: const FaIcon(FontAwesomeIcons.xTwitter, color: Colors.lightBlue),
    onPressed: () => _launchUrl("https://x.com/MTU_ozaledu"),
    ),
    IconButton(
    icon: const FaIcon(FontAwesomeIcons.linkedin, color: Colors.indigo),
    onPressed: () => _launchUrl("https://tr.linkedin.com/school/malatya-turgut-ozal-universitesi/"),
    ),
    IconButton(
    icon: const FaIcon(FontAwesomeIcons.youtube, color: Colors.red),
    onPressed: () => _launchUrl("https://www.youtube.com/c/MalatyaTurgutOzalUniversitesi/null"),
    ),
    ],
    ),
    )
        : null,

    body: currentPage == "menu"
    ? Column(
    children: [
    // 🔹 Hoş geldin kutusu AppBar’ın altında
    Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [
    Theme.of(context).colorScheme.primary,
    Theme.of(context).colorScheme.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    borderRadius: const BorderRadius.only(
    bottomLeft: Radius.circular(24),
    bottomRight: Radius.circular(24),
    ),
    ),
    child: Row(
    children: [
    CircleAvatar(
    radius: 28,
    backgroundColor: Colors.white,
    child: Icon(Icons.person,
    size: 32, color: Theme.of(context).colorScheme.primary),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Text(
    "Hoş geldin $displayName 🎉",
    style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    ),
    IconButton(
    icon: const Icon(Icons.info_outline, color: Colors.white),
    onPressed: () {
    showDialog(
    context: context,
    builder: (_) => Dialog(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [
    Theme.of(context).colorScheme.primary,
    Theme.of(context).colorScheme.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    ),
    ),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const Text(
    "Bilgileriniz",
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    IconButton(
    icon: const Icon(Icons.close, color: Colors.white),
    onPressed: () => Navigator.pop(context),
    ),
    ],
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    ListTile(
    leading: const Icon(Icons.person, color: Colors.blue),
    title: Text("İsim: $displayName"),
    ),
    ListTile(
    leading: const Icon(Icons.email, color: Colors.red),
    title: Text("Email: $email"),
    ),
    ListTile(
    leading: const Icon(Icons.person_outline, color: Colors.purple),
    title: const Text("Rol: Misafir"),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
    },
    ),
    ],
    ),
    ),
      // 🔹 Menü kartları
      Expanded(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(context, Icons.campaign, "Duyurular", "announcements_guest"),
            _buildMenuCard(context, Icons.event, "Etkinlikler", "events_guest"),
            _buildMenuCard(context, Icons.restaurant, "Yemekhane", "canteen_guest"),
            _buildMenuCard(context, Icons.directions_bus, "Ulaşım", "transport_guest"),
            _buildMenuCard(context, Icons.schedule, "Ders Programı", "timetable_guest"),
            _buildMenuCard(context, Icons.school, "Sınav Takvimi", "exams_guest"),
            _buildMenuCard(context, Icons.feedback, "Geri Bildirim", "feedback_guest"),
            _buildMenuCard(context, Icons.map, "Harita", "map_guest"),
            _buildLogoutCard(context),
          ],
        ),
      ),
    ],
    )
        : _buildPage(currentPage),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, String pageKey) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => currentPage = pageKey),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.logout, size: 40, color: Colors.redAccent),
              SizedBox(height: 12),
              Text("Çıkış Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(String pageKey) {
    switch (pageKey) {
      case "announcements_guest":
        return _buildAnnouncementsPage();
      case "events_guest":
        return _buildEventsPage();
      case "canteen_guest":
        return _buildCanteenPage();
      case "transport_guest":
        return _buildTransportPage();
      case "timetable_guest":
        return _buildTimetablePage();
      case "exams_guest":
        return _buildExamsPage();
      case "feedback_guest":
        return _buildFeedbackPage();
      case "map_guest":
        return _buildMapGuestPage();
      default:
        return const Center(child: Text("Sayfa bulunamadı"));
    }
  }
  // 🌍 Misafir Harita Ekranı
  Widget _buildMapGuestPage() {
    final mapController = MapController();

    final Map<String, String> mapLayers = {
      "Normal Harita": "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
      "Uydu Harita": "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
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

            if (docs.isNotEmpty) {
              final first = docs.first;
              final lat = (first['lat'] as num?)?.toDouble() ?? 38.325196;
              final lng = (first['lng'] as num?)?.toDouble() ?? 38.205567;
              initialLocation = LatLng(lat, lng);
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
                    TileLayer(
                      urlTemplate: mapLayers[selectedLayer]!,
                      subdomains: selectedLayer == "Normal Harita"
                          ? const ['a', 'b', 'c', 'd']
                          : const [],
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: docs.map((doc) {
                        final lat = (doc['lat'] as num?)?.toDouble();
                        final lng = (doc['lng'] as num?)?.toDouble();
                        final name = doc['name'] as String? ?? "Bilinmeyen";
                        final address = doc['address'] as String? ?? "Adres bilgisi yok";

                        if (lat == null || lng == null) return null;

                        return Marker(
                          point: LatLng(lat, lng),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(name),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Adres: $address"), // ✅ Adres bilgisi
                                      const SizedBox(height: 8),
                                      Text("Lat: $lat"),
                                      Text("Lng: $lng"),
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
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        );
                      }).whereType<Marker>().toList(),
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
                        heroTag: "zoomInGuest",
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
                        heroTag: "zoomOutGuest",
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

  // 📢 Duyurular
  Widget _buildAnnouncementsPage() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Bir hata oluştu"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Henüz duyuru yok"));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "📢 Duyurular",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      data['title'] ?? 'Başlıksız',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "${date.day}.${date.month}.${date.year}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 200,
                                        child: Image.network(
                                          data['imageUrl'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Center(child: Text("Resim yok")),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? 'Başlıksız',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
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
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Kapat"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
  // 🎉 Etkinlikler
  Widget _buildEventsPage() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Bir hata oluştu"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Henüz etkinlik yok"));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "🎉 Etkinlikler",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      data['title'] ?? 'Etkinlik',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "${date.day}.${date.month}.${date.year} • ${data['location']}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 200,
                                        child: Image.network(
                                          data['imageUrl'],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Center(child: Text("Resim yok")),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? 'Etkinlik',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
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
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Kapat"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  // 🍴 Kantin
  Widget _buildCanteenPage() {
    DateTime currentDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setState) {
        Future<DocumentSnapshot?> _getMenuForDate(DateTime date) async {
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

        return Scaffold(
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "🍽️ Menü",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                          dayName,
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
          ),
        );
      },
    );
  }

// 🔹 Modern tasarımlı kart (anonimdekiyle aynı)
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

  // 🚌 Ulaşım
  Widget _buildTransportPage() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transport').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Bir hata oluştu"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Henüz ulaşım bilgisi yok"));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "🚌 Ulaşım",
                style: TextStyle(
                  fontSize: 22, // ✅ diğer sayfalarla aynı boyut
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.directions_bus,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      data['lineName'] ?? 'Hat',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "${data['departure']} → ${data['arrival']}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: Text(data['lineName'] ?? 'Hat'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Kalkış: ${data['departure']}"),
                                  Text("Varış: ${data['arrival']}"),
                                  const SizedBox(height: 12),
                                  const Text("Duraklar:",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...((data['stops'] ?? []) as List).map((s) => Text("• $s")),
                                  const SizedBox(height: 12),
                                  const Text("Gün içindeki kalkış saatleri:",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Kapat"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
  // 📅 Ders Programı
  Widget _buildTimetablePage() {
    return Scaffold(
      body: Column(
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
                Expanded( // 🔹 Overflow fix: Expanded ile tam genişlik
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final departments = snapshot.data!.docs.map((d) => d['name'] as String).toList();
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
                        items: departments
                            .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedDepartment = val),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Ders listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('departments')
                  .doc(selectedDepartment)
                  .collection('timetable')
                  .orderBy('day')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("Henüz ders programı yok"));
                }
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
                      shadowColor: Colors.black54,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary),
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
      ),
    );
  }

  // 📖 Sınav Takvimi
  Widget _buildExamsPage() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📖 Sınav Takvimi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 200,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final departments =
                      snapshot.data!.docs.map((d) => d['name'] as String).toList();
                      final safeValue = (selectedDepartment != null &&
                          departments.contains(selectedDepartment))
                          ? selectedDepartment
                          : null;
                      return DropdownButton<String>(
                        value: safeValue,
                        isExpanded: true,
                        hint: const Text("Departman Seç"),
                        items: departments
                            .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedDepartment = val),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('departments')
                  .doc(selectedDepartment)
                  .collection('exams')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
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
      ),
    );
  }
  // 💬 Geri Bildirim
  Widget _buildFeedbackPage() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "💬 Geri Bildirim",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const GuestFeedbackForm(),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedbacks')
                  .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("Henüz geri bildiriminiz yok"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();

                    // 🔹 Durum Türkçeleştirme ve renklendirme
                    String durumText;
                    Color durumColor;
                    switch (data['status']) {
                      case 'pending':
                        durumText = 'Beklemede';
                        durumColor = Colors.orange;
                        break;
                      case 'read':
                        durumText = 'Okundu';
                        durumColor = Colors.red;
                        break;
                      case 'answered':
                        durumText = 'Cevaplandı';
                        durumColor = Colors.green;
                        break;
                      default:
                        durumText = 'Bilinmiyor';
                        durumColor = Colors.grey;
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['message'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),

                            // 🔹 Durum etiketi
                            Chip(
                              label: Text(
                                durumText,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: durumColor,
                            ),

                            const SizedBox(height: 8),

                            // 🔹 Admin cevabı
                            if (data['reply'] != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Admin Cevabı: ${data['reply']}",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              Text(
                                "Henüz cevap yok",
                                style: TextStyle(
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic),
                              ),

                            const SizedBox(height: 8),
                            Text(
                              "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}",
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
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
      ),
    );
  }

  // 🔹 Sosyal medya link açıcı
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("URL açılamadı: $url");
    }
  }
}