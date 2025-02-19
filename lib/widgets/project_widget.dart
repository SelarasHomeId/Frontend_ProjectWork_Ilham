import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectWidget extends StatefulWidget {
  @override
  _ProjectWidgetState createState() => _ProjectWidgetState();
}

class _ProjectWidgetState extends State<ProjectWidget> {
  List<dynamic> projects = [];
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;
  int _totalItems = 0;

  Future<void> fetchProjects() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleProject(
        method: 'GET',
      );

      if (result != null) {
        final params = {
          'limit': result['count'].toString(),
          'offset': _pageIndex.toString(),
        };

        final resultProject = await ApiService.handleProject(
          method: 'GET',
          params: params,
        );  
        setState(() {
          projects = resultProject['data'];
          _totalItems = resultProject['count'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProjects(); // Ambil data projects saat widget pertama kali dibangun
  }

  // Fungsi untuk mengurutkan data
  void _sort<T>(Comparable<T> Function(dynamic d) getField, int columnIndex,
      bool ascending) {
    projects.sort((a, b) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Project Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? Center(child: Text('Tidak ada proyek untuk ditampilkan'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context)
                          .size
                          .width, // Menentukan ukuran
                      child: PaginatedDataTable(
                        rowsPerPage: _rowsPerPage,
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(label: Text('No')),
                          DataColumn(
                            label: Text('Project Name'),
                            onSort: (columnIndex, ascending) {
                              _sort<String>((project) => project['name'], columnIndex,
                                  ascending);
                            },
                          ),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Date Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        source: MyDataSource(
                            projects, _totalItems, _pageIndex, _rowsPerPage, context),
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

  MyDataSource(this.projects, this.totalItems, this.pageIndex, this.rowsPerPage, this.context);

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;
    
    // Cegah akses di luar batas list
    if (index >= projects.length) {
      return null;
    }

    final project = projects[index];
    return DataRow(cells: [
      DataCell(Text('${globalRowIndex + 1}')),
      DataCell(Text(project['name'] ?? '')),
      DataCell(
        IconButton(
          icon: Icon(Icons.location_on, color: Colors.blue),
          onPressed: () async {
            final String? url = project['location'];
            if (url != null && url.isNotEmpty) {
              final Uri uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tidak dapat membuka link: $url')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('URL tidak tersedia')),
              );
            }
          },
        ),
      ),
      DataCell(Text((project['created_at'] ?? '').replaceAll('T', ' ').replaceAll('Z', ''))),
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
