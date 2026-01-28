import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../main.dart'; // 🔹 saveTokenToFirestore için
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _numberController = TextEditingController();

  String? _selectedDepartment; // 🔹 Dropdown için seçilen departman

  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _signUp(String role) async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        department: role == "guest" ? "" : _selectedDepartment ?? "",
        number: role == "guest" ? "" : _numberController.text.trim(),
        role: role,
      );

      if (user != null) {
        debugPrint("✅ Yeni kullanıcı oluşturuldu: ${user.uid}");

        // 🔹 Firestore dokümanı oluştur
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'department': role == "guest" ? "" : _selectedDepartment ?? "",
          'number': role == "guest" ? "" : _numberController.text.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ Firestore dokümanı kaydedildi: ${user.uid}");

        // 🔹 FCM token kaydet
        await saveTokenToFirestore(user.uid);
        debugPrint("✅ FCM token kaydedildi");

        // 🔹 E-posta doğrulama maili gönder
        await user.sendEmailVerification();
        debugPrint("📧 Doğrulama maili gönderildi");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kayıt başarılı! Lütfen e-posta adresinizi doğrulayın."),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("❌ Kayıt hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kayıt Ol"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: "Öğrenci"),
              Tab(icon: Icon(Icons.work), text: "Personel"),
              Tab(icon: Icon(Icons.people), text: "Misafir"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/background.webp"),
              fit: BoxFit.cover,
            ),
          ),
          child: TabBarView(
            children: [
              _buildForm(role: "student"),
              _buildForm(role: "personnel"),
              _buildForm(role: "guest"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required String role}) {
    String title;
    if (role == "student") {
      title = "🎓 Öğrenci Kayıt Formu";
    } else if (role == "personnel") {
      title = "👔 Personel Kayıt Formu";
    } else {
      title = "👥 Misafir Kayıt Formu";
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withOpacity(0.85),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 20),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Ad Soyad",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                if (role != "guest") ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('departments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text("Departman bulunamadı");
                      }

                      final departments = snapshot.data!.docs
                          .map((doc) => (doc['name'] ?? '') as String)
                          .where((name) => name.isNotEmpty)
                          .toList();

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedDepartment,
                        items: departments.map((dept) {
                          return DropdownMenuItem(
                              value: dept, child: Text(dept));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Departman Seç",
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      labelText: "Numara",
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Center(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : () => _signUp(role),
                    icon: _loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.person_add),
                    label: Text(_loading ? "Kayıt Yapılıyor..." : "Kayıt Ol"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}