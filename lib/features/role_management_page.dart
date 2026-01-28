import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/secondary_auth.dart'; // 🔹 ikincil Auth için import

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final roles = const ["admin", "personnel", "student", "guest", "department"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: roles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get currentRole => roles[_tabController.index];

  String roleSingularLabel(String role) {
    switch (role) {
      case "admin":
        return "Admin";
      case "personnel":
        return "Personel";
      case "student":
        return "Öğrenci";
      case "guest":
        return "Misafir";
      case "department":
        return "Departman";
      default:
        return "Kullanıcı";
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("👥 Rol Yönetimi"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.admin_panel_settings), text: "Adminler"),
                Tab(icon: Icon(Icons.work), text: "Personeller"),
                Tab(icon: Icon(Icons.school), text: "Öğrenciler"),
                Tab(icon: Icon(Icons.group), text: "Misafirler"),
                Tab(icon: Icon(Icons.apartment), text: "Departmanlar"),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _UserList(role: "admin"),
                _UserList(role: "personnel"),
                _UserList(role: "student"),
                _UserList(role: "guest"),
                _DepartmentList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (currentRole == "department") {
            _showCreateDepartmentDialog(context);
          } else {
            _showCreateUserDialog(context, currentRole);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Yeni Ekle"),
      ),
    );
  }

  /// 🔹 Yeni kullanıcı ekleme dialogu
  Future<void> _showCreateUserDialog(BuildContext context, String role) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Yeni ${roleSingularLabel(role)}"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildField(nameCtrl, "Ad Soyad", Icons.person),
              const SizedBox(height: 8),
              buildField(emailCtrl, "E-posta", Icons.email),
              const SizedBox(height: 8),
              buildField(passwordCtrl, "Şifre", Icons.lock),
              const SizedBox(height: 8),

              if (role != "guest") ...[
                // 🔹 Departman dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final departments = snapshot.data!.docs.map((d) => d['name'] as String).toList();
                    return DropdownButtonFormField<String>(
                      value: deptCtrl.text.isEmpty ? null : deptCtrl.text,
                      items: departments.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (val) => deptCtrl.text = val ?? '',
                      decoration: InputDecoration(
                        labelText: "Departman",
                        prefixIcon: const Icon(Icons.apartment),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                buildField(numberCtrl, "Numara", Icons.numbers),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          FilledButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) return;

              // 🔹 1) Auth tarafında kullanıcı oluştur (ikincil Auth ile)
              final cred = await AuthChannels.secondaryAuth!.createUserWithEmailAndPassword(
                email: emailCtrl.text.trim(),
                password: passwordCtrl.text.trim(),
              );

              // 🔹 2) Firestore’a meta verileri kaydet
              await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'department': role == "guest" ? "" : deptCtrl.text.trim(),
                'number': role == "guest" ? "" : numberCtrl.text.trim(),
                'role': role,
                'createdAt': Timestamp.fromDate(DateTime.now()),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kullanıcı eklendi")),
                );
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Departman ekleme dialogu
  Future<void> _showCreateDepartmentDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final facultyCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yeni Departman"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildField(nameCtrl, "Departman Adı", Icons.apartment),
              const SizedBox(height: 8),
              buildField(codeCtrl, "Kod", Icons.code),
              const SizedBox(height: 8),
              buildField(facultyCtrl, "Fakülte", Icons.school),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;

              // Duplicate kontrolü
              final existing = await FirebaseFirestore.instance
                  .collection('departments')
                  .where('name', isEqualTo: nameCtrl.text.trim())
                  .get();

              if (existing.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bu departman zaten mevcut")),
                );
                return;
              }

              await FirebaseFirestore.instance.collection('departments').add({
                'name': nameCtrl.text.trim(),
                'code': codeCtrl.text.trim(),
                'faculty': facultyCtrl.text.trim(),
                'createdAt': Timestamp.fromDate(DateTime.now()),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Departman eklendi")),
                );
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }
}
class _UserList extends StatelessWidget {
  final String role;
  const _UserList({required this.role});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz kullanıcı yok"));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final id = docs[i].id;
            final data = docs[i].data() as Map<String, dynamic>;
            final name = (data['name'] ?? '') as String;
            final email = (data['email'] ?? '') as String;
            final department = (data['department'] ?? '') as String;
            final number = (data['number'] ?? '') as String;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.person, color: primary),
                title: Text(
                  name.isEmpty ? "(İsimsiz)" : name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    if (email.isNotEmpty) email,
                    if (department.isNotEmpty) department,
                    if (number.isNotEmpty) "No: $number",
                  ].join(" • "),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Düzenle",
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showEditUserDialog(context, id, data, role),
                    ),
                    IconButton(
                      tooltip: "Sil",
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, id, name),
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

