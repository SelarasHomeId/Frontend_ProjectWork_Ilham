import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/update_user_widget.dart';
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
  bool _isSearchVisible = false; // Flag to toggle the visibility of search
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;
  int _totalItems = 0;

  // Animation controller for the search TextField
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleUser(method: 'GET');

      if (result != null) {
        final params = {
          'limit': result['count'].toString(),
          'offset': _pageIndex.toString(),
        };

        final resultUser =
            await ApiService.handleUser(method: 'GET', params: params);
        setState(() {
          users = resultUser['data'];
          filteredUsers = users; // Store original users
          _totalItems = resultUser['count'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User deleted successfully!')));
          setState(() {
            users.removeWhere((user) => user['id'] == userId);
            _totalItems--;
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to delete user')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
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
      _totalItems = filteredUsers.length;
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
        _animationController.reverse(); // Reverse animation
      }
    });
  }

  // Function for sorting data
  void _sort<T>(Comparable<T> Function(dynamic d) getField, int columnIndex,
      bool ascending) {
    filteredUsers.sort((a, b) {
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
                onPressed: () {
                  Navigator.of(context).push(
                    _createRoute(AddUserWidget()),
                  );
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
            padding: EdgeInsets.all(2.0),
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
                                      labelText: 'Search by Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (text) {
                                      _searchUserByName();
                                    },
                                  ),
                                ),
                                // Icon button for closing search
                                IconButton(
                                  icon: Icon(Icons.cancel,
                                      size: 20), // Small close icon
                                  onPressed:
                                      _toggleSearchVisibility, // Close search field
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(), // When search is not visible, show an empty container
                ),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                        ? Center(child: Text('No users to display'))
                        : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: PaginatedDataTable(
                                  columnSpacing: 20,
                                  horizontalMargin: 12,
                                  rowsPerPage: _rowsPerPage,
                                  sortColumnIndex: _sortColumnIndex,
                                  sortAscending: _sortAscending,
                                  columns: [
                                    DataColumn(label: Text('No')),
                                    DataColumn(
                                      label: Text('Name'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>((user) => user['name'],
                                            columnIndex, ascending);
                                      },
                                    ),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Role')),
                                    DataColumn(label: Text('Divisi')),
                                    DataColumn(label: Text('Login ')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(
                                      label: IntrinsicWidth(
                                        child: Container(
                                          width: 120,
                                          child: Text('Actions'),
                                        ),
                                      ),
                                    ),
                                  ],
                                  source: MyDataSource(
                                    filteredUsers,
                                    _totalItems,
                                    0,
                                    _rowsPerPage,
                                    context,
                                    _deleteUser,
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
  final int totalItems;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;

  MyDataSource(
    this.users,
    this.totalItems,
    this.pageIndex,
    this.rowsPerPage,
    this.context,
    this.onDeletePressed,
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
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                int userId = user['id'];
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UpdateUserWidget(userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                onDeletePressed(user['id']);
              },
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
