import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/update_user_widget.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_user_widget.dart';

class UserWidget extends StatefulWidget {
  @override
  _UserWidgetState createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool _isLoading = true;
  bool _isLoadingExport = false;
  bool _isSearchVisible = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;

  FocusNode searchUserFocusNode = FocusNode();

  // Animation controller for the search TextField
  late AnimationController _animationController;

  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleUser(
          method: 'GET', params: {'no_paging': 'yes'});

      if (result != null) {
        setState(() {
          users = result['data'];
          filteredUsers = users; // Store original users
        });
      }
    } catch (e) {
      General.showSnackBar(context, 'Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }

    _searchController.addListener(() {
      _searchUserByName();
      _searchUserByEmail();
    });
  }

  void _deleteUser(int userId) async {
    final confirm = await General.showDialogConfirmDelete(
        context: context,
        title: "Hapus User",
        message: "Apakah Anda yakin ingin menghapus user ini?",
        additionalMessage: "",
        confirmButtonText: "Hapus",
        cancelButtonText: "Batal");

    if (confirm != null && confirm) {
      try {
        final response =
            await ApiService.handleUser(method: 'DELETE', userId: userId);

        if (response != null &&
            response['code'] == 200 &&
            response['success']) {
          General.showSnackBar(context, 'Sukses Hapus User');
          setState(() {
            users.removeWhere((user) => user['id'] == userId);
          });
        } else {
          General.showSnackBar(context, 'Failed to delete user');
        }
      } catch (e) {
        General.showSnackBar(context, 'Error deleting user: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetPassUser(int userId) async {
    final confirm = await General.showDialogConfirmDelete(
        context: context,
        title: "Reset Password User",
        message: "Apakah Anda yakin ingin me-reset password user ini?",
        additionalMessage: "",
        confirmButtonText: "Reset",
        cancelButtonText: "Batal",
        coreIcon: Icons.lock_reset,
        coreTheme: Colors.deepOrange);

    if (confirm != null && confirm) {
      try {
        final response = await ApiService.handleUser(
            method: 'PATCH', userId: userId, resetPass: true);

        if (response != null &&
            response['code'] == 200 &&
            response['success']) {
          General.showSnackBar(context, 'Sukses Reset Password User');
        } else {
          General.showSnackBar(context, 'Failed to reset password user');
        }
      } catch (e) {
        General.showSnackBar(context, 'Error reset password user: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to search user by name
  void _searchUserByName() {
    String keyword = _searchController.text.toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        filteredUsers = users; // Reset to show all users
      });
      return;
    }

    setState(() {
      filteredUsers = users
          .where((user) => user['name'].toLowerCase().contains(keyword))
          .toList();
    });
  }

  void _searchUserByEmail() {
    String keyword = _searchController.text.toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        filteredUsers = users; // Reset to show all users
      });
      return;
    }

    setState(() {
      filteredUsers = users
          .where((user) => user['email'].toLowerCase().contains(keyword))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Fetch users when widget is initialized
  }

  // Toggle visibility of the search TextField
  void _toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _animationController.forward(); // Start animation
      } else {
        _animationController.reverse();
        _searchController.text = ""; // Reverse animation
      }
    });
  }

  // Function to create route for navigating with custom animation
  Route _createRoute(Widget targetScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide in from the right
        const end = Offset.zero; // End at the normal position
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

  Future<void> _exportData({Map<String, String>? param}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _isLoadingExport = true;
    });
    try {
      final response = await ApiService.apiRequestExportData(
          method: "GET", endpoint: "/user/export", token: token, params: param);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final contentDisposition = response.headers['content-disposition'];
        String? fileName;
        if (contentDisposition != null) {
          final regex = RegExp(r'filename="?([^"]+)"?');
          final match = regex.firstMatch(contentDisposition);
          if (match != null) {
            fileName = match.group(1);
          }
        }
        fileName ??=
            'Export_Data_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.xlsx';

        await _saveDownloadedExcelFile(context, bytes, fileName);
      } else {
        General.showSnackBar(
            context, 'Gagal mengekspor data. Status: ${response.statusCode}');
        print('Response error: ${response.body}');
      }
    } catch (e) {
      General.showSnackBar(context, 'Terjadi kesalahan saat ekspor: $e');
      print('Error: $e');
    }
    setState(() {
      _isLoadingExport = false;
    });
  }

  Future<void> _saveDownloadedExcelFile(
      BuildContext context, List<int> bytes, String fileName) async {
    Directory? directory;

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        directory = Directory("/storage/emulated/0/Download");
      } else {
        General.showSnackBar(context, 'Izin penyimpanan tidak diberikan.');
        openAppSettings();
        return;
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      String basePath = '${directory.path}/$fileName';
      String filePath = basePath;
      int counter = 1;

      while (File(filePath).existsSync()) {
        String nameWithoutExtension = fileName.split('.').first;
        String extension = fileName.split('.').last;
        filePath =
            '${directory.path}/$nameWithoutExtension($counter).$extension';
        counter++;
      }

      try {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);

        General.showSnackBar(
          context,
          'File Excel berhasil diunduh dan disimpan di folder Download',
          durationSeconds: 5,
        );

        print('File berhasil disimpan di: $filePath');
      } catch (e) {
        General.showSnackBar(context, 'Gagal menyimpan file: $e');
        print('Gagal menyimpan file: $e');
      }
    } else {
      General.showSnackBar(context, 'Gagal mendapatkan direktori penyimpanan.');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Refresh data by pulling down
  Future<void> _refreshData() async {
    await fetchUsers();
  }

  Future<void> _needRefresh(bool? need) async {
    if (need != null) {
      await fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.065;
    final fontSize = screenWidth * 0.065;

    return PopScope(
      canPop: !searchUserFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (searchUserFocusNode.hasFocus) {
          searchUserFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (searchUserFocusNode.hasFocus) {
            searchUserFocusNode.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.person, size: iconSize),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    "User Management",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Export button
              Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.02),
                child: CircleAvatar(
                  radius: iconSize * 0.8,
                  backgroundColor: Color.fromARGB(255, 83, 82, 79),
                  child: IconButton(
                    iconSize: iconSize,
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    icon: _isLoadingExport
                        ? SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(Icons.download),
                    onPressed: _exportData,
                  ),
                ),
              ),
              // Add user button
              Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.02),
                child: CircleAvatar(
                  radius: iconSize * 0.8,
                  backgroundColor: Color.fromARGB(255, 1, 161, 49),
                  child: IconButton(
                    iconSize: iconSize,
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        _createRoute(AddUserWidget()),
                      );
                      await _needRefresh(true);
                    },
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search field dengan focus node
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        focusNode: searchUserFocusNode,
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Search by Name or Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close, size: iconSize * 0.6),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        style: TextStyle(fontSize: fontSize * 0.8),
                      ),
                    ),

                    // Konten tabel atau indikator loading
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                            ? Center(child: Text('No users to display'))
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 5),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: Container(
                                      constraints:
                                          BoxConstraints(maxWidth: 900),
                                      child: PaginatedDataTable(
                                        columnSpacing: 16,
                                        horizontalMargin: 5,
                                        rowsPerPage: _rowsPerPage,
                                        sortColumnIndex: _sortColumnIndex,
                                        sortAscending: _sortAscending,
                                        columns: [
                                          DataColumn(
                                              label: SizedBox(
                                                  width: 40,
                                                  child: Text('No'))),
                                          DataColumn(label: Text('Name')),
                                          DataColumn(label: Text('Email')),
                                          DataColumn(label: Text('Role')),
                                          DataColumn(label: Text('Divisi')),
                                          DataColumn(label: Text('Login')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(
                                              label: SizedBox(
                                                  width: 150,
                                                  child: Text('Actions'))),
                                        ],
                                        source: MyDataSource(
                                          filteredUsers,
                                          0,
                                          _rowsPerPage,
                                          context,
                                          _deleteUser,
                                          _resetPassUser,
                                          _needRefresh,
                                        ),
                                      ),
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
    );
  }
}

