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
    setState(() => _isLoading = true);

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
          _totalItems = result['count'];
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
      // Tambahkan SnackBar atau notifikasi error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                        rowsPerPage: _rowsPerPage,
                        availableRowsPerPage: [5, 10],
                        onRowsPerPageChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _rowsPerPage = value;
                              _pageIndex =
                                  0; // Reset ke halaman pertama saat ganti rowsPerPage
                            });
                            fetchUsers(); // Ambil data setelah mengubah rowsPerPage
                          }
                        },
                        onPageChanged: (pageIndex) {
                          print(
                              'Page Changed: $pageIndex'); // Print untuk melihat pageIndex yang baru

                          if (pageIndex < 0) return; // Cegah nilai negatif

                          final offset = pageIndex * _rowsPerPage;
                          print(
                              'Calculated Offset: $offset'); // Print untuk melihat offset yang dihitung

                          final maxPageIndex =
                              (_totalItems / _rowsPerPage).ceil() - 1;
                          print(
                              'Max Page Index: $maxPageIndex'); // Print untuk melihat maxPageIndex

                          // Cegah melebihi halaman terakhir
                          if (pageIndex > maxPageIndex) {
                            print(
                                'Page index exceeds max page index, setting to maxPageIndex: $maxPageIndex');

                            setState(() {
                              _pageIndex =
                                  maxPageIndex; // Kembali ke halaman terakhir yang valid
                            });

                            fetchUsers(); // Ambil data untuk halaman baru
                            return;
                          }

                          // Pastikan offset tidak melebihi totalItems
                          if (offset >= _totalItems) {
                            print(
                                'Offset exceeds total items, setting pageIndex to last valid page');
                            setState(() {
                              _pageIndex =
                                  maxPageIndex; // Kembali ke halaman terakhir yang valid jika offset melebihi total items
                            });
                          } else {
                            setState(() {
                              _pageIndex =
                                  pageIndex; // Set pageIndex ke pageIndex yang baru
                            });
                          }

                          fetchUsers(); // Ambil data untuk halaman baru
                          print('Fetching users for page index: $_pageIndex');
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
    final globalRowIndex = pageIndex * rowsPerPage + index;
    if (globalRowIndex >= totalItems) {
      return null;
    }
    final user = users[index];
    return DataRow(cells: [
      DataCell(Text('${globalRowIndex + 1}')),
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
  int get rowCount => totalItems;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
