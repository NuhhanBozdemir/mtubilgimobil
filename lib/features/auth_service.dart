import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RegExp _emailRegex = RegExp(r'^([a-z]+(\.[a-z]+)?|\d{11})@ozal\.edu\.tr$');

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
    required String department,
    required String number,
    required String role,
  }) async {
    // 🔹 Kayıt olurken misafir için ozal.edu.tr kontrolünü atlıyoruz
    if (role != "guest" && !_emailRegex.hasMatch(email.toLowerCase())) {
      throw Exception("E-posta ozal.edu.tr formatında olmalı (isim veya 11 haneli numara)");
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'department': role == "guest" ? null : department,
      'number': role == "guest" ? null : number,
      'role': role,
      'createdAt': DateTime.now(),
    });

    return cred.user;
  }

  Future<User?> login(String email, String password) async {
    // 🔹 Login’de ozal.edu.tr kontrolü tamamen kaldırıldı
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> resetPassword(String email) async {
    // 🔹 Şifre sıfırlamada da ozal.edu.tr kontrolü kaldırıldı
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}