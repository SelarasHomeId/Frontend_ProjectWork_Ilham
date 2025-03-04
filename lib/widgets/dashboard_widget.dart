import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:intl/intl.dart';

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

  bool _isLoadingData = false;
  bool _isLoadingContacts = false;
  bool _isLoadingAffiliate = false;
  int _rowsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _contactCount = 0;
  int _affiliateCount = 0;
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
  }

  @override
  void dispose() {
    _searchMessageController.dispose();
    _searchMessageFocusNode.dispose();
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
      _isLoadingData = false;
      _isLoadingContacts = false;
      _isLoadingAffiliate = false;
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingData = true);
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
        params: {'page': '1', 'limit': '10'},
      );

      print("Contacts API Response: $result");

      if (result != null && result['data'] != null) {
        final responseData = result['data'];
        final List<dynamic> contactsData =
            responseData is List ? responseData : responseData['data'] ?? [];

        setState(() {
          _contacts = contactsData
              .map((data) => Map<String, dynamic>.from(data))
              .toList();
          _basecontacts = List.from(_contacts);
          _contactCount = result['count'] ?? _contacts.length;
        });

        print("Parsed Contacts: $_contacts");
      }
    } catch (e, stackTrace) {
      print("Error fetching contacts: $e, $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kontak: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _fetchAffiliates() async {
    setState(() => _isLoadingAffiliate = true);

    try {
      final result = await ApiService.handleAffiliates(
        token: widget.token,
        params: {'page': '1', 'limit': '10'},
      );

      print("Affiliate API Response: $result");

      if (result != null && result['data'] != null) {
        final responseData = result['data'];
        final List<dynamic> affiliateData =
            responseData is List ? responseData : responseData['data'] ?? [];

        setState(() {
          _affiliates = affiliateData
              .map((data) => Map<String, dynamic>.from(data))
              .toList();
          _baseaffiliates = List.from(_affiliates);
          _affiliateCount = result['count'] ?? _affiliates.length;
        });

        print("Parsed Affiliate: $_affiliates");
      }
    } catch (e, stackTrace) {
      print("Error fetching affiliate: $e, $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat affiliate: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingAffiliate = false);
    }
  }

  void _searchByMessage(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _contacts = List.from(_basecontacts);
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
                              Color(0xFFFD1D1D),
                              Color(0xFF00F2EA),
                              Color(0xff1877F2),
                              Colors.green
                            ],
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
                            colorList: [Color(0xFFC1DBE3), Color(0xFF474441)],
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
                        Text(
                          'Messaging',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
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
                        _isLoadingContacts || _contacts.isEmpty
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
                        Text(
                          'Affiliate Request',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
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
                        _isLoadingAffiliate || _affiliates.isEmpty
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

  // Widget to create legend for each chart section
  Widget _buildLegend(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Container untuk header dengan background abu-abu dan ikon amplop
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[700], // Warna abu-abu
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: AnimatedScale(
                              duration: Duration(milliseconds: 500),
                              scale: 1.2,
                              child: Icon(
                                Icons.email, // Ganti dengan ikon amplop
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Judul dialog
                        Text(
                          'Pesan Lengkap',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),

                        // Isi pesan dengan scroll jika panjang
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Text(
                              contact['message']?.toString() ?? '-',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Tombol Tutup
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.grey[800], // Warna abu-abu tua
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tutup',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            }
          },
          child: Container(
            width: 200, // Atur lebar kolom
            child: Text(
              contact['message']?.toString() ?? '-',
              softWrap: true,
              maxLines: 1, // Batasi satu baris
              overflow: TextOverflow
                  .ellipsis, // Tampilkan titik tiga jika terlalu panjang
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
    return DataRow(cells: [
      DataCell(Text('${index + 1}')),
      DataCell(Text(affiliate['name']?.toString() ?? '-')),
      DataCell(Text(affiliate['email']?.toString() ?? '-')),
      DataCell(Text(affiliate['phone']?.toString() ?? '-')),
      DataCell(Text(affiliate['instagram']?.toString() ?? '-')),
      DataCell(Text(affiliate['tiktok']?.toString() ?? '-')),
      DataCell(
        GestureDetector(
          onTap: () {
            if ((affiliate['info']?.toString() ?? '-').length > 30) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Container untuk header dengan background abu-abu dan ikon amplop
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[700], // Warna abu-abu
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: AnimatedScale(
                              duration: Duration(milliseconds: 500),
                              scale: 1.2,
                              child: Icon(
                                Icons.email, // Ganti dengan ikon amplop
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Judul dialog
                        Text(
                          'Pesan Lengkap',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),

                        // Isi pesan dengan scroll jika panjang
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Text(
                              affiliate['info']?.toString() ?? '-',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Tombol Tutup
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.grey[800], // Warna abu-abu tua
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tutup',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            }
          },
          child: Container(
            width: 200, // Atur lebar kolom
            child: Text(
              affiliate['info']?.toString() ?? '-',
              softWrap: true,
              maxLines: 1, // Batasi satu baris
              overflow: TextOverflow
                  .ellipsis, // Tampilkan titik tiga jika terlalu panjang
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
