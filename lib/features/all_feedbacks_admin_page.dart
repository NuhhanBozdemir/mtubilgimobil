import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllFeedbacksAdminPage extends StatelessWidget {
  const AllFeedbacksAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
        appBar: AppBar(
          title: const Text("📋 Tüm Geri Bildirimler"),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
        .orderBy('date', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.hasError) {
    return const Center(child: Text("Bir hata oluştu"));
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
    final data = docs[index].data() as Map<String, dynamic>;
    final id = docs[index].id;
    final date = (data['date'] as Timestamp).toDate();

    // 🔹 Kullanıcı bilgileri
    String role;
    if (data['isGuest'] == true) {
      role = "Misafir";
    } else {
      final rawRole = (data['role'] ?? "unknown").toString().toLowerCase();
      switch (rawRole) {
        case "student":
          role = "Öğrenci";
          break;
        case "personnel":
          role = "Personel";
          break;
        case "guest":
          role = "Misafir";
          break;
        default:
          role = "Bilinmiyor";
      }
    }

    final department = data['department'] ?? "Genel";
    final name = data['name'] ?? "Bilinmiyor";
    final email = data['email'] ?? "Yok";

    // 🔹 Durum etiketi
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
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Mesaj
            Text(
              data['message'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 Kullanıcı bilgileri (Ad Soyad, E-posta, Rol, Departman)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ad Soyad: $name",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "E-posta: $email",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  "Rol: $role • Departman: $department",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
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

            // 🔹 Admin cevabı veya cevaplama butonu
            if (data['reply'] != null && (data['reply'] as String).isNotEmpty)
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton.icon(
                icon: const Icon(Icons.reply, color: Colors.green),
                label: const Text("Cevapla"),
                onPressed: () async {
                  final replyCtrl = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Geri Bildirime Cevap Ver"),
                      content: TextField(
                        controller: replyCtrl,
                        decoration: const InputDecoration(
                          labelText: "Cevap",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("İptal"),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('feedbacks')
                                .doc(id)
                                .update({
                              'reply': replyCtrl.text.trim(),
                              'status': 'answered',
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cevap gönderildi"),
                                ),
                              );
                            }
                          },
                          child: const Text("Gönder"),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 8),

            // 🔹 Silme butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Sil",
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Silme Onayı"),
                        content: const Text(
                            "Bu geri bildirimi silmek istediğinize emin misiniz?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("İptal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Sil",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('feedbacks')
                          .doc(id)
                          .delete();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Geri bildirim silindi")),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            // 🔹 Tarih
            Text(
              "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
    },
    );
    },
        ),
    );
  }
}