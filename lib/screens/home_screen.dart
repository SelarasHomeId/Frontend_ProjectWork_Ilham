import 'package:flutter/material.dart';
import 'package:selarashomeid/widgets/sidebar_widget.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/appbar_widget.dart';
import 'package:selarashomeid/widgets/dashboard_widget.dart';
import 'package:selarashomeid/widgets/workspace_widget.dart';

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
  Widget _currentWidget =
      DashboardWidget(roleId: 0, token: ''); // Default widget

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
      final response = await ApiService.workspaceFind();
      setState(() {
        _menuItems = response;
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

  // Menambahkan logika untuk mengganti widget yang ditampilkan
  void _onMenuItemSelected(String menuName) {
    setState(() {
      if (menuName == 'Dashboard') {
        _currentWidget =
            DashboardWidget(roleId: widget.roleId, token: widget.token);
      } else {
        _currentWidget = WorkspaceWidget(
            workspace: menuName, token: widget.token); // Default widget
      }
    });
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
          onMenuItemSelected: _onMenuItemSelected, // Pass callback
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    _currentWidget, // Menampilkan widget yang sesuai dengan pilihan
              ),
      ),
    );
  }
}
