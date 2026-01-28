import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/canteen_model.dart';

class CanteenAdminPage extends StatefulWidget {
  const CanteenAdminPage({super.key});

  @override
  State<CanteenAdminPage> createState() => _CanteenAdminPageState();
}

class _CanteenAdminPageState extends State<CanteenAdminPage> {
  final _soupController = TextEditingController();
  final _mainController = TextEditingController();
  final _sideController = TextEditingController();
  final _dessertController = TextEditingController();

  DateTime? selectedDate;

  Future<void> _addMenu() async {
    if (selectedDate == null ||
        _soupController.text.isEmpty ||
        _mainController.text.isEmpty ||
        _sideController.text.isEmpty ||
        _dessertController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    final formattedDay = DateFormat("d MMMM yyyy", "tr_TR").format(selectedDate!);

    await FirebaseFirestore.instance.collection('canteen').add({
      'day': formattedDay,
      'soup': _soupController.text.trim(),
      'main': _mainController.text.trim(),
      'side': _sideController.text.trim(),
      'dessert': _dessertController.text.trim(),
    });

    final users = await FirebaseFirestore.instance.collection('users').get();
    for (var user in users.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .add({
        'title': 'Menü Güncellendi',
        'message': "$formattedDay menüsü eklendi.",
        'date': Timestamp.fromDate(DateTime.now()),
      });
    }

    _soupController.clear();
    _mainController.clear();
    _sideController.clear();
    _dessertController.clear();
    selectedDate = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menü eklendi ve bildirim gönderildi ✅')),
    );
  }

  void _showEditDialog(CanteenModel menu) {
    final soupController = TextEditingController(text: menu.soup);
    final mainController = TextEditingController(text: menu.main);
    final sideController = TextEditingController(text: menu.side);
    final dessertController = TextEditingController(text: menu.dessert);

    DateTime? editDate;
    try {
      editDate = DateFormat("d MMMM yyyy", "tr_TR").parse(menu.day);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Menü Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat("d MMMM yyyy", "tr_TR").format(editDate ?? DateTime.now()),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: editDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale("tr", "TR"), // ✅ Türkçe takvim
                    );
                    if (picked != null) {
                      setState(() => editDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: soupController,
                  decoration: InputDecoration(
                    labelText: "Çorba",
                    prefixIcon: const Icon(Icons.ramen_dining, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mainController,
                  decoration: InputDecoration(
                    labelText: "Ana Yemek",
                    prefixIcon: const Icon(Icons.restaurant, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sideController,
                  decoration: InputDecoration(
                    labelText: "Yan Yemek",
                    prefixIcon: const Icon(Icons.fastfood, color: Colors.blue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dessertController,
                  decoration: InputDecoration(
                    labelText: "Tatlı",
                    prefixIcon: const Icon(Icons.cake, color: Colors.pink),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final formattedDay = editDate == null
                    ? menu.day
                    : DateFormat("d MMMM yyyy", "tr_TR").format(editDate!);

                await FirebaseFirestore.instance
                    .collection('canteen')
                    .doc(menu.id)
                    .update({
                  'day': formattedDay,
                  'soup': soupController.text.trim(),
                  'main': mainController.text.trim(),
                  'side': sideController.text.trim(),
                  'dessert': dessertController.text.trim(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menü güncellendi ✅")),
                );
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🍽️ Menü Yönetimi"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
          children: [
      // 🔹 Menü ekleme formu
      Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
            label: Text(
              selectedDate == null
                  ? "Tarih Seç"
                  : DateFormat("d MMMM yyyy", "tr_TR").format(selectedDate!),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                locale: const Locale("tr", "TR"), // ✅ Türkçe takvim
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _soupController,
            decoration: InputDecoration(
              labelText: 'Çorba',
              prefixIcon: const Icon(Icons.ramen_dining, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mainController,
            decoration: InputDecoration(
              labelText: 'Ana Yemek',
              prefixIcon: const Icon(Icons.restaurant, color: Colors.green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sideController,
            decoration: InputDecoration(
              labelText: 'Yan Yemek',
              prefixIcon: const Icon(Icons.fastfood, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dessertController,
            decoration: InputDecoration(
              labelText: 'Tatlı',
              prefixIcon: const Icon(Icons.cake, color: Colors.pink),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addMenu,
            icon: const Icon(Icons.save),
            label: const Text("Kaydet"),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Text(
    "📋 Mevcut Menüler",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('canteen').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("Henüz menü yok"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final menu = CanteenModel.fromMap(docs[i].id, data);
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
                          title: Text(
                            "${menu.day} Menüsü",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "Çorba: ${menu.soup}\nAna Yemek: ${menu.main}\nYan Yemek: ${menu.side}\nTatlı: ${menu.dessert}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Menüyü düzenle',
                                onPressed: () => _showEditDialog(menu),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Menüyü sil',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Menüyü Sil"),
                                      content: Text("${menu.day} menüsünü silmek istediğine emin misin?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("İptal"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Sil"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('canteen')
                                        .doc(menu.id)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Menü silindi ❌")),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
      ),
    );
  }
}