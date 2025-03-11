import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:http/http.dart' as http;

class AddProjectWidget extends StatefulWidget {
  @override
  _AddProjectWidgetState createState() => _AddProjectWidgetState();
}

class _AddProjectWidgetState extends State<AddProjectWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  File? _selectedImage;

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

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  // Fungsi untuk menambah project
  void _addProject(BuildContext context) async {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        dateController.text.isEmpty) {
      showAutoDismissDialog(context, "Semua field harus diisi");
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiService.getProjectUrl()),
      );

      // ✅ Ambil token dengan benar sebelum digunakan
      final token = await ApiService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal menambahkan project: Token tidak ditemukan')),
        );
        return;
      }

      // ✅ Pastikan format Authorization sesuai dengan API
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Tambahkan data proyek
      request.fields['name'] = nameController.text;
      request.fields['location'] = locationController.text;
      request.fields['date_created'] = dateController.text;

      // Upload gambar jika ada
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('cover', _selectedImage!.path),
        );
      }

      // Kirim request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project berhasil ditambahkan!')),
        );
      } else {
        print("⚠️ Error Response: $responseData"); // Debug Response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan project: $responseData')),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e"); // Debug Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
                "Silahkan Masukkan Data Proyek Baru",
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

              // Pilih Gambar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Gambar Cover",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .cloud_upload, // Ganti dengan ikon yang diinginkan
                            color: Colors.white,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Pilih Gambar",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7EA0B7),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _selectedImage != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              _selectedImage!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "Tidak ada gambar",
                          style: TextStyle(color: Colors.grey),
                        ),
                ],
              ),

              SizedBox(
                height: 10,
              ),

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
                      borderRadius: BorderRadius.circular(15),
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
