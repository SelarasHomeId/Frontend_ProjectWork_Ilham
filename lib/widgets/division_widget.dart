import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class DivisionWidget extends StatefulWidget {
  @override
  _DivisionWidgetState createState() => _DivisionWidgetState();
}

class _DivisionWidgetState extends State<DivisionWidget> {
  List<dynamic> divisions = [];
  bool _isLoading = true;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 10;
  int _pageIndex = 0;
  int _totalItems = 0;

  Future<void> fetchDivisions() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.handleDivision(
        method: 'GET',
      );

      if (result != null) {
        final params = {
          'limit': result['count'].toString(),
          'offset': _pageIndex.toString(),
        };

        final resultDivision = await ApiService.handleDivision(
          method: 'GET',
          params: params,
        );  
        setState(() {
          divisions = resultDivision['data'];
          _totalItems = resultDivision['count'];
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
    fetchDivisions(); // Ambil data divisions saat widget pertama kali dibangun
  }

  // Fungsi untuk mengurutkan data
  void _sort<T>(Comparable<T> Function(dynamic d) getField, int columnIndex,
      bool ascending) {
    divisions.sort((a, b) {
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
          "Division Management",
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
          : divisions.isEmpty
              ? Center(child: Text('Tidak ada divisi untuk ditampilkan'))
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
                            label: Text('Division Name'),
                            onSort: (columnIndex, ascending) {
                              _sort<String>((division) => division['name'], columnIndex,
                                  ascending);
                            },
                          ),
                          DataColumn(label: Text('Date Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        source: MyDataSource(
                            divisions, _totalItems, _pageIndex, _rowsPerPage),
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

  MyDataSource(this.divisions, this.totalItems, this.pageIndex, this.rowsPerPage);

  @override
  DataRow? getRow(int index) {
    final globalRowIndex = pageIndex * rowsPerPage + index;
    if (globalRowIndex >= totalItems) {
      return null;
    }
    final division = divisions[index];
    return DataRow(cells: [
      DataCell(Text('${globalRowIndex + 1}')),
      DataCell(Text(division['name'] ?? '')),
      DataCell(Text((division['created_at'] ?? '').replaceAll('T', ' ').replaceAll('Z', ''))),
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
