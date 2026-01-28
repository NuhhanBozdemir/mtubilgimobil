import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// Kullanıcı geri bildirim ekranları
import 'package:mtubilgimobil/features/feedback_form.dart';
import 'package:mtubilgimobil/features/feedbacks_user.dart';

// 🔹 Admin ekranları
import 'package:mtubilgimobil/features/admin_feedbacks.dart';
import 'package:mtubilgimobil/features/admin_management_page.dart';
import 'package:mtubilgimobil/features/announcements_admin.dart';
import 'package:mtubilgimobil/features/canteen_admin.dart';
import 'package:mtubilgimobil/features/events_admin.dart';
import 'package:mtubilgimobil/features/exams_admin.dart';
import 'package:mtubilgimobil/features/timetable_admin.dart';
import 'package:mtubilgimobil/features/transport_admin.dart';
import 'package:mtubilgimobil/features/map_admin_page.dart'; // ✅ Harita yönetimi

import '../models/location_model.dart'; // ✅ LocationModel

class HomePage extends StatefulWidget {
  final String? initialPage;

  const HomePage({super.key, this.initialPage});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  late final bool isAnonymous;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _notifSub;
  StreamSubscription<QuerySnapshot>? _announcementSub;
  StreamSubscription<QuerySnapshot>? _examSub;

  String? selectedDepartment;
  String? currentPage;

