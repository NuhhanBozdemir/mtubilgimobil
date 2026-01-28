import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔹 Link açmak için
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 🔹 Sosyal medya ikonları
import 'anonymous_home_page.dart';
import 'home_page.dart';

class HomeMenuPage extends StatelessWidget {
  final String role;
  final String department;

  const HomeMenuPage({super.key, required this.role, required this.department});

  // 🔹 Link açma fonksiyonu
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Link açılamadı: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final menuItems = [
      {"title": "Duyurular", "icon": Icons.campaign, "pageType": "announcements"},
      {"title": "Ders Programı", "icon": Icons.schedule, "pageType": "timetable"},
      {"title": "Yemekhane", "icon": Icons.restaurant_menu, "pageType": "canteen"},
      {"title": "Ulaşım", "icon": Icons.directions_bus, "pageType": "transport"},
      {"title": "Etkinlikler", "icon": Icons.event, "pageType": "events"},
      {"title": "Sınav Takvimi", "icon": Icons.school, "pageType": "exams"},
      {"title": "Geri Bildirim", "icon": Icons.feedback, "pageType": "feedback"},
      {"title": "Harita", "icon": Icons.map, "pageType": "map"}, // ✅ yeni eklendi
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "MTÜ Bilgi Mobil",
          style: TextStyle(
            fontSize: 22, // ✅ büyük ve net
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary, // üst bar aynı kaldı
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 32, color: Colors.blue),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Hoş geldiniz 🎉",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text("Anonim Kullanıcı",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          // 🔹 Anonim kullanıcı için giriş/kayıt butonları AppBar altında
          if (user == null || user.isAnonymous)
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text("Giriş Yap"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text("Kayıt Ol"),
                  ),
                ],
              ),
            ),

          // 🔹 Menü grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GestureDetector(
                  onTap: () {
                    if (user == null || user.isAnonymous) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnonymousHomePage(
                            pageType: item["pageType"] as String,
                          ),
                        ),
                      );
                    } else if (role == "student" || role == "personnel") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(
                            initialPage: item["pageType"] as String,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item["icon"] as IconData,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item["title"] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 🔹 Sosyal medya alt bar
      bottomNavigationBar: Container(
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
      ),
    );
  }
}