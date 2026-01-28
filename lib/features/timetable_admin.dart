import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';

class TimetableAdminPage extends StatefulWidget {
  final String department;

  const TimetableAdminPage({super.key, required this.department});

  @override
  State<TimetableAdminPage> createState() => _TimetableAdminPageState();
}

class _TimetableAdminPageState extends State<TimetableAdminPage> {
  final _courseController = TextEditingController();
  final _codeController = TextEditingController();
  final _instructorController = TextEditingController();
  final _locationController = TextEditingController();

  int currentDayIndex = 0;
  final days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"];
  String? selectedDay;

  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(), // ✅ garanti null değil
    );
    if (picked != null) {
      setState(() => _selectedStartTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(), // ✅ garanti null değil
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  Future<void> _addTimetableEntry() async {
    if (selectedDay == null ||
        _courseController.text.isEmpty ||
        _codeController.text.isEmpty ||
        _instructorController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    final startFormatted = _formatTime(_selectedStartTime!);
    final endFormatted = _formatTime(_selectedEndTime!);

    await FirebaseFirestore.instance
        .collection('departments')
        .doc(widget.department)
        .collection('timetable')
        .add({
      'day': selectedDay,
      'course': _courseController.text.trim(),
      'code': _codeController.text.trim(),
      'instructor': _instructorController.text.trim(),
      'location': _locationController.text.trim(),
      'startTime': startFormatted,
      'endTime': endFormatted,
    });

    _courseController.clear();
    _codeController.clear();
    _instructorController.clear();
    _locationController.clear();
    _selectedStartTime = null;
    _selectedEndTime = null;
    selectedDay = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders programı eklendi ✅')),
      );
    }
  }

  // 🔹 Güvenli formatlama fonksiyonu (nullable destekli)
  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
  void _showEditDialog(TimetableModel entry) {
    final courseController = TextEditingController(text: entry.course);
    final codeController = TextEditingController(text: entry.code);
    final instructorController = TextEditingController(text: entry.instructor);
    final locationController = TextEditingController(text: entry.location);

    TimeOfDay? editStart = _parseTime(entry.startTime);
    TimeOfDay? editEnd = _parseTime(entry.endTime);
    String? editDay = entry.day;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ders Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: editDay,
                  decoration: const InputDecoration(labelText: "Gün"),
                  items: days.map((day) {
                    return DropdownMenuItem(value: day, child: Text(day));
                  }).toList(),
                  onChanged: (val) => editDay = val,
                ),
                TextField(controller: courseController, decoration: const InputDecoration(labelText: "Ders")),
                TextField(controller: codeController, decoration: const InputDecoration(labelText: "Kod")),
                TextField(controller: instructorController, decoration: const InputDecoration(labelText: "Eğitmen")),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: "Salon")),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(editStart == null
                      ? "Başlangıç Saati Seç"
                      : _formatTime(editStart)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: editStart ?? TimeOfDay.now(), // ✅ garanti null değil
                    );
                    if (picked != null) {
                      setState(() => editStart = picked);
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(editEnd == null
                      ? "Bitiş Saati Seç"
                      : _formatTime(editEnd)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: editEnd ?? TimeOfDay.now(), // ✅ garanti null değil
                    );
                    if (picked != null) {
                      setState(() => editEnd = picked);
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
                if (editStart != null && editEnd != null) {
                  final startFormatted = _formatTime(editStart);
                  final endFormatted = _formatTime(editEnd);

                  await FirebaseFirestore.instance
                      .collection('departments')
                      .doc(widget.department)
                      .collection('timetable')
                      .doc(entry.id)
                      .update({
                    'day': editDay,
                    'course': courseController.text.trim(),
                    'code': codeController.text.trim(),
                    'instructor': instructorController.text.trim(),
                    'location': locationController.text.trim(),
                    'startTime': startFormatted,
                    'endTime': endFormatted,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ders güncellendi ✅")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen başlangıç ve bitiş saatlerini seçin")),
                  );
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  void _nextDay() {
    setState(() {
      currentDayIndex = (currentDayIndex + 1) % days.length;
    });
  }

  void _previousDay() {
    setState(() {
      currentDayIndex = (currentDayIndex - 1 + days.length) % days.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text("📝 Ders Programı Yönetimi"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
            slivers: [
        // 🔹 Ekleme Formu
        SliverToBoxAdapter(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: "Gün"),
                  items: days.map((day) {
                    return DropdownMenuItem(value: day, child: Text(day));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDay = val),
                ),
                const SizedBox(height: 12),
                _buildField(controller: _courseController, label: 'Ders', icon: Icons.book),
                const SizedBox(height: 12),
                _buildField(controller: _codeController, label: 'Kod', icon: Icons.code),
                const SizedBox(height: 12),
                _buildField(controller: _instructorController, label: 'Eğitmen', icon: Icons.person),
                const SizedBox(height: 12),
                _buildField(controller: _locationController, label: 'Salon', icon: Icons.meeting_room),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(_selectedStartTime == null
                      ? "Başlangıç Saati Seç"
                      : _formatTime(_selectedStartTime)),
                  onPressed: _pickStartTime,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(_selectedEndTime == null
                      ? "Bitiş Saati Seç"
                      : _formatTime(_selectedEndTime)),
                  onPressed: _pickEndTime,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _addTimetableEntry,
                  icon: const Icon(Icons.save),
                  label: const Text("Kaydet"),
                ),
              ],
            ),
          ),
        ),
      ),
    ),

    // 🔹 Gün seçimi
    SliverToBoxAdapter(
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    IconButton(onPressed: _previousDay, icon: const Icon(Icons.arrow_back)),
    Text(days[currentDayIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    IconButton(onPressed: _nextDay, icon: const Icon(Icons.arrow_forward)),
    ],
    ),
    ),
              // 🔹 Listeleme
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('departments')
                    .doc(widget.department)
                    .collection('timetable')
                    .where('day', isEqualTo: days[currentDayIndex])
                    .orderBy('startTime')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Text("Bu gün için ders programı yok")),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final entry = TimetableModel.fromMap(docs[i].id, data);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.schedule, color: primary),
                              title: Text("${entry.code} — ${entry.course}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text(
                                "${entry.instructor} • ${entry.location}\n${entry.startTime} - ${entry.endTime}",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Dersi düzenle',
                                    onPressed: () => _showEditDialog(entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Dersi sil',
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('departments')
                                          .doc(widget.department)
                                          .collection('timetable')
                                          .doc(entry.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  );
                },
              ),
            ],
        ),
      ),
    );
  }
}

Widget _buildField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}