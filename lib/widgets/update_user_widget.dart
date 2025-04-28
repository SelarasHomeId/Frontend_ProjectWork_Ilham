import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';

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
  bool? isLocked;
  FocusNode _userNameFocusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();

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

  @override
  void dispose() {
    _userNameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
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
          isLocked = user['is_locked'];
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
      General.showSnackBar(context, 'Gagal mengambil data role: $e');
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
      General.showSnackBar(context, 'Gagal mengambil data divisi: $e');
    }
  }

  // Fungsi untuk mengupdate user
  void _updateUser() async {
    final confirm = await General.showDialogConfirmEdit(
        context: context,
        title: "Update",
        message: "Apakah Anda Yakin Ingin Mengubah Data User Ini ?",
        confirmButtonText: "Ya, Ubah",
        cancelButtonText: "Batal");

    if (confirm != null && confirm) {
      final data = {
        'name': nameController.text,
        'email': emailController.text,
        'role_id': selectedRole.toString(),
        'divisi_id': selectedDivision.toString(),
        'is_locked': isLocked.toString(),
      };

      print("Data yang dikirim ke API: $data");

      try {
        final response = await ApiService.handleUser(
          method: 'PUT',
          userId: widget.userId,
          data: data,
        );

        //print("Response dari API Update: $response");

        if (response != null && response['success'] == true) {
          General.showSnackBar(context, 'User berhasil diupdate!');
          Navigator.pop(context);
        } else {
          //print("Response tidak valid atau gagal: $response");
          General.showSnackBar(context, 'Gagal mengupdate user');
        }
      } catch (e) {
        //print("ERROR DETAIL:");
        //print("Error during update: $e");
        General.showSnackBar(context, 'Gagal mengupdate user: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
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
                  "Update Data User",
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
                          focusNode: _userNameFocusNode,
                          decoration: InputDecoration(
                            hintText: "Nama Lengkap",
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
                          focusNode: _emailFocusNode,
                          decoration: InputDecoration(
                            hintText: "Masukkan Email",
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
                                      if (snapshot.hasError) {
                                        return Text('Gagal memuat data role');
                                      } else {
                                        roles = List<Map<String, dynamic>>.from(
                                            snapshot.data?['data'] ?? []);
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border:
                                                Border.all(color: Colors.grey),
                                            color: Colors.grey[100],
                                          ),
                                          child: DropdownButton<int>(
                                            value: selectedRole,
                                            hint: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left:
                                                        16.0), // Memberikan sedikit jarak dari kiri
                                                child: Text(
                                                  'Pilih Role',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal),
                                                ),
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
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                      left:
                                                          16.0), // Memberikan sedikit jarak dari kiri
                                                  child: Text(
                                                    role['name'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
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
                                    future: ApiService.handleDivision(
                                        method: 'GET'),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Text('Gagal memuat data divisi');
                                      } else {
                                        divisions =
                                            List<Map<String, dynamic>>.from(
                                                snapshot.data?['data'] ?? []);
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border:
                                                Border.all(color: Colors.grey),
                                            color: Colors.grey[100],
                                          ),
                                          child: DropdownButton<int>(
                                            value: selectedDivision,
                                            hint: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left:
                                                        16.0), // Memberikan sedikit jarak dari kiri
                                                child: Text(
                                                  'Pilih Divisi',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal),
                                                ),
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
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                      left:
                                                          16.0), // Memberikan sedikit jarak dari kiri
                                                  child: Text(
                                                    division['name'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "Status",
                            style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey),
                            color: Colors.grey[100],
                          ),
                          child: DropdownButton<bool>(
                            value: isLocked,
                            onChanged: (bool? newValue) {
                              setState(() {
                                isLocked = newValue;
                              });
                            },
                            isExpanded: true,
                            underline: SizedBox(),
                            items: [
                              DropdownMenuItem<bool>(
                                value: false,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left:
                                          16.0), // Memberikan sedikit jarak dari kiri
                                  child: Text(
                                    'Unlocked',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ),
                              ),
                              DropdownMenuItem<bool>(
                                value: true,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left:
                                          16.0), // Memberikan sedikit jarak dari kiri
                                  child: Text(
                                    'Locked',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updateUser,
                            child: Text("Update User",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.05)),
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
    );
  }
}
