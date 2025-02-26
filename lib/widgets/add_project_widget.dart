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

  void showAutoDismissDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Supaya tidak bisa ditutup secara manual
      builder: (context) {
        Future.delayed(Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Tutup dialog setelah 2 detik
          }
        });

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.redAccent, // Warna background error
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi untuk menambah project
  void _addProject(BuildContext context) async {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        dateController.text.isEmpty) {
      showAutoDismissDialog(context, "Semua field harus diisi");
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
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.09),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red[900],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Tambah Project",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Silahkan masukkan data proyek baru",
                style: TextStyle(fontSize: screenWidth * 0.05),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Nama Project
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Nama Project",
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Masukkan nama project",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Lokasi Project
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Lokasi Project",
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Masukkan link lokasi project",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Tanggal Dibuat
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Tanggal Dibuat",
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Pilih tanggal",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addProject(context);
                  },
                  child: Text(
                    "Tambah Project",
                    style: TextStyle(
                        color: Colors.white, fontSize: screenWidth * 0.05),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7EA0B7),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
