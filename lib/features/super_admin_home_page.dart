import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'announcements_admin.dart';
import 'events_admin.dart';
import 'exams_admin.dart';
import 'timetable_admin.dart';
import 'canteen_admin.dart';
import 'transport_admin.dart';
import 'guest_feedbacks_admin_page.dart';
import 'role_management_page.dart';
import 'map_admin_page.dart';
import 'all_feedbacks_admin_page.dart';

class SuperAdminHomePage extends StatefulWidget {
  const SuperAdminHomePage({super.key});

  @override
  State<SuperAdminHomePage> createState() => _SuperAdminHomePageState();
}

class _SuperAdminHomePageState extends State<SuperAdminHomePage> {
  String currentPage = "menu";
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? "Süper Admin";
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

        // 🔹 Menüde geri butonu yok, diğer sayfalarda var
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
    "Hoş geldin $name 🎉",
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
    title: Text("İsim: $name"),
    ),
    ListTile(
    leading: const Icon(Icons.email, color: Colors.red),
    title: Text("Email: $email"),
    ),
    ListTile(
    leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
    title: const Text("Rol: Süper Admin"),
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
            _buildMenuCard(context, Icons.campaign, "Duyuru Yönetimi", "announcements_admin"),
            _buildMenuCard(context, Icons.event, "Etkinlik Yönetimi", "events_admin"),
            _buildMenuCard(context, Icons.school, "Sınav Yönetimi", "exams_admin"),
            _buildMenuCard(context, Icons.schedule, "Program Yönetimi", "timetable_admin"),
            _buildMenuCard(context, Icons.restaurant, "Menü Yönetimi", "canteen_admin"),
            _buildMenuCard(context, Icons.directions_bus, "Ulaşım Yönetimi", "transport_admin"),
            _buildMenuCard(context, Icons.feedback, "Geri Bildirim Yönetimi", "feedbacks_admin"),
            _buildMenuCard(context, Icons.admin_panel_settings, "Rol Yönetimi", "role_management"),
            _buildMenuCard(context, Icons.map, "Harita Yönetimi", "map_admin_super"),
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
      case "announcements_admin":
        return const AnnouncementsAdminPage();
      case "events_admin":
        return const EventsAdminPage();
      case "exams_admin":
        return const ExamsAdminPage(department: "Tüm Bölümler");
      case "timetable_admin":
        return const TimetableAdminPage(department: "Tüm Bölümler");
      case "canteen_admin":
        return const CanteenAdminPage();
      case "transport_admin":
        return const TransportAdminPage();
      case "feedbacks_admin":
        return const AllFeedbacksAdminPage();
      case "role_management":
        return const RoleManagementPage();
      case "map_admin_super":
        return const MapAdminPage();
      default:
        return const Center(child: Text("Sayfa bulunamadı"));
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('URL açılamadı: $url');
    }
  }
}