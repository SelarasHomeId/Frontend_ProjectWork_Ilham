import 'package:flutter/material.dart';
import 'package:selarashomeid/widgets/sidebar_widget.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/appbar_widget.dart';
import 'package:selarashomeid/widgets/dashboard_widget.dart';

class HomeScreen extends StatefulWidget {
  final int roleId;
  final String token;

  HomeScreen({required this.roleId, required this.token});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.apiRequest(
        method: 'GET',
        endpoint: '/workspace',
        body: null,
        token: widget.token,
        contentType: 'application/json',
      );
      setState(() {
        _menuItems = List<Map<String, dynamic>>.from(response?['data']['data']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat menu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: Sidebar(
          menuItems: _menuItems,
          isLoading: _isLoading,
          roleId: widget.roleId,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: DashboardWidget(
                    roleId: widget.roleId,
                    token: widget.token), // Menggunakan DashboardWidget
              ),
      ),
    );
  }
}
