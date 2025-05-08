import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/connection_checker.dart';
import 'package:selarashomeid/utils/general.dart';

class AddUserWidget extends StatefulWidget {
  @override
  _AddUserWidgetState createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends State<AddUserWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  int? selectedRole;
  int? selectedDivision;
  FocusNode _userNameFocusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // List untuk menyimpan data role dan divisi
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> divisions = [];
  bool isLoadingRoles = true;
  bool isLoadingDivisions = true;

  @override
  void initState() {
    super.initState();
    _fetchRolesAndDivisions();
  }

  @override
  void dispose() {
    _userNameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil data role & divisi hanya sekali saat widget dibuka
  void _fetchRolesAndDivisions() async {
    try {
      final roleResponse = await ApiService.getRoles();
      final divisionResponse = await ApiService.handleDivision(method: 'GET');

      setState(() {
        roles = List<Map<String, dynamic>>.from(roleResponse?['data'] ?? []);
        divisions =
            List<Map<String, dynamic>>.from(divisionResponse['data'] ?? []);
        isLoadingRoles = false;
        isLoadingDivisions = false;
      });
    } catch (error) {
      setState(() {
        isLoadingRoles = false;
        isLoadingDivisions = false;
      });
      General.showSnackBar(context, 'Gagal mengambil data: $error');
    }
  }

  // Fungsi untuk menambah user
  void _addUser(BuildContext context) async {
    if (selectedRole == null || selectedDivision == null) {
      General.showSnackBar(context, 'Role dan Divisi harus dipilih');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await ApiService.handleUser(
        method: 'POST',
        data: {
          'name': nameController.text,
          'email': emailController.text,
          'role_id': selectedRole,
          'divisi_id': selectedDivision,
        },
      );
      setState(() {
        _isLoading = false;
      });
      if (response != null) {
        Navigator.pop(context); // Kembali ke halaman sebelumnya
        General.showSnackBar(context, 'User berhasil ditambahkan!');
      }
    } catch (e) {
      General.showSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return ConnectionChecker(
      child: PopScope(
        canPop: !_userNameFocusNode.hasFocus && !_emailFocusNode.hasFocus,
        onPopInvokedWithResult: (didPop, result) {
          if (_userNameFocusNode.hasFocus) {
            _userNameFocusNode.unfocus();
          }
          if (_emailFocusNode.hasFocus) {
            _emailFocusNode.unfocus();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _userNameFocusNode.unfocus();
            _emailFocusNode.unfocus();
          },
          child: Scaffold(
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
                    "Tambah User",
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
                child: Form(
                  key: _formKey, // Hubungkan Form dengan GlobalKey
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Silahkan masukkan data user baru",
                        style: TextStyle(fontSize: screenWidth * 0.05),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Nama
                      TextFormField(
                        controller: nameController,
                        focusNode: _userNameFocusNode,
                        textAlignVertical: TextAlignVertical
                            .center, // Menjaga teks tetap sejajar
                        decoration: InputDecoration(
                          label: Padding(
                            padding: EdgeInsets.only(
                                left: 12,
                                top: 35,
                                bottom: 2), // Atur padding label
                            child: Text(
                              'Nama Lengkap*',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Label tetap di dalam field saat fokus
                          floatingLabelAlignment:
                              FloatingLabelAlignment.start, // Label tetap sejajar
                          alignLabelWithHint:
                              true, // Menjaga label sejajar dengan input
                          filled: true,
                          fillColor: Colors
                              .grey[200], // Warna background seperti permintaan

                          // **Menggunakan borderRadius tetapi tetap mengontrol tinggi**
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none, // Tidak ada garis border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),

                          // **Geser teks input lebih ke kanan**
                          prefix: SizedBox(
                              width: 12), // Tambahkan padding kiri untuk teks
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                16, // Sebelumnya 10, sekarang 16 agar lebih ke kanan
                            vertical: 18,
                          ),
                          constraints: BoxConstraints(
                              minHeight: 50), // Pastikan field tetap ringkas
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Email
                      TextFormField(
                        controller: emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textAlignVertical: TextAlignVertical
                            .center, // Menjaga teks tetap sejajar
                        decoration: InputDecoration(
                          label: Padding(
                            padding: EdgeInsets.only(
                                left: 12,
                                top: 35,
                                bottom: 2), // Atur padding label
                            child: Text(
                              'Email*',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior
                              .auto, // Label tetap di dalam field saat fokus
                          floatingLabelAlignment:
                              FloatingLabelAlignment.start, // Label tetap sejajar
                          alignLabelWithHint:
                              true, // Menjaga label sejajar dengan input
                          filled: true,
                          fillColor: Colors
                              .grey[200], // Warna background sesuai role model

                          // **Menggunakan borderRadius tetapi tetap mengontrol tinggi**
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none, // Tidak ada garis border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),

                          // **Geser teks input lebih ke kanan**
                          prefix: SizedBox(
                              width: 12), // Tambahkan padding kiri untuk teks
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                16, // Sama seperti role model agar teks lebih ke kanan
                            vertical: 18,
                          ),
                          constraints: BoxConstraints(
                              minHeight: 50), // Pastikan field tetap ringkas
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      ),

                      // **Role**
                      SizedBox(height: screenHeight * 0.03),
                      DropdownButtonFormField<int>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.grey[200], // Warna sesuai role model

                          // **Border mirip dengan TextFormField**
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),

                          // **Padding & ukuran sama dengan TextFormField**
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          constraints: BoxConstraints(minHeight: 50),
                        ),
                        isExpanded: true,
                        hint: Padding(
                          padding:
                              EdgeInsets.only(left: 12), // Geser hint ke kanan
                          child: Text('Pilih Role*'),
                        ),
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
                        validator: (value) =>
                            value == null ? 'Harap pilih role' : null,
                      ),

                      // **Divisi**
                      SizedBox(height: screenHeight * 0.03),
                      DropdownButtonFormField<int>(
                        value: selectedDivision,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.grey[200], // Warna sesuai role model

                          // **Border mirip dengan TextFormField**
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),

                          // **Padding & ukuran sama dengan TextFormField**
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          constraints: BoxConstraints(minHeight: 50),
                        ),
                        isExpanded: true,
                        hint: Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('Pilih Divisi*'),
                        ),
                        onChanged: (int? newValue) {
                          setState(() {
                            selectedDivision = newValue;
                          });
                        },
                        items: divisions.map((division) {
                          return DropdownMenuItem<int>(
                            value: division['id'],
                            child: Text(division['name']),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Harap pilih divisi' : null,
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _addUser(context); // Hanya submit jika form valid
                            }
                          },
                          child: Text(
                            "Tambah User",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                            ),
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
            ),
          ),
        ),
      )
    );
  }
}
