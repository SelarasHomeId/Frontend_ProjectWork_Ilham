import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class DivisionWidget extends StatefulWidget {
  @override
  _DivisionWidgetState createState() => _DivisionWidgetState();
}

class _DivisionWidgetState extends State<DivisionWidget>
    with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  List<dynamic> divisions = [];
  List<dynamic> filteredDivisions = [];
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

  Future<void> fetchDivisions() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleDivision(method: 'GET');

      if (result != null) {
        final params = {
          'limit': result['count'].toString(),
          'offset': _pageIndex.toString(),
        };

        final resultDivision =
            await ApiService.handleDivision(method: 'GET', params: params);
        setState(() {
          divisions = resultDivision['data'];
          filteredDivisions = divisions; // Store original divisions
          _totalItems = resultDivision['count'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Search function for divisions
  void _searchDivisionByName() {
    String keyword = _searchController.text.toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        filteredDivisions = divisions; // Reset to show all divisions
      });
      return;
    }

    setState(() {
      filteredDivisions = divisions
          .where((division) => division['name'].toLowerCase().contains(keyword))
          .toList();
      _totalItems = filteredDivisions.length;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchDivisions(); // Fetch divisions when widget is initialized

    // Initialize the animation controller for the search TextField
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0))
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOut));
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
    filteredDivisions.sort((a, b) {
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

  Future<void> _addDivision() async {
    showDialog(
      context: context,
      builder: (context) {
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
                  color: Colors.green,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Tambah Divisi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama divisi',
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
                      backgroundColor: Colors.grey[600],
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
                    onPressed: () async {
                      final divisionName = nameController.text.trim();
                      if (divisionName.isEmpty) {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Nama divisi tidak boleh kosong'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin:
                                EdgeInsets.only(top: 20, left: 20, right: 20),
                          ),
                        );
                        return;
                      }

                      bool isDuplicate = divisions.any((division) =>
                          division['name'].toLowerCase() ==
                          divisionName.toLowerCase());
                      if (isDuplicate) {
                        Navigator.of(context).pop();
                        Future.delayed(Duration(milliseconds: 100), () {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nama divisi sudah ada!'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              margin:
                                  EdgeInsets.only(top: 20, left: 20, right: 20),
                            ),
                          );
                        });
                        return;
                      }

                      try {
                        print("Menambahkan divisi: $divisionName");
                        final response = await ApiService.handleDivision(
                          method: 'POST',
                          data: {'name': divisionName},
                        );

                        if (response != null && response['success'] == true) {
                          print("Divisi berhasil ditambahkan");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Divisi berhasil ditambahkan!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          fetchDivisions();
                          nameController.text = "";
                          Navigator.pop(context);
                        } else {
                          print(
                              "Gagal menambahkan divisi: ${response?['message']}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Gagal menambahkan divisi: ${response?['message']}'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      } catch (e) {
                        print("Error saat menambahkan divisi: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Simpan',
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
  }

  Future<void> _editDivision(int divisiId) async {
    print("Fetching divisi data for ID: $divisiId");
    try {
      final response = await ApiService.handleDivision(
        method: 'GET',
        divisiId: divisiId,
      );
      print("Response received: $response");

      if (response != null && response['data'] != null) {
        final division = response['data'];
        print("Project Data: $divisions");

        setState(() {
          nameController.text = division['name'] ?? '';
          _isLoading = false;
        });
      } else {
        print("No Division data found");
      }
    } catch (e) {
      print("Error fetching Division data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data Division: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }

    showDialog(
      context: context,
      builder: (context) {
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
                  color: Colors.green,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Edit Divisi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama divisi',
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
                      backgroundColor: Colors.grey[600],
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
                    onPressed: () async {
                      final divisionName = nameController.text.trim();
                      if (divisionName.isEmpty) {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Nama divisi tidak boleh kosong'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin:
                                EdgeInsets.only(top: 20, left: 20, right: 20),
                          ),
                        );
                        return;
                      }

                      bool isDuplicate = divisions.any((division) =>
                          division['name'].toLowerCase() ==
                          divisionName.toLowerCase());
                      if (isDuplicate) {
                        Navigator.of(context).pop();
                        Future.delayed(Duration(milliseconds: 100), () {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nama divisi sudah ada!'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              margin:
                                  EdgeInsets.only(top: 20, left: 20, right: 20),
                            ),
                          );
                        });
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Konfirmasi"),
                            content: Text(
                                "Apakah Anda yakin ingin mengubah data project ini?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text("Batal"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text("Ya, Ubah"),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm != null && confirm) {
                        final data = {
                          'name': nameController.text,
                        };

                        print("Updating divisi with data: $data");
                        try {
                          // Membuat form data dengan file
                          final data = {
                            'name': nameController.text,
                          };

                          // Panggil API service dengan file
                          final response = await ApiService.handleDivision(
                            method: 'PUT',
                            divisiId: divisiId,
                            data: data,
                          );
                          print("Update Response: $response");

                          if (response != null && response['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Divisi berhasil diperbarui!')),
                            );
                            fetchDivisions();
                            nameController.text = "";
                            Navigator.pop(context);
                          } else {
                            print("Failed to update divisi");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal memperbarui divisi')),
                            );
                          }
                        } catch (e) {
                          print("Error updating divisi: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal memperbarui divisi: $e')),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Simpan',
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
  }

  Future<void> _deleteDivision(int divisiId) async {
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
                  color: Colors.red,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hapus Divisi',
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
                  'Apakah Anda yakin ingin menghapus divisi ini?',
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
                      backgroundColor: Colors.grey[600],
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
                    onPressed: () =>
                        {fetchDivisions(), Navigator.of(context).pop(true)},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[800],
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
        print("Menghapus divisi dengan ID: $divisiId");
        final response = await ApiService.handleDivision(
            method: 'DELETE', divisiId: divisiId);

        if (response != null &&
            response['code'] == 200 &&
            response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Division deleted successfully!')));
          setState(() {
            divisions.removeWhere((division) => division['id'] == divisiId);
            _totalItems--;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete Division')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting Division: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Refresh data by pulling down
  Future<void> _refreshData() async {
    await fetchDivisions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Division Management",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                  _addDivision();
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
                                      labelText: 'Search by Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (text) {
                                      _searchDivisionByName();
                                    },
                                  ),
                                ),
                                // Icon button for closing search
                                IconButton(
                                  icon: Icon(Icons.cancel, size: 20),
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
                    : filteredDivisions.isEmpty
                        ? Center(child: Text('No divisions to display'))
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
                                      label: Text('Division Name'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (division) => division['name'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(label: Text('Date Created')),
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
                                      filteredDivisions,
                                      _totalItems,
                                      _pageIndex,
                                      _rowsPerPage,
                                      context,
                                      _deleteDivision,
                                      _editDivision),
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
  final List<dynamic> divisions;
  final int totalItems;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;
  final Function onEditPressed;

  MyDataSource(
    this.divisions,
    this.totalItems,
    this.pageIndex,
    this.rowsPerPage,
    this.context,
    this.onDeletePressed,
    this.onEditPressed,
  );

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;

    // Cegah akses di luar batas list
    if (globalRowIndex >= totalItems) {
      return null;
    }

    final division = divisions[index];
    return DataRow(cells: [
      DataCell(Text('${globalRowIndex + 1}')),
      DataCell(Text(division['name'] ?? '')),
      DataCell(Text((division['created_at'] ?? '')
          .replaceAll('T', ' ')
          .replaceAll('Z', ''))),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                onEditPressed(division['id']);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                onDeletePressed(division['id']);
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
