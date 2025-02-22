import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/update_user_widget.dart';
import 'add_user_widget.dart';

class UserWidget extends StatefulWidget {
  @override
  _UserWidgetState createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  List<dynamic> users = [];
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;
  int _totalItems = 0;

  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleUser(
        method: 'GET',
      );

      if (result != null) {
        final params = {
          'limit': result['count'].toString(),
          'offset': _pageIndex.toString(),
        };

        final resultUser = await ApiService.handleUser(
          method: 'GET',
          params: params,
        );
        setState(() {
          users = resultUser['data'];
          _totalItems = resultUser['count'];
        });
      }
    } catch (e) {
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

  Route _createRoute(Widget targetScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Mulai dari kanan
        const end = Offset.zero; // Berakhir di posisi normal
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
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

  void _navigateToUpdateUser() {
    Navigator.of(context).push(_createRoute(UpdateUserWidget()));
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(_createRoute(
                    AddUserWidget())); // 'Add User' adalah menu baru
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFF4C6A92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add), // Icon +
                  SizedBox(width: 4),
                  Text(
                    "Tambah User", // Teks tombol
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                      width: MediaQuery.of(context).size.width,
                      child: PaginatedDataTable(
                        rowsPerPage: _rowsPerPage,
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
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Divisi')),
                          DataColumn(label: Text('Login From')),
                          DataColumn(label: Text('Locked Status')),
                          DataColumn(label: Text('Date Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        source: MyDataSource(
                          users,
                          _totalItems,
                          _pageIndex,
                          _rowsPerPage,
                          context,
                          _navigateToUpdateUser,
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class MyDataSource extends DataTableSource {
  final List<dynamic> users;
  final int totalItems;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onEditPressed;

  MyDataSource(
    this.users,
    this.totalItems,
    this.pageIndex,
    this.rowsPerPage,
    this.context,
    this.onEditPressed,
  );

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
      DataCell(Text(user['role']['name'] ?? '')),
      DataCell(Text(user['divisi']['name'] ?? '')),
      DataCell(Text(user['login_from'] == '' ? '-' : user['login_from'])),
      DataCell(Text(user['is_locked'] ? 'Locked' : 'Unlocked')),
      DataCell(Text(
          (user['created_at'] ?? '').replaceAll('T', ' ').replaceAll('Z', ''))),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                onEditPressed();
              },
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
