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
              "Tambah User",
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
                "Silahkan masukkan data user baru",
                style: TextStyle(fontSize: screenWidth * 0.05),
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Nama",
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Nama Lengkap",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Email",
                  style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Masukkan Email",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "Role",
                            style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        FutureBuilder(
                          future: ApiService.getRoles(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Gagal memuat data role');
                            } else {
                              roles = List<Map<String, dynamic>>.from(
                                  snapshot.data?['data'] ?? []);
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.grey[100],
                                ),
                                child: DropdownButton<int>(
                                  value: selectedRole,
                                  hint: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Pilih Role',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      selectedRole = newValue;
                                    });
                                  },
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: roles.map((role) {
                                    return DropdownMenuItem<int>(
                                      value: role['id'],
                                      child: Text(role['name'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal)),
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "Divisi",
                            style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        FutureBuilder(
                          future: ApiService.handleDivision(method: 'GET'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Gagal memuat data divisi');
                            } else {
                              divisions = List<Map<String, dynamic>>.from(
                                  snapshot.data?['data'] ?? []);
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.grey[100],
                                ),
                                child: DropdownButton<int>(
                                  value: selectedDivision,
                                  hint: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Pilih Divisi',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      selectedDivision = newValue;
                                    });
                                  },
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: divisions.map((division) {
                                    return DropdownMenuItem<int>(
                                      value: division['id'],
                                      child: Text(division['name']),
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addUser(context);
                  },
                  child: Text("Tambah User",
                      style: TextStyle(
                          color: Colors.white, fontSize: screenWidth * 0.05)),
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