  @override
  void initState() {
    super.initState();
    isAnonymous = user != null && user!.isAnonymous;
    _initLocalNotifications();
    _startUserNotificationListener();
    _startAnnouncementListener();
    _startExamListener();
    selectedDepartment = null;
    currentPage = widget.initialPage ?? "menu";
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _announcementSub?.cancel();
    _examSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);
  }

  void _startUserNotificationListener() {
    if (user == null || isAnonymous) return;
    final notifQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('notifications')
        .orderBy('date');

    _notifSub = notifQuery.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          final title = data?['title'] as String?;
          final body = data?['message'] as String?;
          _showLocalNotification(title, body);
        }
      }
    });
  }

  void _startAnnouncementListener() {
    _announcementSub = FirebaseFirestore.instance
        .collection('announcements')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          _showLocalNotification(
            "Yeni Duyuru",
            data?['title'] ?? "Detay yok",
          );
        }
      }
    });
  }

  void _startExamListener() {
    _examSub = FirebaseFirestore.instance
        .collection('exams')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          _showLocalNotification(
            "Yeni Sınav",
            "Ders: ${data?['course']} • Tarih: ${data?['date']}",
          );
        }
      }
    });
  }

  Future<void> _showLocalNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'mtu_channel_id',
      'MTU Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title ?? 'Yeni Bildirim',
      body ?? '',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "MTÜ Bilgi Mobil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,

        // 🔹 Menüdeyken geri butonu hiç çıkmasın
        automaticallyImplyLeading: currentPage != "menu",

        // 🔹 Menü dışındaki sayfalarda geri butonu görünsün
        leading: currentPage != "menu"
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              currentPage = "menu"; // sadece menüye dön
            });
          },
        )
            : null,
      ),

    // 🔹 Sosyal medya bar eklendi
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
      body: user == null
          ? const Center(child: Text("Kullanıcı bulunamadı"))
          : FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text("Kullanıcı bilgisi bulunamadı"));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'İsimsiz';
          final department = data['department'] ?? 'Bölüm yok';
          final number = data['number'] ?? 'Numara yok';
          final role = data['role'] ?? 'user';
          final email = data['email'] ?? 'Email yok';

          if (currentPage == "menu") {
            return Column(
              children: [
                // 🔹 Hoş geldin karşılama AppBar’ın altında
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
                          "Hoş geldin $name 🎉",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // 🔹 Sağ tarafta bilgi ikonu
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        onPressed: () {
                          // 🔹 Rol dönüşümü
                          String roleText;
                          if (role == "student") {
                            roleText = "Öğrenci";
                          } else if (role == "personnel") {
                            roleText = "Personel";
                          } else {
                            roleText = role;
                          }

                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 🔹 Başlık kısmı
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

                                  // 🔹 İçerik kısmı
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.person, color: Colors.blue),
                                          title: Text("İsim: $name"),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.school, color: Colors.green),
                                          title: Text("Bölüm: $department"),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.confirmation_number,
                                              color: Colors.orange),
                                          title: Text("Numara: $number"),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.email, color: Colors.red),
                                          title: Text("Email: $email"),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.badge, color: Colors.purple),
                                          title: Text("Rol: $roleText"),
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

                // 🔹 Menü kutuları
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      if (role == "admin") ...[
                        _buildMenuCard(context, Icons.campaign,
                            "Duyuru Yönetimi", "announcements_admin"),
                        _buildMenuCard(context, Icons.schedule,
                            "Program Yönetimi", "timetable_admin"),
                        _buildMenuCard(context, Icons.restaurant_menu,
                            "Menü Yönetimi", "canteen_admin"),
                        _buildMenuCard(context, Icons.directions_bus,
                            "Ulaşım Yönetimi", "transport_admin"),
                        _buildMenuCard(context, Icons.event,
                            "Etkinlik Yönetimi", "events_admin"),
                        _buildMenuCard(context, Icons.school,
                            "Sınav Yönetimi", "exams_admin"),
                        _buildMenuCard(context, Icons.feedback,
                            "Geri Bildirim Yönetimi", "feedbacks_admin"),
                        _buildMenuCard(context, Icons.map,
                            "Harita Yönetimi", "map_admin"),
                        if (role == "superadmin")
                          _buildMenuCard(context, Icons.admin_panel_settings,
                              "Admin Yönetimi", "admin_management"),
                      ] else ...[
                        _buildMenuCard(context, Icons.campaign,
                            "Duyurular", "announcements"),
                        _buildMenuCard(context, Icons.schedule,
                            "Ders Programı", "timetable"),
                        _buildMenuCard(context, Icons.restaurant_menu,
                            "Menü", "canteen"),
                        _buildMenuCard(context, Icons.directions_bus,
                            "Ulaşım", "transport"),
                        _buildMenuCard(context, Icons.event,
                            "Etkinlikler", "events"),
                        _buildMenuCard(context, Icons.school,
                            "Sınav Takvimi", "exams"),
                        _buildMenuCard(context, Icons.feedback,
                            "Geri Bildirim", "feedback"),
                        _buildMenuCard(context, Icons.map,
                            "Harita", "map"),
                      ],
                      _buildLogoutCard(context),
                    ],
                  ),
                ),
              ],
            );
          }

          // 🔹 Yönlendirme
          switch (currentPage) {
            case "announcements":
              return _buildAnnouncements(
                  context, name, department, number, email);
            case "timetable":
              return _buildTimetable(context, department, role);
            case "canteen":
              return _buildCanteen(context);
            case "transport":
              return _buildTransport(context);
            case "events":
              return _buildEvents(context);
            case "exams":
              return _buildExams(context, department, role);
            case "feedback":
              return _buildFeedback(
                  context, name, email, department, number, role);
            case "map":
              return _buildMapScreen(context);

          // Admin ekranları
            case "announcements_admin":
              return AnnouncementsAdminPage();
            case "timetable_admin":
              return TimetableAdminPage(department: department);
            case "canteen_admin":
              return CanteenAdminPage();
            case "transport_admin":
              return TransportAdminPage();
            case "events_admin":
              return EventsAdminPage();
            case "exams_admin":
              return ExamsAdminPage(department: department);
            case "feedbacks_admin":
              return AdminFeedbacksPage(department: department);
            case "map_admin":
              return MapAdminPage();
            case "admin_management":
              return AdminManagementPage();

            default:
              return const Center(child: Text("Sayfa bulunamadı"));
          }
        },
      ),
    );
  }
  // 🔹 Menü kartı
  Widget _buildMenuCard(
      BuildContext context, IconData icon, String title, String pageKey) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            currentPage = pageKey;
          });
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Çıkış kartı
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
              Text(
                "Çıkış Yap",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📢 Duyurular ekranı (öğrenci/personel için)
  Widget _buildAnnouncements(
      BuildContext context, String name, String department, String number, String email) {
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
                                        height: 200, // ✅ sabit yükseklik
                                        child: Image.network(
                                          data['imageUrl'],
                                          fit: BoxFit.contain, // 🔹 kırpmadan sığdırır
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
  // 📅 Ders Programı ekranı (departman otomatik seçili)
  Widget _buildTimetable(BuildContext context, String department, String role) {
    selectedDepartment ??= department;
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
                  Expanded( // 🔹 Overflow fix: Expanded ile tam genişlik
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

            // 🔹 Ders listesi
            Expanded(
              child: selectedDepartment == null
                  ? const Center(child: Text("Lütfen departman seçiniz"))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('departments')
                    .doc(selectedDepartment)
                    .collection('timetable')
                    .where('day', isEqualTo: days[currentDayIndex]) // ✅ sadece seçilen gün
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
                                  const Icon(Icons.book, color: Colors.blue),
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
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "${data['startTime']} - ${data['endTime']}",
                                      style: const TextStyle(
                                        color: Colors.blue,
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

  // 📖 Sınav Takvimi ekranı (departman otomatik seçili)
  Widget _buildExams(BuildContext context, String department, String role) {
    selectedDepartment ??= department;

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
                      items: departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
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
  }

  // 🍽️ Yemekhane ekranı
  // 🍽️ Yemekhane ekranı (öğrenci/personel için)
  Widget _buildCanteen(BuildContext context) {
    DateTime currentDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setState) {
        Future<DocumentSnapshot?> _getMenuForDate(DateTime date) async {
          // Firestore'daki day alanı "26 Ocak 2026" formatında tutuluyor
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
            stream: FirebaseFirestore.instance.collection('transport').snapshots(),
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
                                  const Text("Duraklar:",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...((data['stops'] ?? []) as List)
                                      .map((s) => Text("• $s")),
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
  // 💬 Geri Bildirim ekranı
  Widget _buildFeedback(BuildContext context, String name, String email,
      String department, String number, String role) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Kullanıcı bulunamadı"));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          FeedbackForm(
            uid: user.uid,
            name: name,
            email: email,
            department: department,
            number: number,
            role: role,
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "📜 Önceki Geri Bildirimleriniz",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          FeedbacksUserList(uid: user.uid),
        ],
      ),
    );
  }

  // 🗺️ Harita ekranı
  Widget _buildMapScreen(BuildContext context) {
    final mapController = MapController();

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
            LatLng initialLocation = const LatLng(38.325196, 38.205567);
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
                    TileLayer(
                      urlTemplate: mapLayers[selectedLayer]!,
                      subdomains: selectedLayer == "Normal Harita"
                          ? const ['a', 'b', 'c', 'd']
                          : const [],
                      userAgentPackageName: 'mtubilgimobil',
                    ),
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

                // 🔹 Üstte Dropdown menüsü (Normal / Uydu)
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
                        heroTag: "zoomIn",
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
                        heroTag: "zoomOut",
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
}

// 🔹 URL açma fonksiyonu
Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('URL açılamadı: $url');
  }
}