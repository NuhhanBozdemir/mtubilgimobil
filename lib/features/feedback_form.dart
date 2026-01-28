import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackForm extends StatefulWidget {
  final String uid;
  final String name;
  final String email;
  final String department;
  final String number;
  final String role; // 🔹 öğrenci veya personel bilgisi

  const FeedbackForm({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.number,
    required this.role, // 🔹 parametre olarak role alınıyor
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _submitFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'uid': widget.uid,
        'name': widget.name,
        'email': widget.email,
        'department': widget.department,
        'number': widget.number,
        'message': text,
        'date': Timestamp.now(),
        'status': 'pending',
        'reply': '',
        'role': widget.role, // 🔹 admin ekranı bu alanı filtreliyor
      });
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri bildirim gönderildi')),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "📝 Geri Bildirim",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Şikayet veya önerinizi yazın...',
                  prefixIcon: const Icon(Icons.feedback),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _sending ? null : _submitFeedback,
                icon: _sending
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(_sending ? "Gönderiliyor..." : "Gönder"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}