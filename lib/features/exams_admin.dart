import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';

class ExamsAdminPage extends StatefulWidget {
  final String department; // örn. "Yazılım Mühendisliği"

  const ExamsAdminPage({super.key, required this.department});

  @override
  State<ExamsAdminPage> createState() => _ExamsAdminPageState();
}

class _ExamsAdminPageState extends State<ExamsAdminPage> {
  final _courseController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _addExam() async {
    if (_selectedDate == null ||
        _courseController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _typeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('departments')
        .doc(widget.department)
        .collection('exams')
        .add({
      'course': _courseController.text.trim(),
      'location': _locationController.text.trim(),
      'type': _typeController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate!),
    });

    // 🔹 Bildirim: tüm kullanıcılara gönder
    final users = await FirebaseFirestore.instance.collection('users').get();
    for (var user in users.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .add({
        'title': 'Yeni Sınav',
        'message':
        "${_courseController.text.trim()} (${_typeController.text.trim()}) sınavı eklendi.",
        'date': Timestamp.fromDate(DateTime.now()),
      });
    }

    _courseController.clear();
    _locationController.clear();
    _typeController.clear();
    _selectedDate = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sınav eklendi ve bildirim gönderildi ✅')),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'), // 🔹 Türkçe takvim desteği
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // 🔹 Yeni: düzenleme popup
  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final courseController = TextEditingController(text: data['course']);
    final locationController = TextEditingController(text: data['location']);
    final typeController = TextEditingController(text: data['type']);
    DateTime? selectedDate = (data['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sınavı Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: courseController, decoration: const InputDecoration(labelText: "Ders")),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: "Salon")),
                TextField(controller: typeController, decoration: const InputDecoration(labelText: "Tür")),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    selectedDate == null
                        ? "Tarih Seç"
                        : "${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}",
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      locale: const Locale('tr', 'TR'),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('departments')
                    .doc(widget.department)
                    .collection('exams')
                    .doc(docId)
                    .update({
                  'course': courseController.text.trim(),
                  'location': locationController.text.trim(),
                  'type': typeController.text.trim(),
                  'date': Timestamp.fromDate(selectedDate ?? DateTime.now()),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sınav güncellendi ✅")),
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
        title: const Text("✍ Sınav Yönetimi"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
          children: [
      Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _courseController,
            decoration: InputDecoration(
              labelText: 'Ders',
              prefixIcon: const Icon(Icons.book),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Salon',
              prefixIcon: const Icon(Icons.meeting_room),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _typeController,
            decoration: InputDecoration(
              labelText: 'Tür',
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate == null
                      ? "Tarih seçilmedi"
                      : "Seçilen: ${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}",
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text("Tarih Seç"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addExam,
            icon: const Icon(Icons.save),
            label: const Text("Kaydet"),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Text(
    "📖 Mevcut Sınavlar",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('departments')
                    .doc(widget.department)
                    .collection('exams')
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("Henüz sınav yok"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final exam = ExamModel.fromMap(docs[i].id, data);

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.school,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(
                            "${exam.course} (${exam.type})",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "${exam.date.day}.${exam.date.month}.${exam.date.year} • ${exam.location}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Sınavı düzenle',
                                onPressed: () => _showEditDialog(exam.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Sınavı sil',
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('departments')
                                      .doc(widget.department)
                                      .collection('exams')
                                      .doc(exam.id)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Sınav silindi 🗑️")),
                                  );
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