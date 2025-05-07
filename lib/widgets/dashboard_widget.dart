import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as Excel;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:selarashomeid/utils/general.dart';

class DashboardWidget extends StatefulWidget {
  final int roleId;
  final String token;

  DashboardWidget({required this.roleId, required this.token});

  @override
  _DashboardWidgetState createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  String _userName = '';
  Map<String, dynamic>? _chartData;
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _basecontacts = [];
  List<Map<String, dynamic>> _affiliates = [];
  List<Map<String, dynamic>> _baseaffiliates = [];
  List<Map<String, dynamic>> _calculateTaskData = [];
  int _selectedWorkspaceIndex = 0;

  bool _isLoadingContacts = false;
  bool _isLoadingAffiliate = false;
  int _rowsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  TextEditingController _searchMessageController = TextEditingController();
  FocusNode _searchMessageFocusNode = FocusNode();
  TextEditingController _searchAffiliateController = TextEditingController();
  FocusNode _searchAffiliateFocusNode = FocusNode();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchData();
    _fetchContacts();
    _fetchAffiliates();
    _fetchCalculateTask();
  }

  @override
  void dispose() {
    _searchMessageController.dispose();
    _searchMessageFocusNode.dispose();
    _searchAffiliateController.dispose();
    _searchAffiliateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'Pengguna';
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoadingContacts = true;
      _isLoadingAffiliate = true;
    });

    await _fetchData();
    await _fetchContacts();
    await _fetchAffiliates();

    setState(() {
      _isLoadingContacts = false;
      _isLoadingAffiliate = false;
    });
  }

  Future<void> _fetchData() async {
    final data = await ApiService.fetchDashboard(widget.token);
    setState(() {
      _chartData = data?['data'];
    });
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoadingContacts = true);

    try {
      final result = await ApiService.handleContacts(
        token: widget.token,
        params: {'no_paging': 'yes'},
      );

      if (result != null && result['data'] != null) {
        final responseData = result['data'];
        final List<dynamic> contactsData =
            responseData is List ? responseData : responseData['data'] ?? [];

        setState(() {
          _contacts = contactsData
              .map((data) => Map<String, dynamic>.from(data))
              .toList();
          _basecontacts = List.from(_contacts);
        });
      }
    } catch (e) {
      //print("Error fetching contacts: $e, $stackTrace");
      General.showSnackBar(context, 'Gagal memuat kontak: ${e.toString()}');
    } finally {
      setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _fetchAffiliates() async {
    setState(() => _isLoadingAffiliate = true);

    try {
      final result = await ApiService.handleAffiliates(
        token: widget.token,
        params: {'no_paging': 'yes'},
      );

      if (result != null && result['data'] != null) {
        final responseData = result['data'];
        final List<dynamic> affiliateData =
            responseData is List ? responseData : responseData['data'] ?? [];

        setState(() {
          _affiliates = affiliateData
              .map((data) => Map<String, dynamic>.from(data))
              .toList();
          _baseaffiliates = List.from(_affiliates);
        });
      }
    } catch (e) {
      // print("Error fetching affiliate: $e, $stackTrace");
      General.showSnackBar(context, 'Gagal memuat affiliate: ${e.toString()}');
    } finally {
      setState(() => _isLoadingAffiliate = false);
    }
  }

  void _searchByMessage(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _contacts = List.from(_basecontacts);
        Text("Pesan tidak ditemukan");
      } else {
        _contacts = _basecontacts
            .where((contact) =>
                (contact['name'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (contact['email'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (contact['phone'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (contact['message'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()))
            .toList();
      }
    });
  }

  void _searchByInfo(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _affiliates = List.from(_baseaffiliates);
      } else {
        _affiliates = _baseaffiliates
            .where((affiliate) =>
                (affiliate['name'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (affiliate['email'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (affiliate['phone'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (affiliate['instagram'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (affiliate['tiktok'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()) ||
                (affiliate['info'] ?? '')
                    .toLowerCase()
                    .contains(keyword.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _exportMessagingData() async {
    var excel = Excel.Excel.createExcel();
    Excel.Sheet sheetObject = excel['Messaging Data'];

    // Tambahkan header
    sheetObject.appendRow([
      Excel.TextCellValue('No'),
      Excel.TextCellValue('Name'),
      Excel.TextCellValue('Email'),
      Excel.TextCellValue('Phone'),
      Excel.TextCellValue('Message'),
      Excel.TextCellValue('Created At'),
    ]);

    // Tambahkan data dari list _contacts
    for (var i = 0; i < _contacts.length; i++) {
      sheetObject.appendRow([
        Excel.TextCellValue((i + 1).toString()),
        Excel.TextCellValue(_contacts[i]['name']),
        Excel.TextCellValue(_contacts[i]['email']),
        Excel.TextCellValue(_contacts[i]['phone']),
        Excel.TextCellValue(_contacts[i]['message']),
        Excel.TextCellValue(DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(_contacts[i]['created_at'].toString()))),
      ]);
    }

    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    String fileName = 'Messaging_Data_$timestamp.xlsx';

    // Simpan file
    await _saveExcelFile(context, excel, fileName);
  }

  // Fungsi untuk membuat file Excel dari data Affiliate Request
  Future<void> _exportAffiliateData() async {
    var excel = Excel.Excel.createExcel();
    Excel.Sheet sheetObject = excel['Affiliate Data'];

    // Tambahkan header
    sheetObject.appendRow([
      Excel.TextCellValue('No'),
      Excel.TextCellValue('Name'),
      Excel.TextCellValue('Email'),
      Excel.TextCellValue('Phone'),
      Excel.TextCellValue('Instagram'),
      Excel.TextCellValue('TikTok'),
      Excel.TextCellValue('Info'),
      Excel.TextCellValue('Created At'),
    ]);

    // Tambahkan data dari list _affiliates
    for (var i = 0; i < _affiliates.length; i++) {
      sheetObject.appendRow([
        Excel.TextCellValue((i + 1).toString()),
        Excel.TextCellValue(_affiliates[i]['name']),
        Excel.TextCellValue(_affiliates[i]['email']),
        Excel.TextCellValue(_affiliates[i]['phone']),
        Excel.TextCellValue(_affiliates[i]['instagram']),
        Excel.TextCellValue(_affiliates[i]['tiktok']),
        Excel.TextCellValue(_affiliates[i]['info']),
        Excel.TextCellValue(DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(_affiliates[i]['created_at'].toString()))),
      ]);
    }

    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    String fileName = 'Affiliate_Data_$timestamp.xlsx';

    // Simpan file
    await _saveExcelFile(context, excel, fileName);
  }

  // Fungsi untuk menyimpan file Excel
  Future<void> _saveExcelFile(
      BuildContext context, Excel.Excel excel, String fileName) async {
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
      String filePath = '${directory.path}/$fileName';

      try {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.encode()!);

        General.showSnackBar(
            context, 'File Excel berhasil disimpan di folder Download',
            durationSeconds: 5);

        print('File berhasil disimpan di: $filePath');
      } catch (e) {
        General.showSnackBar(context, 'Gagal menyimpan file: $e');
        print('Gagal menyimpan file: $e');
      }
    } else {
      General.showSnackBar(context, 'Gagal mendapatkan direktori penyimpanan.');
    }
  }

  Future<void> _fetchCalculateTask() async {
    setState(() => _isLoadingAffiliate = true);
    try {
      final response = await ApiService.calculateTask();
      setState(() {
        _calculateTaskData = (response as List).map((workspace) {
          return {
            "workspace_name": workspace["workspace"], // Sesuaikan key dari API
            "boards": (workspace["board"] != null && workspace["board"] is List)
                ? (workspace["board"] as List).map((board) {
                    return {
                      "count_task": board["count_task"], // Ambil jumlah task
                      "name": board["name"], // Ambil nama board
                      "has_new": board["has_new"],
                      "updated_at": board["updated_at"],
                    };
                  }).toList()
                : [], // Jika null, set default list kosong
          };
        }).toList();
      });
    } catch (e) {
      // print("Error fetching calculate task: $e, $stackTrace");
      General.showSnackBar(context, 'Gagal memuat affiliate: ${e.toString()}');
    } finally {
      setState(() => _isLoadingAffiliate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_searchMessageFocusNode.hasFocus &&
          !_searchAffiliateFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (_searchMessageFocusNode.hasFocus) {
          _searchMessageFocusNode.unfocus();
        }
        if (_searchAffiliateFocusNode.hasFocus) {
          _searchAffiliateFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _searchMessageFocusNode.unfocus();
          _searchAffiliateFocusNode
              .unfocus(); // Tutup keyboard saat tap di luar search bar
        },
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kontainer Selamat Datang
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: _containerDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.0),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Summary',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),

                        // Workspace selection buttons
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _calculateTaskData.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _selectedWorkspaceIndex == index
                                            ? Colors.blue[800]
                                            : Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedWorkspaceIndex = index;
                                    });
                                  },
                                  child: Text(
                                    _calculateTaskData[index]['workspace_name'],
                                    style: TextStyle(
                                      color: _selectedWorkspaceIndex == index
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Display boards
                        if (_isLoadingAffiliate)
                          Center(child: CircularProgressIndicator()),
                        if (_calculateTaskData.isNotEmpty)
                          _calculateTaskData[_selectedWorkspaceIndex]
                                          ['boards'] !=
                                      null &&
                                  _calculateTaskData[_selectedWorkspaceIndex]
                                          ['boards']
                                      .isNotEmpty
                              ? SizedBox(
                                  height: 145,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _calculateTaskData[
                                            _selectedWorkspaceIndex]['boards']
                                        .length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      final board = _calculateTaskData[
                                              _selectedWorkspaceIndex]['boards']
                                          [index];
                                      return Container(
                                        width: 280,
                                        margin: EdgeInsets.all(10),
                                        child: createCard(
                                          label1:
                                              'Count: ${board["count_task"].toString()}',
                                          label2: board['has_new'] == true
                                              ? 'Has New!'
                                              : '',
                                          description: board['name'],
                                          date: DateFormat(
                                                  'EEE, dd MMM y | hh:MM:ss')
                                              .format(DateTime.parse(
                                                      board['updated_at'])
                                                  .toLocal()),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      "No boards to display",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                        if (_calculateTaskData.isEmpty)
                          Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),

                  SizedBox(height: 10.0),

                  // Social Media Engagement Pie Chart
                  if (_chartData != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      decoration: _containerDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Social Media Engagement',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Jumlah Klik Mengakses Social Media Melalui Website',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(height: 10),
                          PieChart(
                            dataMap: {
                              'Instagram':
                                  _chartData!['count_instagram'].toDouble(),
                              'Tiktok': _chartData!['count_tiktok'].toDouble(),
                              'Facebook':
                                  _chartData!['count_facebook'].toDouble(),
                              'Whatsapp':
                                  _chartData!['count_whatsapp'].toDouble(),
                            },
                            animationDuration: Duration(milliseconds: 800),
                            chartLegendSpacing: 32,
                            chartRadius:
                                MediaQuery.of(context).size.width / 3.2,
                            colorList: [
                              Color.fromARGB(255, 246, 1, 8),
                              Color.fromARGB(255, 0, 0, 0),
                              Color.fromARGB(255, 1, 0, 138),
                              Color.fromARGB(255, 128, 255, 0),
                            ],
                            gradientList: [],
                            initialAngleInDegree: 0,
                            chartType: ChartType.disc,
                            ringStrokeWidth: 32,
                            legendOptions: LegendOptions(
                              showLegendsInRow: false,
                              legendPosition: LegendPosition.right,
                              showLegends: true,
                              legendShape: BoxShape.circle,
                              legendTextStyle:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            chartValuesOptions: ChartValuesOptions(
                              showChartValueBackground: false,
                              showChartValues: true,
                              showChartValuesInPercentage: false,
                              showChartValuesOutside: false,
                              decimalPlaces: 0,
                              chartValueStyle: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Affiliate & Contact Pie Chart
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      decoration: _containerDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Affiliate and Contact',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Jumlah Klik Pada Affiliate dan Kontak Melalui Website',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.normal),
                          ),
                          SizedBox(height: 10),
                          PieChart(
                            dataMap: {
                              'Affiliate':
                                  _chartData!['count_affiliate'].toDouble(),
                              'Contact':
                                  _chartData!['count_contact'].toDouble(),
                            },
                            animationDuration: Duration(milliseconds: 800),
                            chartLegendSpacing: 32,
                            chartRadius:
                                MediaQuery.of(context).size.width / 3.2,
                            colorList: [
                              Color.fromARGB(255, 104, 201, 208),
                              Color.fromARGB(255, 226, 48, 108),
                            ],
                            initialAngleInDegree: 0,
                            chartType: ChartType.disc,
                            ringStrokeWidth: 40,
                            legendOptions: LegendOptions(
                              showLegendsInRow: false,
                              legendPosition: LegendPosition.right,
                              showLegends: true,
                              legendShape: BoxShape.circle,
                              legendTextStyle:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            chartValuesOptions: ChartValuesOptions(
                              showChartValueBackground: false,
                              showChartValues: true,
                              showChartValuesInPercentage: false,
                              showChartValuesOutside: false,
                              decimalPlaces: 0,
                              chartValueStyle: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(child: CircularProgressIndicator()),
                  ],
                  SizedBox(height: 10.0),

                  // Kontainer Messaging dengan Tabel Contact
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: _containerDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Messaging',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              onPressed: _exportMessagingData,
                              icon: Icon(Icons.file_download),
                              label: Text('Unduh Data'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Data Pesan, Pertanyaan dan Kontak Melalui Website, klik untuk melihat detail pesan',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.normal),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _searchMessageController,
                          focusNode: _searchMessageFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Cari...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (text) {
                            _searchByMessage(text);
                          },
                        ),
                        SizedBox(height: 10.0),
                        _isLoadingContacts
                            ? Center(child: CircularProgressIndicator())
                            : _contacts.isEmpty
                                ? Center(child: Text('No contacts to display'))
                                : Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: PaginatedDataTable(
                                          columnSpacing: 20,
                                          horizontalMargin: 12,
                                          rowsPerPage: _rowsPerPage,
                                          sortColumnIndex: _sortColumnIndex,
                                          sortAscending: _sortAscending,
                                          columns: [
                                            DataColumn(label: Text('No')),
                                            DataColumn(label: Text('Name')),
                                            DataColumn(label: Text('Email')),
                                            DataColumn(label: Text('Phone')),
                                            DataColumn(label: Text('Message')),
                                            DataColumn(
                                                label: Text('Created At')),
                                          ],
                                          source: ContactDataSource(
                                              _contacts, context),
                                        ),
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.0),

                  // Affiliate Request Table (Tetap Dipertahankan)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: _containerDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Affiliate Request',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              onPressed: _exportAffiliateData,
                              icon: Icon(Icons.file_download),
                              label: Text('Unduh Data'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Data Permintaan Untuk Join Affiliate Marketing Selarashome.id. Klik untuk melihat detail info',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.normal),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _searchAffiliateController,
                          focusNode: _searchAffiliateFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Cari...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (text) {
                            _searchByInfo(text);
                          },
                        ),
                        SizedBox(height: 10.0),
                        _isLoadingAffiliate
                            ? Center(child: CircularProgressIndicator())
                            : _affiliates.isEmpty
                                ? Center(
                                    child: Text('No affiliates to display'))
                                : Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: PaginatedDataTable(
                                          columnSpacing: 20,
                                          horizontalMargin: 12,
                                          rowsPerPage: _rowsPerPage,
                                          sortColumnIndex: _sortColumnIndex,
                                          sortAscending: _sortAscending,
                                          columns: [
                                            DataColumn(label: Text('No')),
                                            DataColumn(label: Text('Name')),
                                            DataColumn(label: Text('Email')),
                                            DataColumn(label: Text('Phone')),
                                            DataColumn(
                                                label: Text('Instagram')),
                                            DataColumn(label: Text('Tiktok')),
                                            DataColumn(label: Text('Info')),
                                            DataColumn(
                                                label: Text('Created At')),
                                          ],
                                          source: AffiliateDataSource(
                                              _affiliates, context),
                                        ),
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 2,
          offset: Offset(2, 4),
        ),
      ],
      borderRadius: BorderRadius.circular(8.0),
    );
  }

  Widget createCard({
    required String label1,
    required String label2,
    required String description,
    required String date,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Mengurangi tinggi keseluruhan
        children: [
          // Label Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label1,
                  style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: label2 != "" ? Colors.orange[50] : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label2,
                  style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8), // Mengurangi spacing
          // Title
          Text(
            description,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
          ),
          SizedBox(height: 6), // Mengurangi spacing
          // Date
          Text(
            date,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class ContactDataSource extends DataTableSource {
  final List<Map<String, dynamic>> contacts; // Ubah ke tipe spesifik
  final BuildContext context;

  ContactDataSource(this.contacts, this.context);

  @override
  DataRow getRow(int index) {
    final contact = contacts[index];
    return DataRow(cells: [
      DataCell(Text('${index + 1}')),
      DataCell(Text(contact['name']?.toString() ?? '-')),
      DataCell(Text(contact['email']?.toString() ?? '-')),
      DataCell(Text(contact['phone']?.toString() ?? '-')),
      DataCell(
        GestureDetector(
          onTap: () {
            if ((contact['message']?.toString() ?? '-').length > 30) {
              General.showDialogMessage(
                  context: context,
                  title: "Pesan Lengkap",
                  message: contact['message']?.toString() ?? '-');
            }
          },
          child: Container(
            width: 200,
            constraints: BoxConstraints(maxHeight: 50),
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Text(
                contact['message']?.toString() ?? '-',
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 150, // Tambahkan lebar agar tanggal tidak terpotong
          child: Text(
            contact['created_at'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(contact['created_at']))
                : '-',
            textAlign: TextAlign.left,
          ),
        ),
      ),
    ]);
  }

  @override
  int get rowCount => contacts.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class AffiliateDataSource extends DataTableSource {
  final List<Map<String, dynamic>> affiliates; // Ubah ke tipe spesifik
  final BuildContext context;

  AffiliateDataSource(this.affiliates, this.context);

  @override
  DataRow getRow(int index) {
    final affiliate = affiliates[index];
    final String? tiktok = affiliate['tiktok'];
    final Uri? tiktokUri = tiktok != null ? Uri.tryParse(tiktok) : null;
    final String? instagram = affiliate['instagram'];
    final Uri? instagramUri =
        instagram != null ? Uri.tryParse(instagram) : null;
    return DataRow(cells: [
      DataCell(Text('${index + 1}')),
      DataCell(Text(affiliate['name']?.toString() ?? '-')),
      DataCell(Text(affiliate['email']?.toString() ?? '-')),
      DataCell(Text(affiliate['phone']?.toString() ?? '-')),
      DataCell(
        Row(
          children: [
            // 1. Jika valid URL Tiktok
            if (instagramUri != null && instagramUri.isAbsolute)
              IconButton(
                icon: Icon(
                  FontAwesomeIcons.instagram,
                  color: Colors.black, // Sesuaikan warna
                  size: 20,
                ),
                onPressed: () async {
                  try {
                    await launchUrl(
                      instagramUri,
                      mode: LaunchMode
                          .externalApplication, // Buka di app eksternal
                    );
                  } catch (e) {
                    General.showSnackBar(
                        context, 'Gagal membuka Instagram: ${e.toString()}');
                  }
                },
              )

            // 2. Jika text biasa (username) atau URL tidak valid
            else if (instagram != null && instagram.isNotEmpty)
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: instagram));
                  General.showSnackBar(
                      context, 'Berhasil disalin ke clipboard!');
                },
                child: Tooltip(
                  // Tambahkan tooltip untuk UX lebih baik
                  message: 'Tap untuk menyalin',
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 14),
                        SizedBox(width: 6),
                        Text(
                          instagram,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // 3. Jika kosong/null
            else
              Text(
                'No Instagram Account',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
      DataCell(
        Row(
          children: [
            // 1. Jika valid URL Tiktok
            if (tiktokUri != null && tiktokUri.isAbsolute)
              IconButton(
                icon: Icon(
                  FontAwesomeIcons.tiktok,
                  color: Colors.black, // Sesuaikan warna
                  size: 20,
                ),
                onPressed: () async {
                  try {
                    await launchUrl(
                      tiktokUri,
                      mode: LaunchMode
                          .externalApplication, // Buka di app eksternal
                    );
                  } catch (e) {
                    General.showSnackBar(
                        context, 'Gagal membuka TikTok: ${e.toString()}');
                  }
                },
              )

            // 2. Jika text biasa (username) atau URL tidak valid
            else if (tiktok != null && tiktok.isNotEmpty)
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tiktok));
                  General.showSnackBar(
                      context, 'Berhasil disalin ke clipboard!');
                },
                child: Tooltip(
                  // Tambahkan tooltip untuk UX lebih baik
                  message: 'Tap untuk menyalin',
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 14),
                        SizedBox(width: 6),
                        Text(
                          tiktok,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // 3. Jika kosong/null
            else
              Text(
                'No Tiktok Account',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
      DataCell(
        GestureDetector(
          onTap: () {
            if ((affiliate['info']?.toString() ?? '-').length > 30) {
              General.showDialogMessage(
                  context: context,
                  title: "Info Lengkap",
                  message: affiliate['info']?.toString() ?? '-');
            }
          },
          child: Container(
            width: 200,
            constraints: BoxConstraints(maxHeight: 50),
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Text(
                affiliate['info']?.toString() ?? '-',
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 150, // Tambahkan lebar agar tanggal tidak terpotong
          child: Text(
            affiliate['created_at'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(affiliate['created_at']))
                : '-',
            textAlign: TextAlign.left,
          ),
        ),
      ),
    ]);
  }

  @override
  int get rowCount => affiliates.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