class MyDataSource extends DataTableSource {
  final List<dynamic> users;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;
  final Function onResetPressed;
  final Future<void> Function(bool) needRefresh;

  Color _getStatusColor(String status) {
    if (status == 'Unlocked') {
      return Colors.green;
    } else if (status == 'Locked') {
      return Colors.red;
    }
    return Colors.black; // Warna default jika status tidak dikenali
  }

  MyDataSource(
    this.users,
    this.pageIndex,
    this.rowsPerPage,
    this.context,
    this.onDeletePressed,
    this.onResetPressed,
    this.needRefresh,
  );

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;
    if (globalRowIndex >= users.length) {
      return null;
    }
    final user = users[index];
    return DataRow(cells: [
      DataCell(Text('${globalRowIndex + 1}')),
      DataCell(Text(user['name'] ?? '')),
      DataCell(Text(user['email'] ?? '')),
      DataCell(
        Text(
          user['role']['name'] ?? '',
        ),
      ),
      DataCell(Text(user['divisi']['name'] ?? '')),
      DataCell(Text(user['login_from'] == '' ? '-' : user['login_from'])),
      DataCell(
        Text(
          user['is_locked'] ? 'Locked' : 'Unlocked',
          style: TextStyle(
              color: _getStatusColor(user['is_locked'] ? 'Locked' : 'Unlocked'),
              fontWeight: FontWeight.bold),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min, // Pastikan row tidak melebar
          children: [
            SizedBox(
              width: 30, // Tetapkan width yang lebih kecil agar tidak melebar
              child: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  int userId = user['id'];
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UpdateUserWidget(userId: userId),
                    ),
                  );
                  await needRefresh(true);
                },
              ),
            ),
            SizedBox(width: 2), // Mengurangi jarak antar ikon
            SizedBox(
              width: 30, // Tetapkan width agar lebih rapat
              child: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  onDeletePressed(user['id']);
                },
              ),
            ),
            SizedBox(width: 2),
            SizedBox(
              width: 30,
              child: IconButton(
                icon: Icon(Icons.lock_reset),
                onPressed: () {
                  onResetPressed(user['id']);
                },
              ),
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
