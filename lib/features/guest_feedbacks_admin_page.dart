import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuestFeedbacksAdminPage extends StatelessWidget {
  final String adminDepartment;
  const GuestFeedbacksAdminPage({super.key, required this.adminDepartment});

  Future<void> _replyToFeedback(BuildContext context, String docId) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Geri Bildirime Cevap Ver"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Cevabınızı buraya yazın...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          FilledButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('feedbacks')
                  .doc(docId)
                  .update({
                'reply': controller.text.trim(),
                'status': 'answered',
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cevap kaydedildi 👍")),
              );
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection('feedbacks')
        .doc(docId)
        .update({'status': 'read'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Geri bildirim okundu olarak işaretlendi")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .where('isGuest', isEqualTo: true) // 🔹 sadece misafirler
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
            return const Center(child: Text("Henüz geri bildirim yok"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();

              // 🔹 Durum Türkçeleştirme
              String durumText;
              switch (data['status']) {
                case 'pending':
                  durumText = 'Beklemede';
                  break;
                case 'read':
                  durumText = 'Okundu';
                  break;
                case 'answered':
                  durumText = 'Cevaplandı';
                  break;
                default:
                  durumText = 'Bilinmiyor';
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.feedback,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(
                    data['name']?.isNotEmpty == true
                        ? data['name']
                        : "İsimsiz Misafir",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${data['email'] ?? 'E-posta yok'}\n"
                        "${data['message'] ?? ''}\n\n"
                        "Durum: $durumText\n"
                        "Cevap: ${data['reply'] ?? 'Henüz cevap yok'}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: adminDepartment == "Misafir"
                      ? Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mark_email_read),
                        tooltip: "Okundu olarak işaretle",
                        onPressed: () => _markAsRead(context, doc.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.reply),
                        tooltip: "Cevapla",
                        onPressed: () => _replyToFeedback(context, doc.id),
                      ),
                    ],
                  )
                      : null, // 🔹 diğer departman adminleri butonları görmez
                ),
              );
            },
          );
        },
      ),
    );
  }
}