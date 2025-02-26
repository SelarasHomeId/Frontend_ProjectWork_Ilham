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
  final TextEditingController dateController = TextEditingController();
  bool _isLoading = true;

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
          dateController.text = project['date_created'] ?? '';
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
        final response = await ApiService.handleProject(
          method: 'PUT',
          projectId: widget.projectId,
          data: data,
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
      appBar: AppBar(
        title: Text("Edit Project"),
        backgroundColor: Colors.red[900],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Project',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Lokasi Project',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Dibuat',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProject,
                        child: Text("Perbarui Project"),
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
