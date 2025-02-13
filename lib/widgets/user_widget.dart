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
  int _rowsPerPage = 5; // Jumlah data yang ingin ditampilkan per halaman
  int _pageIndex = 0; // Halaman yang sedang aktif
  int _totalItems = 0; // Total data yang ada di server

  // Memanggil API untuk mendapatkan data user dengan pagination
  // Di user_widget.dart
  Future<void> fetchUsers() async {
    try {
      final params = {
        'limit': '$_rowsPerPage',
        'offset': (_pageIndex * _rowsPerPage).toString(),
        'is_delete': 'false', // Filter data yang tidak di-delete
      };

      final result = await ApiService.handleUser(
        method: 'GET',
        params: params,
      );

      if (result != null) {
        setState(() {
          users = result['data'];
          _totalItems = result['count']; // Total data aktif dari API
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
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
                        header: Text('Total Users: $_totalItems'),
                        source: MyDataSource(
                            users, _totalItems, _pageIndex, _rowsPerPage),
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
  final int totalItems;
  final int pageIndex;
  final int rowsPerPage;

  MyDataSource(this.users, this.totalItems, this.pageIndex, this.rowsPerPage);

  @override
  DataRow? getRow(int index) {
    // Hitung indeks data yang sesuai dengan halaman saat ini
    final localIndex = index - (pageIndex * rowsPerPage);
    if (localIndex < 0 || localIndex >= users.length) {
      return null; // Tidak tampilkan apa-apa jika data belum terload
    }

    final user = users[localIndex];
    return DataRow(cells: [
      DataCell(Text('${index + 1}')),
      DataCell(Text(user['name'] ?? '')),
      DataCell(Text(user['email'] ?? '')),
      DataCell(Text(user['divisi']['name'] ?? '')),
      DataCell(Text(user['role']['name'] ?? '')),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {},
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  int get rowCount => totalItems; // Gunakan total data dari API

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
