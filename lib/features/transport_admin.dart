import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransportAdminPage extends StatefulWidget {
  const TransportAdminPage({super.key});

  @override
  State<TransportAdminPage> createState() => _TransportAdminPageState();
}

class _TransportAdminPageState extends State<TransportAdminPage> {
  final _lineNameController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();

  final List<TextEditingController> _stopControllers = [];
  final List<TextEditingController> _timeControllers = [];

  void _addStopField() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _addTimeField() {
    setState(() {
      _timeControllers.add(TextEditingController());
    });
  }

  Future<void> _addTransport() async {
    if (_lineNameController.text.isEmpty ||
        _departureController.text.isEmpty ||
        _arrivalController.text.isEmpty) return;

    final stops = _stopControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final times = _timeControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    await FirebaseFirestore.instance.collection('transport').add({
      'lineName': _lineNameController.text.trim(),
      'departure': _departureController.text.trim(),
      'arrival': _arrivalController.text.trim(),
      'stops': stops,
      'dailyTimes': times,
    });

    setState(() {
      _lineNameController.clear();
      _departureController.clear();
      _arrivalController.clear();

      for (var c in _stopControllers) {
        c.dispose();
      }
      for (var c in _timeControllers) {
        c.dispose();
      }
      _stopControllers.clear();
      _timeControllers.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ulaşım hattı eklendi')),
    );
  }

  // 🔹 Yeni: düzenleme popup
  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final lineController = TextEditingController(text: data['lineName']);
    final departureController = TextEditingController(text: data['departure']);
    final arrivalController = TextEditingController(text: data['arrival']);

    final stopControllers = (data['stops'] as List?)?.map((s) => TextEditingController(text: s)).toList() ?? [];
    final timeControllers = (data['dailyTimes'] as List?)?.map((t) => TextEditingController(text: t)).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ulaşım Hattını Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: lineController,
                  decoration: const InputDecoration(
                    labelText: "Hat Adı",
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                ),
                TextField(
                  controller: departureController,
                  decoration: const InputDecoration(
                    labelText: "Kalkış",
                    prefixIcon: Icon(Icons.play_arrow),
                  ),
                ),
                TextField(
                  controller: arrivalController,
                  decoration: const InputDecoration(
                    labelText: "Varış",
                    prefixIcon: Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Duraklar:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...stopControllers.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      labelText: "Durak",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                const Text("Kalkış Saatleri:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...timeControllers.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: c,
                    decoration: const InputDecoration(
                      labelText: "Saat",
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('transport').doc(docId).update({
                  'lineName': lineController.text.trim(),
                  'departure': departureController.text.trim(),
                  'arrival': arrivalController.text.trim(),
                  'stops': stopControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
                  'dailyTimes': timeControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ulaşım hattı güncellendi ✅")),
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
        title: const Text("🚌 Ulaşım Yönetimi"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Form Kartı
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _lineNameController,
                    decoration: InputDecoration(
                      labelText: 'Hat Adı',
                      prefixIcon: const Icon(Icons.directions_bus),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _departureController,
                    decoration: InputDecoration(
                      labelText: 'Kalkış',
                      prefixIcon: const Icon(Icons.play_arrow),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _arrivalController,
                    decoration: InputDecoration(
                      labelText: 'Varış',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (var c in _stopControllers)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            controller: c,
                            decoration: InputDecoration(
                              labelText: 'Durak',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addStopField,
                          icon: const Icon(Icons.add),
                          label: const Text("Durak Ekle"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (var c in _timeControllers)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            controller: c,
                            decoration: InputDecoration(
                              labelText: 'Kalkış Saati',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addTimeField,
                          icon: const Icon(Icons.add),
                          label: const Text("Saat Ekle"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _addTransport,
                    icon: const Icon(Icons.save),
                    label: const Text("Kaydet"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "📋 Mevcut Ulaşım Hatları",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transport').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("Henüz ulaşım hattı yok"));

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.directions_bus, color: Theme.of(context).colorScheme.primary),
                      title: Text(data['lineName'] ?? 'Hat'),
                      subtitle: Text("${data['departure']} → ${data['arrival']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Hattı düzenle',
                            onPressed: () => _showEditDialog(doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Hattı sil',
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('transport').doc(doc.id).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Hat başarıyla silindi")),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(data['lineName'] ?? 'Hat'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Kalkış: ${data['departure']}"),
                                    Text("Varış: ${data['arrival']}"),
                                    const SizedBox(height: 12),
                                    const Text("Duraklar:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...((data['stops'] ?? []) as List).map((s) => Text("• $s")),
                                    const SizedBox(height: 12),
                                    const Text("Gün içindeki kalkış saatleri:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: ((data['dailyTimes'] ?? []) as List).map<Widget>((t) {
                                        return Chip(label: Text(t));
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}