import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guest_home_page.dart';
import 'home_page.dart';
import 'super_admin_home_page.dart';
import '../main.dart'; // 🔹 saveTokenToFirestore için

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.webp"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/logo.png", height: 120),
                    const SizedBox(height: 20),
                    const Text(
                      "🔑 MTÜ Bilgi Mobil Giriş",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "E-posta",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Şifre",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _login,
                          icon: _loading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.login),
                          label: Text(_loading ? "Giriş Yapılıyor..." : "Giriş Yap"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _resetPassword,
                      child: const Text("Şifremi Unuttum"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        debugPrint("✅ Login başarılı: ${user.uid}");

        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'name': user.email ?? 'Kullanıcı',
            'email': user.email ?? '',
            'department': '',
            'number': '',
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        final roleSnapshot = await docRef.get();
        final role = roleSnapshot.data()?['role'] ?? "student";

        // 🔹 E-posta doğrulama kontrolü
        if (!user.emailVerified && role != "admin" && role != "superadmin") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lütfen önce e-posta adresinizi doğrulayın.")),
          );
          setState(() => _loading = false);
          return;
        }

        if (role != "anonymous") {
          await saveTokenToFirestore(user.uid);
        }

        if (mounted) {
          if (role == "guest") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GuestHomePage()),
            );
          } else if (role == "superadmin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SuperAdminHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = "Geçersiz e-posta adresi.";
          break;
        case 'user-disabled':
          message = "Bu hesap devre dışı bırakılmış.";
          break;
        case 'user-not-found':
          message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
          break;
        case 'wrong-password':
          message = "Hatalı şifre girdiniz.";
          break;
        default:
          message = "Giriş başarısız. Lütfen bilgilerinizi kontrol edin.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beklenmeyen bir hata oluştu.")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    try {
      await _authService.resetPassword(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre sıfırlama maili gönderildi!")),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = "Geçersiz e-posta formatı.";
          break;
        case 'user-not-found':
          message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
          break;
        default:
          message = "Şifre sıfırlama işlemi başarısız.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beklenmeyen bir hata oluştu.")),
      );
    }
  }
}
