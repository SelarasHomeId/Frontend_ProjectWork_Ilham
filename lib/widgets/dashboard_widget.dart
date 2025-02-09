import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart'; // Import the PieChart package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selarashomeid/service/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'Pengguna';
    });
  }

  Future<void> _fetchData() async {
    final data = await ApiService.fetchDashboard(widget.token);
    setState(() {
      _chartData = data?['data'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
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
            SizedBox(height: 10.0),

            // Social Media Engagement Box
            if (_chartData != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white, // Warna putih
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.2), // Warna shadow dengan transparansi
                      blurRadius: 8, // Efek blur untuk shadow
                      spreadRadius: 2, // Lebar shadow
                      offset: Offset(2, 4), // Posisi shadow (x, y)
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Social Media Engagement',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 20),
                    PieChart(
                      dataMap: {
                        'Instagram': _chartData!['count_instagram'].toDouble(),
                        'Tiktok': _chartData!['count_tiktok'].toDouble(),
                        'Facebook': _chartData!['count_facebook'].toDouble(),
                        'Whatsapp': _chartData!['count_whatsapp'].toDouble(),
                      },
                      animationDuration: Duration(milliseconds: 800),
                      chartLegendSpacing: 32,
                      chartRadius: MediaQuery.of(context).size.width / 3.2,
                      colorList: [
                        Colors.blue,
                        Colors.purple,
                        Colors.orange,
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
                        legendTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      chartValuesOptions: ChartValuesOptions(
                        showChartValueBackground: false,
                        showChartValues: true,
                        showChartValuesInPercentage: false,
                        showChartValuesOutside: false,
                        decimalPlaces: 0, // Menghilangkan titik desimal
                        chartValueStyle: TextStyle(
                          fontSize: 18, // Memperbesar font angka
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Affiliate and Contact Box
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white, // Warna putih
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.2), // Warna shadow dengan transparansi
                      blurRadius: 8, // Efek blur untuk shadow
                      spreadRadius: 2, // Lebar shadow
                      offset: Offset(2, 4), // Posisi shadow (x, y)
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Affiliate and Contact',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 10),
                    PieChart(
                      dataMap: {
                        'Affiliate': _chartData!['count_affiliate'].toDouble(),
                        'Contact': _chartData!['count_contact'].toDouble(),
                      },
                      animationDuration: Duration(milliseconds: 800),
                      chartLegendSpacing: 32,
                      chartRadius: MediaQuery.of(context).size.width / 3.2,
                      colorList: [Colors.red, Colors.yellow],
                      initialAngleInDegree: 0,
                      chartType: ChartType.disc,
                      ringStrokeWidth: 40,
                      // centerText: "Affiliate & Contact",
                      legendOptions: LegendOptions(
                        showLegendsInRow: false,
                        legendPosition: LegendPosition.right,
                        showLegends: true,
                        legendShape: BoxShape.circle,
                        legendTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      chartValuesOptions: ChartValuesOptions(
                        showChartValueBackground: false,
                        showChartValues: true,
                        showChartValuesInPercentage: false,
                        showChartValuesOutside: false,
                        decimalPlaces: 0, // Menghilangkan titik desimal
                        chartValueStyle: TextStyle(
                          fontSize: 18, // Memperbesar font angka
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
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
