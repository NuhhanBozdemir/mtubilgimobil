import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuestFeedbackForm extends StatefulWidget {
  const GuestFeedbackForm({super.key});

  @override
  State<GuestFeedbackForm> createState() => _GuestFeedbackFormState();
}

class _GuestFeedbackFormState extends State<GuestFeedbackForm> {
  final _messageController = TextEditingController();

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mesaj boş olamaz")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Kullanıcının kayıtlı bilgilerini çekiyoruz
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'uid': user.uid,
        'name': userDoc['name'],
        'email': userDoc['email'],
        'department': "Misafir",   // 🔹 Otomatik departman ismi
        'number': userDoc['number'],
        'message': _messageController.text.trim(),
        'reply': null,
        'status': 'pending',
        'date': DateTime.now(),
        'isGuest': true,
      });


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geri bildiriminiz gönderildi 👍")),
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Şikayet veya önerinizi yazın...",
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitFeedback,
              icon: const Icon(Icons.send),
              label: const Text("Gönder"),
            ),
          ],
        ),
      ),
    );
  }
}