/// 🔹 Kullanıcı düzenleme dialogu
Future<void> _showEditUserDialog(BuildContext context, String userId, Map<String, dynamic> data, String role) async {
  final nameCtrl = TextEditingController(text: data['name'] ?? '');
  final emailCtrl = TextEditingController(text: data['email'] ?? '');
  final deptCtrl = TextEditingController(text: data['department'] ?? '');
  final numberCtrl = TextEditingController(text: data['number'] ?? '');
  final passwordCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Kullanıcı Düzenle"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            buildField(nameCtrl, "Ad Soyad", Icons.person),
            const SizedBox(height: 8),
            buildField(emailCtrl, "E-posta", Icons.email),
            const SizedBox(height: 8),
            buildField(passwordCtrl, "Yeni Şifre (opsiyonel)", Icons.lock),
            const SizedBox(height: 8),

            if (role != "guest") ...[
              // 🔹 Departman dropdown
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final departments = snapshot.data!.docs.map((d) => d['name'] as String).toList();

                  return DropdownButtonFormField<String>(
                    isExpanded: true, // ✅ uzun departman isimleri taşmaz
                    value: deptCtrl.text.isEmpty ? null : deptCtrl.text,
                    items: departments.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis, // ✅ çok uzun isimler satır taşırmaz
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => deptCtrl.text = val ?? '',
                    decoration: InputDecoration(
                      labelText: "Departman",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // ✅ padding eklendi
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              buildField(numberCtrl, "Numara", Icons.numbers),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
        FilledButton(
          onPressed: () async {
            // 🔹 Firestore güncelleme
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'name': nameCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'department': role == "guest" ? "" : deptCtrl.text.trim(),
              'number': role == "guest" ? "" : numberCtrl.text.trim(),
            });

            // 🔹 Şifre güncelleme (opsiyonel, sadece mevcut oturum için)
            if (passwordCtrl.text.trim().isNotEmpty) {
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(passwordCtrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Şifre güncellendi")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Şifre güncellenemedi: $e")),
                );
              }
            }

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Kullanıcı güncellendi")),
              );
            }
          },
          child: const Text("Kaydet"),
        ),
      ],
    ),
  );
}

/// 🔹 Kullanıcı silme
Future<void> _confirmDelete(BuildContext context, String userId, String name) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Silme Onayı"),
      content: Text("\"$name\" kullanıcısını silmek istediğinize emin misiniz?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
        TextButton(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('users').doc(userId).delete();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Kullanıcı silindi")),
              );
            }
          },
          child: const Text("Sil", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
class _DepartmentList extends StatelessWidget {
  const _DepartmentList();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('departments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz departman yok"));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final id = docs[i].id;
            final data = docs[i].data() as Map<String, dynamic>;
            final name = (data['name'] ?? '') as String;
            final code = (data['code'] ?? '') as String;
            final faculty = (data['faculty'] ?? '') as String;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.apartment, color: primary),
                title: Text(
                  name.isEmpty ? "(İsimsiz)" : name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    if (code.isNotEmpty) "Kod: $code",
                    if (faculty.isNotEmpty) "Fakülte: $faculty",
                  ].join(" • "),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Düzenle",
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _showEditDepartmentDialog(context, id, data),
                    ),
                    IconButton(
                      tooltip: "Sil",
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteDepartment(context, id, name),
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

  Future<void> _showEditDepartmentDialog(BuildContext context, String deptId, Map<String, dynamic> data) async {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final codeCtrl = TextEditingController(text: data['code'] ?? '');
    final facultyCtrl = TextEditingController(text: data['faculty'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Departmanı Düzenle"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildField(nameCtrl, "Departman Adı", Icons.apartment),
              const SizedBox(height: 8),
              buildField(codeCtrl, "Kod", Icons.code),
              const SizedBox(height: 8),
              buildField(facultyCtrl, "Fakülte", Icons.school),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          FilledButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('departments').doc(deptId).update({
                'name': nameCtrl.text.trim(),
                'code': codeCtrl.text.trim(),
                'faculty': facultyCtrl.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Departman güncellendi")),
                );
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDepartment(BuildContext context, String deptId, String name) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Silme Onayı"),
        content: Text("\"$name\" departmanını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('departments').doc(deptId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Departman silindi")),
                );
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 🔧 Ortak input alanı
Widget buildField(TextEditingController controller, String label, IconData icon) {
  return TextField(
    controller: controller,
    obscureText: label.toLowerCase().contains("şifre"), // ✅ şifre alanı gizli gösterilir
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}