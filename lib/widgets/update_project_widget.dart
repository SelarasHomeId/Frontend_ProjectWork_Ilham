import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:http/http.dart' as http;

class UpdateProjectWidget extends StatefulWidget {
  final int projectId;

  UpdateProjectWidget({required this.projectId});

  @override
  _UpdateProjectWidgetState createState() => _UpdateProjectWidgetState();
}

class _UpdateProjectWidgetState extends State<UpdateProjectWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

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
          _existingImageUrl =
              project['cover'] != null ? project['cover']['content'] : null;
          _isLoading = false;
        });
      } else {
        print("No project data found");
      }
    } catch (e) {
      // print("Error fetching project data: $e");
      General.showSnackBar(context, 'Gagal memuat data project: $e');
      setState(() {
        _isLoading = false;
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
    final confirm = await General.showDialogConfirmEdit(
        context: context,
        title: "Edit Project",
        message: "Apakah Anda Yakin Ingin Mengubah Project ?",
        confirmButtonText: "Ya, Ubah",
        cancelButtonText: "Batal");

    if (confirm != null && confirm) {
      try {
        Map<String, dynamic> data = {
          'name': nameController.text,
          'location': locationController.text,
        };

        var response = null;
        if (_selectedImage != null) {
          final fileStream = await http.MultipartFile.fromPath(
            'cover',
            _selectedImage!.path,
          );

          response = await ApiService.handleProject(
            method: 'PUT',
            projectId: widget.projectId,
            data: data,
            listFile: [fileStream],
          );
        } else if (_selectedImage == null && _existingImageUrl == null) {
          data['delete_cover'] = true;
          response = await ApiService.handleProject(
            method: 'PUT',
            projectId: widget.projectId,
            data: data,
          );
        } else {
          response = await ApiService.handleProject(
            method: 'PUT',
            projectId: widget.projectId,
            data: data,
          );
        }

        // print("Update Response: $response");

        if (response != null && response['success'] == true) {
          General.showSnackBar(context, 'Project berhasil diperbarui!');
          Navigator.pop(context);
        } else {
          debugPrint("masuk else");
          General.showSnackBar(context, 'Gagal memperbarui project');
        }
      } catch (e, stackTrace) {
        debugPrint("masuk catch $e: $stackTrace");

        General.showSnackBar(context, 'Gagal memperbarui project: $e');
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
            automaticallyImplyLeading: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Update Data Project",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w500),
            ),
            iconTheme: IconThemeData(
              color: Colors.white, // Mengubah warna ikon back jadi putih
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
