import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/update_user_widget.dart';
import 'package:selarashomeid/utils/general.dart';
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
  bool _isSearchVisible = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;

  // Animation controller for the search TextField
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red, // Mengubah warna menjadi merah
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete, // Menambahkan ikon tong sampah
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hapus Pengguna',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Apakah Anda yakin ingin menghapus user ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.grey[600], // Warna abu-abu untuk Cancel
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.red[800], // Warna merah untuk Delete
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );

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

    // Initialize the animation controller for the search TextField
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1), // Start from above
      end: Offset(0, 0), // End at normal position
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, size: 30), // Icon pengguna
            SizedBox(width: 8), // Jarak antara ikon dan teks
            Text(
              "User Management",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor:
                  Color(0xFFC0BCB5), // Set the background color of the circle
              child: IconButton(
                icon: Icon(Icons.search),
                color: Colors.white, // Set the icon color
                onPressed:
                    _toggleSearchVisibility, // Toggle visibility of search TextField
                padding:
                    EdgeInsets.zero, // Remove padding inside the CircleAvatar
                iconSize: 28, // Adjust the size of the icon
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20, // Set the size of the CircleAvatar
              backgroundColor:
                  Color(0xFF4A6C6F), // Set the background color of the circle
              child: IconButton(
                icon: Icon(Icons.add),
                color: Colors.white, // Set the icon color
                onPressed: () async {
                  await Navigator.of(context).push(
                    _createRoute(AddUserWidget()),
                  );
                  await _needRefresh(true);
                },
                padding:
                    EdgeInsets.zero, // Remove padding inside the CircleAvatar
                iconSize: 28, // Adjust the size of the icon
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Trigger to fetch new data
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _isSearchVisible
                      ? SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      labelText: 'Search by Name or Email',
                                      border: OutlineInputBorder(),
                                    ),
                                    // onChanged: (text) {
                                    // },
                                  ),
                                ),
                                // Icon button for closing search
                                IconButton(
                                  icon: Icon(Icons.cancel,
                                      size: 20), // Small close icon
                                  onPressed: _toggleSearchVisibility,
                                  // Close search field
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(),
                ),
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
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          900), // Maksimal 900px agar tidak terlalu luas
                                  child: PaginatedDataTable(
                                    columnSpacing: 16,
                                    horizontalMargin: 5,
                                    rowsPerPage: _rowsPerPage,
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _sortAscending,
                                    columns: [
                                      DataColumn(
                                          label: SizedBox(
                                              width: 40, child: Text('No'))),
                                      DataColumn(label: Text('Name')),
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Role')),
                                      DataColumn(label: Text('Divisi')),
                                      DataColumn(label: Text('Login')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(
                                          label: SizedBox(
                                              width: 100,
                                              child: Text('Actions'))),
                                    ],
                                    source: MyDataSource(
                                      filteredUsers,
                                      0,
                                      _rowsPerPage,
                                      context,
                                      _deleteUser,
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
    );
  }
}

class MyDataSource extends DataTableSource {
  final List<dynamic> users;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;
  final Future<void> Function(bool) needRefresh;

  MyDataSource(
    this.users,
    this.pageIndex,
    this.rowsPerPage,
    this.context,
    this.onDeletePressed,
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
      DataCell(Text(user['role']['name'] ?? '')),
      DataCell(Text(user['divisi']['name'] ?? '')),
      DataCell(Text(user['login_from'] == '' ? '-' : user['login_from'])),
      DataCell(Text(user['is_locked'] ? 'Locked' : 'Unlocked')),
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
