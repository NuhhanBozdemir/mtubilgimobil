import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbacksUserList extends StatelessWidget {
  final String uid;

  const FeedbacksUserList({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('uid', isEqualTo: uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Henüz geri bildirim göndermediniz"));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final ts = d['date'] as Timestamp?;
            final date = ts?.toDate();
            final reply = (d['reply'] ?? '').toString();
            final status = (d['status'] ?? 'pending').toString();

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: status == "answered"
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.feedback,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d['message'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Gönderim: ${date != null ? "${date.day}.${date.month}.${date.year}" : "?"}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(
                        status == "answered" ? "Yanıtlandı" : "Beklemede",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: status == "answered"
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                    if (reply.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Yanıt: $reply",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500),
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
}