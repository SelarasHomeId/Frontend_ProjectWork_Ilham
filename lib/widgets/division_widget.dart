import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class DivisionWidget extends StatefulWidget {
  @override
  _DivisionWidgetState createState() => _DivisionWidgetState();
}

class _DivisionWidgetState extends State<DivisionWidget>
    with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
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
          // Search button
          IconButton(
            icon: Icon(Icons.search),
            onPressed:
                _toggleSearchVisibility, // Toggle visibility of search TextField
          ),
          // Add division button with "+" icon only
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.add), // "+" icon
              onPressed: () {
                // Navigate to add division screen
              },
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
  final List<dynamic> divisions;
  final int totalItems;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;

  MyDataSource(this.divisions, this.totalItems, this.pageIndex,
      this.rowsPerPage, this.context);

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
      DataCell(Text(division['created_at'] ?? '')),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Add navigation for edit
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Add delete functionality
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
