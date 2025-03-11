import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class UpdateProjectWidget extends StatefulWidget {
  final int projectId;

  UpdateProjectWidget({required this.projectId});

  @override
  _UpdateProjectWidgetState createState() => _UpdateProjectWidgetState();
}

class _UpdateProjectWidgetState extends State<UpdateProjectWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  bool _isLoading = true;
  File? _selectedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProjectData(widget.projectId);
  }

  void _loadProjectData(int projectId) async {
    print("Fetching project data for ID: $projectId");
    try {
      final response = await ApiService.handleProject(
        method: 'GET',
        projectId: projectId,
      );
      print("Response received: $response");

      if (response != null && response['data'] != null) {
        final project = response['data'];
        print("Project Data: $project");

        setState(() {
          nameController.text = project['name'] ?? '';
          locationController.text = project['location'] ?? '';
          dateController.text = project['created_at'] ?? '';
          _existingImageUrl = project['cover']['content'];
          _isLoading = false;
        });
      } else {
        print("No project data found");
      }
    } catch (e) {
      print("Error fetching project data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data project: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      setState(() {
        dateController.text = "${selectedDate.toLocal()}".split(' ')[0];
      });
    }
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

  void _updateProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text("Apakah Anda yakin ingin mengubah data project ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Ya, Ubah"),
            ),
          ],
        );
      },
    );

    if (confirm != null && confirm) {
      final data = {
        'name': nameController.text,
        'location': locationController.text,
        'date_created': dateController.text,
      };

      print("Updating project with data: $data");
      try {
        // Membuat form data dengan file
        final data = {
          'name': nameController.text,
          'location': locationController.text,
          'date_created': dateController.text,
        };

        // Panggil API service dengan file
        final response = await ApiService.handleProject(
          method: 'PUT',
          projectId: widget.projectId,
          data: data,
          // imageFile: _selectedImage, // Kirim file jika ada
        );
        print("Update Response: $response");

        if (response != null && response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project berhasil diperbarui!')),
          );
          Navigator.pop(context);
        } else {
          print("Failed to update project");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui project')),
          );
        }
      } catch (e) {
        print("Error updating project: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui project: $e')),
        );
      }
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
              "Edit Project",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Silahkan Perbarui Data Proyek",
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
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.5)),
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
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.5)),
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
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.5)),
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
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            if (_selectedImage != null)
                              Image.file(_selectedImage!,
                                  width: 100, height: 100, fit: BoxFit.cover)
                            else if (_existingImageUrl != null)
                              Image.network(_existingImageUrl!,
                                  width: 100, height: 100, fit: BoxFit.cover)
                            else
                              Text("Belum ada gambar",
                                  style: TextStyle(color: Colors.grey)),
                            if (_selectedImage != null ||
                                _existingImageUrl != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _selectedImage = null;
                                  _existingImageUrl = null;
                                }),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),

                    SizedBox(
                      height: 10,
                    ),
                    // Tombol Update
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProject,
                        child: Text(
                          "Perbarui Project",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05),
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
