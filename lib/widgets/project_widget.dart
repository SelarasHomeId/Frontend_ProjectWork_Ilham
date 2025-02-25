import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/add_project_widget.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:selarashomeid/widgets/update_project_widget.dart';

class ProjectWidget extends StatefulWidget {
  @override
  _ProjectWidgetState createState() => _ProjectWidgetState();
}

class _ProjectWidgetState extends State<ProjectWidget>
    with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> projects = [];
  List<dynamic> filteredProjects = [];
  bool _isLoading = true;
  bool _isSearchVisible = false; // Flag to toggle search visibility
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;
  int _totalItems = 0;

  // Animation controller for the search TextField
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  Future<void> fetchProjects() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleProject(method: 'GET');

      if (result != null) {
        final params = {
          'limit': result['count'].toString(),
          'offset': _pageIndex.toString(),
        };

        final resultProject =
            await ApiService.handleProject(method: 'GET', params: params);
        setState(() {
          projects = resultProject['data'];
          filteredProjects = projects; // Store original projects
          _totalItems = resultProject['count'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Function to search projects by name
  void _searchProjectByName() {
    String keyword = _searchController.text.toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        filteredProjects = projects; // Reset to show all projects
      });
      return;
    }

    setState(() {
      filteredProjects = projects
          .where((project) => project['name'].toLowerCase().contains(keyword))
          .toList();
      _totalItems = filteredProjects.length;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProjects(); // Fetch projects when widget is initialized

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
    filteredProjects.sort((a, b) {
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
    await fetchProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Project Management",
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
          // Add project button with "+" icon only
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.add), // "+" icon
              onPressed: () {
                Navigator.of(context).push(
                  _createRoute(AddProjectWidget()),
                ); // Go to add project screen
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
                                      labelText: 'Search by Project Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (text) {
                                      _searchProjectByName();
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
                    : filteredProjects.isEmpty
                        ? Center(child: Text('No projects to display'))
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
                                      label: Text('Project Name'),
                                      onSort: (columnIndex, ascending) {
                                        _sort<String>(
                                            (project) => project['name'],
                                            columnIndex,
                                            ascending);
                                      },
                                    ),
                                    DataColumn(label: Text('Location')),
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
                                    filteredProjects,
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
  final List<dynamic> projects;
  final int totalItems;
  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;

  MyDataSource(this.projects, this.totalItems, this.pageIndex, this.rowsPerPage,
      this.context);

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;

    if (index >= projects.length) {
      return null;
    }

    final project = projects[index];

    final String? location = project['location'];
    final Uri? locationUri = location != null ? Uri.parse(location) : null;
    return DataRow(cells: [
      DataCell(Text('${globalRowIndex + 1}')),
      DataCell(Text(project['name'] ?? '')),
      DataCell(
        Row(
          children: [
            // If location URL is valid, show the location icon
            if (locationUri != null && locationUri.isAbsolute)
              IconButton(
                icon: Icon(Icons.location_on),
                onPressed: () async {
                  // Open Google Maps using the URL
                  try {
                    await launchUrl(locationUri);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open the map.')),
                    );
                  }
                },
              )
            else
              Text('No Location'),
          ],
        ),
      ),
      DataCell(Text((project['created_at'] ?? '')
          .replaceAll('T', ' ')
          .replaceAll('Z', ''))),
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
