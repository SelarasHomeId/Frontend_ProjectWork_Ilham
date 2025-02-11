import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class RoleWidget extends StatefulWidget {
  @override
  _RoleWidgetState createState() => _RoleWidgetState();
}

class _RoleWidgetState extends State<RoleWidget> {
  List<dynamic> roles = [];
  bool _isLoading = true;

  // Memanggil API untuk mendapatkan data role
  Future<void> fetchRoles() async {
    try {
      final result = await ApiService
          .getRoles(); // Memanggil fungsi getRoles() dari ApiService
      if (result != null) {
        setState(() {
          roles = result['data']; // Menyimpan data ke dalam list 'roles'
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching roles: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRoles(); // Ambil data roles saat widget pertama kali dibangun
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Role Management"),
        backgroundColor: Colors.blueAccent, // Sesuaikan warna appbar
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : roles.isEmpty
              ? Center(
                  child: Text(
                      'Tidak ada roles untuk ditampilkan')) // Jika tidak ada role
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Tabel dengan style yang lebih bagus
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Table(
                            border: TableBorder.symmetric(
                              inside:
                                  BorderSide(color: Colors.grey, width: 0.5),
                              outside: BorderSide.none,
                            ),
                            columnWidths: const <int, TableColumnWidth>{
                              0: FlexColumnWidth(2), // Nama role
                              1: FlexColumnWidth(3), // Deskripsi
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors
                                      .blueAccent, // Background header yang lebih modern
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'Role Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'Description',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Tampilkan data role
                              ...roles.map(
                                (role) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 8.0),
                                        child: Text(
                                          role['name'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 8.0),
                                        child: Text(
                                          role['description'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Tambahkan jika perlu informasi tambahan
                        // Padding, tombol, atau lainnya sesuai kebutuhan
                      ],
                    ),
                  ),
                ),
    );
  }
}
