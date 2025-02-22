import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class UpdateUserWidget extends StatefulWidget {
  final int userId;

  UpdateUserWidget({required this.userId});

  @override
  _UpdateUserWidgetState createState() => _UpdateUserWidgetState();
}

class _UpdateUserWidgetState extends State<UpdateUserWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  int? selectedRole;
  int? selectedDivision;

  // List untuk menyimpan data role dan divisi
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> divisions = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(widget.userId); // Memuat data user berdasarkan ID
    _fetchRoles(); // Memuat data role
    _fetchDivisions(); // Memuat data divisi
  }

  // Fungsi untuk mengambil data user berdasarkan ID
  void _loadUserData(int userId) async {
    try {
      final response = await ApiService.handleUser(
        method: 'GET',
        userId: userId,
      );

      if (response != null && response['data'] != null) {
        final user = response['data']; // Akses data langsung dari 'data'

        setState(() {
          nameController.text = user['name'] ?? '';
          emailController.text = user['email'] ?? '';
          selectedRole = user['role']['id'];
          selectedDivision = user['divisi']['id'];
          _isLoading = false;
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle exception
    }
  }

  // Fungsi untuk mengambil data role dari API
  void _fetchRoles() async {
    try {
      final response = await ApiService.getRoles();
      if (response != null && response['data'] != null) {
        setState(() {
          roles = List<Map<String, dynamic>>.from(response['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data role: $e')),
      );
    }
  }

  // Fungsi untuk mengambil data divisi dari API
  void _fetchDivisions() async {
    try {
      final response = await ApiService.handleDivision(method: 'GET');
      if (response != null && response['data'] != null) {
        setState(() {
          divisions = List<Map<String, dynamic>>.from(response['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data divisi: $e')),
      );
    }
  }

  // Fungsi untuk mengupdate user
  void _updateUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text("Apakah Anda yakin ingin mengubah data user ini?"),
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
        'email': emailController.text,
        'role_id': selectedRole.toString(), // Kirim ID role
        'divisi_id': selectedDivision.toString(),
      };

      print("Data yang dikirim ke API: $data");

      try {
        final response = await ApiService.handleUser(
          method: 'PUT',
          userId: widget.userId,
          data: data,
        );

        print("Response dari API Update: $response");

        if (response != null && response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User berhasil diupdate!')),
          );
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        } else {
          print("Response tidak valid atau gagal: $response");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengupdate user')),
          );
        }
      } catch (e) {
        print("ERROR DETAIL:");
        print("Error during update: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupdate user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Data User"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Menampilkan loading
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Nama'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  // Dropdown untuk Role
                  roles.isEmpty
                      ? CircularProgressIndicator()
                      : DropdownButton<int>(
                          value: selectedRole,
                          hint: Text('Pilih Role'),
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedRole = newValue;
                            });
                          },
                          items: roles.map((role) {
                            return DropdownMenuItem<int>(
                              value: role['id'],
                              child: Text(role['name']),
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 16),
                  // Dropdown untuk Divisi
                  divisions.isEmpty
                      ? CircularProgressIndicator() // Menampilkan loading jika data divisi belum ada
                      : DropdownButton<int>(
                          value: selectedDivision,
                          hint: Text('Pilih Divisi'),
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedDivision =
                                  newValue; // Mengubah nilai divisi yang dipilih
                            });
                          },
                          items: divisions.map((division) {
                            return DropdownMenuItem<int>(
                              value: division['id'], // ID divisi sebagai value
                              child: Text(division[
                                  'name']), // Nama divisi sebagai tampilan
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateUser,
                    child: Text("Update User"),
                  ),
                ],
              ),
            ),
    );
  }
}
