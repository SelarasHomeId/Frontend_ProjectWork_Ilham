import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardWidget extends StatefulWidget {
  final int roleId;
  final String token;

  DashboardWidget({required this.roleId, required this.token});

  @override
  _DashboardWidgetState createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'Pengguna';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selamat Datang
        // Teks 'Selamat Datang' dengan font tebal
        Text(
          'Selamat Datang,',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold, // Teks tebal
            color: Colors.black,
          ),
        ),
        // Teks username dalam format biasa
        Text(
          _userName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.normal, // Teks biasa
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5.0), // Mengurangi jarak

        // Diagram Lingkaran
        Center(
          child: Column(
            children: [
              Text(
                'Work Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5.0), // Mengurangi jarak
              SizedBox(
                height: 250, // Menentukan tinggi diagram lingkaran
                width: 250, // Menentukan lebar diagram lingkaran
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.red,
                        value: 30,
                        title: '30%',
                        titleStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.yellow,
                        value: 50,
                        title: '50%',
                        titleStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.green,
                        value: 20,
                        title: '20%',
                        titleStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
