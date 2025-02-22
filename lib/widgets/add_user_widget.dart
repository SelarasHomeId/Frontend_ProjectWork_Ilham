import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class AddUserWidget extends StatefulWidget {
  @override
  _AddUserWidgetState createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends State<AddUserWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  int? selectedRole;
  int? selectedDivision;

  // List untuk menyimpan data role dan divisi
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> divisions = [];

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _fetchDivisions();
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

  // Fungsi untuk menambah user
  void _addUser(BuildContext context) async {
    if (selectedRole == null || selectedDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role dan Divisi harus dipilih')),
      );
      return;
    }

    final data = {
      'name': nameController.text,
      'email': emailController.text,
      'role_id': selectedRole,
      'divisi_id': selectedDivision,
    };

    try {
      final response = await ApiService.handleUser(
        method: 'POST',
        data: data,
      );
      print('Ini Response :' + response);
      if (response != null) {
        Navigator.pop(context); // Kembali ke halaman sebelumnya
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah User")),
      body: Padding(
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
            FutureBuilder(
              future: ApiService.getRoles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Gagal memuat data role');
                } else {
                  roles = List<Map<String, dynamic>>.from(
                      snapshot.data?['data'] ?? []);
                  return DropdownButton<int>(
                    value: selectedRole,
                    hint: Text('Pilih Role'),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedRole = newValue;
                      });
                    },
                    items: roles.map((role) {
                      return DropdownMenuItem<int>(
                        value: role['id'], // Simpan ID sebagai int
                        child: Text(role['name']),
                      );
                    }).toList(),
                  );
                }
              },
            ),
            SizedBox(height: 16),
            // Dropdown untuk Divisi
            FutureBuilder(
              future: ApiService.handleDivision(method: 'GET'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Gagal memuat data divisi');
                } else {
                  divisions = List<Map<String, dynamic>>.from(
                      snapshot.data?['data'] ?? []);
                  return DropdownButton<int>(
                    value: selectedDivision,
                    hint: Text('Pilih Divisi'),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedDivision = newValue;
                      });
                    },
                    items: divisions.map((division) {
                      return DropdownMenuItem<int>(
                        value: division['id'], // Simpan ID sebagai int
                        child: Text(division['name']),
                      );
                    }).toList(),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addUser(context); // Panggil fungsi untuk menambah user
              },
              child: Text("Tambah User"),
            ),
          ],
        ),
      ),
    );
  }
}
