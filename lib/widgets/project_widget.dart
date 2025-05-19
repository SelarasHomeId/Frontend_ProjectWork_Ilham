import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/add_project_widget.dart';
import 'package:selarashomeid/widgets/update_project_widget.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoadingExport = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;

  FocusNode searchProjectFocusNode = FocusNode();

  // Animation controller for the search TextField
  late AnimationController _animationController;

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
    _searchController.addListener(() {
      _searchProjectByName();
    });
  }

  void _deleteProject(int projectId) async {
    final confirm = await General.showDialogConfirmDelete(
        context: context,
        title: "Hapus Project",
        message: "Apakah Anda yakin ingin menghapus project ini?",
        additionalMessage:
            "Menghapus project akan menghapus semua board & task di dalamnya.",
        confirmButtonText: "Hapus",
        cancelButtonText: "Batal");

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
    fetchProjects();
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

  Future<void> _exportData({Map<String, String>? param}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _isLoadingExport = true;
    });
    try {
      final response = await ApiService.apiRequestExportData(
          method: "GET",
          endpoint: "/project/export",
          token: token,
          params: param);

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
    await fetchProjects();
  }

  Future<void> _needRefresh(bool? need) async {
    if (need != null) {
      await fetchProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.065;
    final fontSize = screenWidth * 0.065;

    return PopScope(
      canPop: !searchProjectFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (searchProjectFocusNode.hasFocus) {
          searchProjectFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (searchProjectFocusNode.hasFocus) {
            searchProjectFocusNode.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.add_business, size: iconSize),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    "Project Management",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize * 0.85,
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
              // Add project button
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
                        _createRoute(AddProjectWidget()),
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
                    // Search field dengan focus node di atas tabel
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        focusNode: searchProjectFocusNode,
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Search by Project Name',
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
                        : filteredProjects.isEmpty
                            ? Center(child: Text('No projects to display'))
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 5),
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
                                          onSort: (colIndex, asc) {
                                            _sort<String>(
                                              (project) => project['name'],
                                              colIndex,
                                              asc,
                                            );
                                          },
                                        ),
                                        DataColumn(label: Text('Location')),
                                        DataColumn(label: Text('Cover')),
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
                                        _needRefresh,
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
  void showImagePreview(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  final List<dynamic> projects;

  final int pageIndex;
  final int rowsPerPage;
  final BuildContext context;
  final Function onDeletePressed;
  final Future<void> Function(bool) needRefresh;

  MyDataSource(this.projects, this.pageIndex, this.rowsPerPage, this.context,
      this.onDeletePressed, this.needRefresh);

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;

    if (globalRowIndex >= projects.length) {
      return null;
    }

    final project = projects[index];

    final String? location = project['location'];
    final Uri? locationUri = location != null ? Uri.parse(location) : null;
    final Map<String, dynamic> cover = project['cover'] != null
        ? {
            "view": project["cover"]?["view"] ?? "",
            "content": project["cover"]?["content"] ?? "",
            "id": project["cover"]?["id"] ?? "",
            "name": project["cover"]?["name"] ?? "",
          }
        : {};
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
      DataCell(
        Row(
          children: [
            if (cover.isNotEmpty)
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () async {
                  showImagePreview(context, cover['view']);
                },
              )
            else
              Text('No Cover'),
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
              onPressed: () async {
                int projectId = project['id'];
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateProjectWidget(projectId: projectId),
                  ),
                );
                await needRefresh(true);
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
