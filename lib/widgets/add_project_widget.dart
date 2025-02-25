import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class AddProjectWidget extends StatefulWidget {
  @override
  _AddProjectWidgetState createState() => _AddProjectWidgetState();
}

class _AddProjectWidgetState extends State<AddProjectWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  TextEditingController dateController =
      TextEditingController(); // Controller untuk tanggal

  @override
  void initState() {
    super.initState();
    // Set default date to today's date
    dateController.text =
        DateTime.now().toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
  }

  // Fungsi untuk menampilkan date picker dan memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Tanggal awal adalah hari ini
      firstDate: DateTime(2000), // Tanggal awal (bisa disesuaikan)
      lastDate: DateTime(2101), // Tanggal akhir (bisa disesuaikan)
    );

    if (selectedDate != null && selectedDate != DateTime.now()) {
      setState(() {
        dateController.text = "${selectedDate.toLocal()}"
            .split(' ')[0]; // Set tanggal yang dipilih
      });
    }
  }

  // Fungsi untuk menambah project
  void _addProject(BuildContext context) async {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    final data = {
      'name': nameController.text,
      'location': locationController.text,
      'date_created': dateController.text, // Menggunakan tanggal yang dipilih
    };

    try {
      final response = await ApiService.handleProject(
        method: 'POST',
        data: data,
      );
      print('Response: $response');
      if (response != null) {
        Navigator.pop(context); // Kembali ke halaman sebelumnya
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan project: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Project")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nama Project'),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: 'Lokasi Project'),
            ),
            // Tanggal dengan Date Picker
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Tanggal Dibuat'),
              readOnly:
                  true, // Agar tidak bisa mengetik manual, hanya bisa memilih tanggal
              onTap: () => _selectDate(
                  context), // Panggil fungsi pilih tanggal saat field ditekan
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addProject(context); // Panggil fungsi untuk menambah project
              },
              child: Text("Tambah Project"),
            ),
          ],
        ),
      ),
    );
  }
}
