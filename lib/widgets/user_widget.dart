import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class UserWidget extends StatefulWidget {
  @override
  _UserWidgetState createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  List<dynamic> users = [];
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10; // Jumlah data yang ingin ditampilkan per halaman
  int _pageIndex = 0; // Halaman yang sedang aktif
  int _totalItems = 0; // Total data yang ada di server

  // Memanggil API untuk mendapatkan data user dengan pagination
  Future<void> fetchUsers() async {
    try {
      final params = {
        'limit': '$_rowsPerPage', // Menentukan jumlah data per halaman
        'offset': (_pageIndex * _rowsPerPage)
            .toString(), // Menghitung offset berdasarkan halaman
      };

      final result = await ApiService.handleUser(
        method: 'GET',
        params: params, // Mengirimkan params dengan limit dan offset
      );

      if (result != null) {
        setState(() {
          users = result; // Menyimpan data ke dalam list 'users'
          _totalItems = result.length; // Menyimpan total data yang diterima
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Ambil data users saat widget pertama kali dibangun
  }

  // Fungsi untuk mengurutkan data
  void _sort<T>(Comparable<T> Function(dynamic d) getField, int columnIndex,
      bool ascending) {
    users.sort((a, b) {
      if (!ascending) {
        final temp = a;
        a = b;
        b = temp;
      }
      final aValue = getField(a);
      final bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Management"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text('Tidak ada pengguna untuk ditampilkan'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context)
                          .size
                          .width, // Menentukan ukuran
                      child: PaginatedDataTable(
                        rowsPerPage:
                            _rowsPerPage, // Menampilkan 5 data per halaman
                        availableRowsPerPage: [
                          5,
                          10,
                          15
                        ], // Opsi jumlah baris per halaman
                        onPageChanged: (pageIndex) {
                          setState(() {
                            _pageIndex =
                                pageIndex; // Menyimpan indeks halaman yang dipilih
                          });
                          fetchUsers(); // Ambil data berdasarkan halaman yang dipilih
                        },
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(label: Text('No')),
                          DataColumn(
                            label: Text('Nama'),
                            onSort: (columnIndex, ascending) {
                              _sort<String>((user) => user['name'], columnIndex,
                                  ascending);
                            },
                          ),
                          DataColumn(
                            label: Text('Email'),
                            onSort: (columnIndex, ascending) {
                              _sort<String>((user) => user['email'],
                                  columnIndex, ascending);
                            },
                          ),
                          DataColumn(label: Text('Divisi')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Actions')),
                        ],
                        source: MyDataSource(users),
                      ),
                    ),
                  ),
                ),
    );
  }
}

// Define MyDataSource class for paginated data table
class MyDataSource extends DataTableSource {
  final List<dynamic> users;

  MyDataSource(this.users);

  @override
  DataRow? getRow(int index) {
    final user = users[index];
    return DataRow(cells: [
      DataCell(Text('${index + 1}')), // Nomor urut
      DataCell(Text(user['name'] ?? '')),
      DataCell(Text(user['email'] ?? '')),
      DataCell(Text(user['divisi']['name'] ?? '')),
      DataCell(Text(user['role']['name'] ?? '')),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Logika edit
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Logika delete
              },
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  int get rowCount => users.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
