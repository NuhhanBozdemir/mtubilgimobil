import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin'); // 🔹 Sadece adminler

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Kayıtlı admin bulunamadı."));
          }

          final admins = snapshot.data!.docs;

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final doc = admins[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'İsimsiz';
              final email = data['email'] ?? '';
              final department = data['department'] ?? 'Belirtilmemiş';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text("$email • $department"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Düzenle",
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editAdmin(context, doc.id, data),
                      ),
                      IconButton(
                        tooltip: "Sil",
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, doc.id, name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAdmin(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Yeni Admin"),
      ),
    );
  }

  void _editAdmin(BuildContext context, String uid, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final deptController = TextEditingController(text: data['department'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Admin bilgilerini düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Ad Soyad")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "E-posta")),
            TextField(controller: deptController, decoration: const InputDecoration(labelText: "Departman")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'department': deptController.text.trim(),
                // role 'admin' olarak bırakılır
              });
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Admini sil"),
        content: Text("$name kullanıcısını silmek istediğine emin misin?\n(Not: Bu işlem Firestore dokümanını siler)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              Navigator.pop(context);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  void _addAdmin(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final deptController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yeni admin ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Ad Soyad")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "E-posta")),
            TextField(controller: deptController, decoration: const InputDecoration(labelText: "Departman")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              // Not: Burada sadece Firestore dokümanı oluşturuluyor.
              // Authentication (Auth) tarafında kullanıcıyı oluşturmak ve parola atamak ayrı bir adımdır.
              await FirebaseFirestore.instance.collection('users').add({
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'department': deptController.text.trim(),
                'role': 'admin',
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }
}