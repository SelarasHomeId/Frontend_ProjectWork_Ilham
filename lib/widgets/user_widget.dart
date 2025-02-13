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
  // Di user_widget.dart
  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true; // Pastikan indikator loading muncul saat fetch data baru
    });

    try {
      final params = {
        'limit': '$_rowsPerPage',
        'offset': (_pageIndex * _rowsPerPage).toString(),
      };

      final result = await ApiService.handleUser(
        method: 'GET',
        params: params,
      );

      if (result != null) {
        setState(() {
          users = result['data'];
          _totalItems = result['count']; // Pastikan total data diperbarui
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      setState(() {
        _isLoading = false; // Loading selesai
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
        title: Text(
          "User Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                        availableRowsPerPage: [1,2,3,4,5,6,7,8,9,10], // Opsi jumlah baris per halaman
                        onPageChanged: (offset) {
                          int newPageIndex = (offset / _rowsPerPage).floor();
                          if (newPageIndex != _pageIndex) { // Cegah pemanggilan fetchUsers() berulang
                            setState(() {
                              _pageIndex = newPageIndex;
                            });
                            fetchUsers();
                          } // Ambil data berdasarkan halaman yang dipilih
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
    int realIndex = (pageIndex * rowsPerPage) + index + 1; // Hitung index absolut
    if (realIndex > totalItems || index >= users.length) return null;
    final user = users[index];
    return DataRow(cells: [
      DataCell(Text('${realIndex}')),
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
