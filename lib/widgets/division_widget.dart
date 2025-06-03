import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoadingExport = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;

  FocusNode searchDivisionFocusNode = FocusNode();

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
    fetchDivisions();
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

  Future<void> _exportData({Map<String, String>? param}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _isLoadingExport = true;
    });
    try {
      final response = await ApiService.apiRequestExportData(
          method: "GET",
          endpoint: "/divisi/export",
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

  // Refresh data by pulling down
  Future<void> _refreshData() async {
    await fetchDivisions();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.065;
    final fontSize = screenWidth * 0.065;

    return PopScope(
      canPop: !searchDivisionFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (searchDivisionFocusNode.hasFocus) {
          searchDivisionFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (searchDivisionFocusNode.hasFocus) {
            searchDivisionFocusNode.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.business, size: iconSize),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    "Division Management",
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
              // Add division button
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
                    onPressed: _addDivision,
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
                        focusNode: searchDivisionFocusNode,
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Search by Division',
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
                        : filteredDivisions.isEmpty
                            ? Center(child: Text('No divisions to display'))
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
                                          label: Text('Division Name'),
                                          onSort: (colIndex, asc) {
                                            _sort<String>(
                                              (division) => division['name'],
                                              colIndex,
                                              asc,
                                            );
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
                                        _editDivision,
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
