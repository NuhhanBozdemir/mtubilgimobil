import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbacksPage extends StatefulWidget {
  final String department; // ✅ adminin departmanı parametre olarak gelecek
  const AdminFeedbacksPage({super.key, required this.department});

  @override
  State<AdminFeedbacksPage> createState() => _AdminFeedbacksPageState();
}

class _AdminFeedbacksPageState extends State<AdminFeedbacksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 🔹 Artık sadece 2 sekme var: Öğrenci ve Personel
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📩 Geri Bildirimler"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,          // 🔹 aktif sekme tam beyaz
          unselectedLabelColor: Colors.white70, // 🔹 pasif sekme soluk beyaz
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "Öğrenci Geri Bildirimleri"),
            Tab(icon: Icon(Icons.work), text: "Personel Geri Bildirimleri"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FeedbacksAdminList(department: widget.department, role: "student"),
          FeedbacksAdminList(department: widget.department, role: "personnel"),
        ],
      ),
    );
  }
}
class FeedbacksAdminList extends StatelessWidget {
  final String department;
  final String role; // 🔹 öğrenci veya personel

  const FeedbacksAdminList({
    super.key,
    required this.department,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('department', isEqualTo: department)
          .where('role', isEqualTo: role) // 🔹 role filtre
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Henüz geri bildirim yok'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final ts = d['date'] as Timestamp?;
            final date = ts?.toDate();
            final reply = (d['reply'] ?? '').toString();
            final status = d['status'] ?? 'pending';

            // 🔹 Durum rengi
            final statusColor =
            status == "answered" ? Colors.green : Colors.orange;
            final statusLabel =
            status == "answered" ? "Cevaplandı" : "Beklemede";

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor,
                          child: const Icon(Icons.feedback, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['name'] ??
                                    (role == "student" ? "Öğrenci" : "Personel"),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${d['department']} • ${d['number']} • ${d['email']}",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          date != null
                              ? "${date.day}.${date.month}.${date.year}"
                              : "Tarih yok",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d['message'] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.reply, color: Colors.blue),
                              tooltip: "Yanıtla",
                              onPressed: () {
                                _showReplyDialog(context, docs[i].id, reply, d['uid']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Sil",
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Silme Onayı"),
                                    content: const Text("Bu geri bildirimi silmek istediğinize emin misiniz?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("İptal"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Sil", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('feedbacks')
                                      .doc(docs[i].id)
                                      .delete();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Geri bildirim silindi")),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (reply.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Yanıt: $reply",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReplyDialog(
      BuildContext context, String docId, String currentReply, String studentUid) {
    final controller = TextEditingController(text: currentReply);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Yanıt Ekle"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Yanıtınızı yazın",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();

              // Feedback dokümanını güncelle
              await FirebaseFirestore.instance
                  .collection('feedbacks')
                  .doc(docId)
                  .update({
                'reply': text,
                'status': 'answered',
              });

              // Kullanıcıya bildirim gönder
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentUid)
                  .collection('notifications')
                  .add({
                'title': 'Geri bildiriminize yanıt geldi',
                'message': text,
                'date': Timestamp.now(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Yanıt kaydedildi")),
              );
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}