import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';

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
  bool _isSearchVisible = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;

  // Animation controller for the search TextField
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  Future<void> fetchDivisions() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleDivision(
          method: 'GET', params: {'no_paging': 'yes'});

      if (result != null) {
        setState(() {
          divisions = result['data'];
          filteredDivisions = divisions; // Store original divisions
        });
      }
    } catch (e) {
      General.showSnackBar(context, 'Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
    _searchController.addListener(() {
      _searchDivisionByName();
    });
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
      // _totalItems = filteredDivisions.length;
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
    final TextEditingController nameController = TextEditingController();
    await General.showDialogAdd(
      context: context,
      title: 'Tambah Divisi',
      hintText: 'Masukkan nama divisi',
      controller: nameController,
      headerColor: Colors.green,
      buttonColor: Colors.green[800],
      validate: (value) {
        if (value.isEmpty) {
          return 'Nama divisi tidak boleh kosong';
        }
        if (divisions.any((division) =>
            division['name'].toLowerCase() == value.toLowerCase())) {
          return 'Nama divisi sudah ada!';
        }
        return null;
      },
      onConfirm: (divisionName) async {
        try {
          print("Menambahkan divisi: $divisionName");
          final response = await ApiService.handleDivision(
            method: 'POST',
            data: {'name': divisionName},
          );

          if (response != null && response['success'] == true) {
            print("Divisi berhasil ditambahkan");
            General.showSnackBar(context, 'Divisi berhasil ditambahkan!');
            fetchDivisions();
            return true;
          } else {
            print("Gagal menambahkan divisi: ${response?['message']}");
            General.showSnackBar(
                context, 'Gagal menambahkan divisi: ${response?['message']}');
            return false;
          }
        } catch (e) {
          print("Error saat menambahkan divisi: $e");
          General.showSnackBar(context, 'Error: $e');
          return false;
        }
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

      if (response != null && response['data'] != null) {
        final division = response['data'];
        setState(() {
          nameController.text = division['name'] ?? '';
          _isLoading = false;
        });

        await General.showDialogEdit(
          context: context,
          controller: nameController,
          existingItems: divisions,
          hintText: "Masukkan nama",
          itemName: 'Divisi',
          emptyFieldMessage: 'Nama divisi tidak boleh kosong',
          duplicateMessage: 'Nama divisi sudah ada!',
          onSave: (data) async {
            final updateResponse = await ApiService.handleDivision(
              method: 'PUT',
              divisiId: divisiId,
              data: data,
            );

            if (updateResponse != null && updateResponse['success'] == true) {
              General.showSnackBar(context, 'Divisi berhasil diperbarui!');
              fetchDivisions();
            } else {
              throw Exception('Failed to update division');
            }
          },
        );
      }
    } catch (e) {
      print("Error: $e");
      General.showSnackBar(context, 'Gagal memuat data Division: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDivision(int divisiId) async {
    final confirm = await General.showDialogDelete(
        context: context,
        title: "Hapus Divisi",
        message: "Apakah Anda Yakin Ingin Menghapus Divisi Ini?",
        confirmButtonText: "Hapus",
        cancelButtonText: "Batal");

    if (confirm != null && confirm) {
      try {
        print("Menghapus divisi dengan ID: $divisiId");
        final response = await ApiService.handleDivision(
            method: 'DELETE', divisiId: divisiId);

        if (response != null &&
            response['code'] == 200 &&
            response['success']) {
          General.showSnackBar(context, 'Division deleted successfully!');
          setState(() {
            divisions.removeWhere((division) => division['id'] == divisiId);
          });
        } else {
          General.showSnackBar(context, 'Failed to delete Division');
        }
      } catch (e) {
        General.showSnackBar(context, '$e');
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
              backgroundColor: Color.fromARGB(
                  255, 13, 55, 224), // Set the background color of the circle
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
              backgroundColor: Color.fromARGB(
                  255, 1, 161, 49), // Set the background color of the circle
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
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search by Name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(Icons.close, size: 20),
                                    onPressed: _toggleSearchVisibility,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ),
                                suffixIconConstraints: BoxConstraints(
                                  maxHeight: 32,
                                ),
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                      : Container(),
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

  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;
  final Function onEditPressed;

  MyDataSource(
    this.divisions,
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
    if (globalRowIndex >= divisions.length) {
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
  int get rowCount => divisions.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
