import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/add_project_widget.dart';
import 'package:selarashomeid/widgets/update_project_widget.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // int _totalItems = 0;

  // Animation controller for the search TextField
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  Future<void> fetchProjects() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleProject(
          method: 'GET', params: {'no_paging': 'yes'});

      if (result != null) {
        setState(() {
          projects = result['data'];
          filteredProjects = projects; // Store original projects
        });
      }
    } catch (e) {
      General.showSnackBar(context, 'Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteProject(int projectId) async {
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
                'Hapus Project',
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
                  'Apakah Anda yakin ingin menghapus project ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Menghapus project akan menghapus semua board & task di dalamnya.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
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
        final response = await ApiService.handleProject(
            method: 'DELETE', projectId: projectId);

        if (response != null &&
            response['code'] == 200 &&
            response['success']) {
          General.showSnackBar(context, 'Project deleted successfully!');
          setState(() {
            projects.removeWhere((project) => project['id'] == projectId);
          });
        } else {
          General.showSnackBar(context, 'Failed to delete project');
        }
      } catch (e) {
        General.showSnackBar(context, 'Error deleting project: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: Row(
          children: [
            Icon(Icons.add_business, size: 30), // Icon pengguna
            SizedBox(width: 8), // Jarak antara ikon dan teks
            Text(
              "Project Management",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                    _createRoute(AddProjectWidget()),
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
        onRefresh: _refreshData,
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
                                    _pageIndex,
                                    _rowsPerPage,
                                    context,
                                    _deleteProject,
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

  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;

  MyDataSource(this.projects, this.pageIndex, this.rowsPerPage, this.context,
      this.onDeletePressed);

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;

    if (globalRowIndex >= projects.length) {
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
                    General.showSnackBar(context, 'Could not open the map');
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
          mainAxisSize: MainAxisSize.min, // Supaya hanya sebesar isi
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                int projectId = project['id'];
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateProjectWidget(projectId: projectId),
                  ),
                );
              },
              visualDensity:
                  VisualDensity.compact, // Memperkecil padding default
            ),
            SizedBox(width: 4), // Mengurangi jarak antar ikon
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                onDeletePressed(project['id']);
              },
              visualDensity:
                  VisualDensity.compact, // Memperkecil padding default
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  int get rowCount => projects.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
