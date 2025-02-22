import 'package:flutter/material.dart';
import 'package:selarashomeid/widgets/add_user_widget.dart';
import 'package:selarashomeid/widgets/division_widget.dart';
import 'package:selarashomeid/widgets/project_widget.dart';
import 'package:selarashomeid/widgets/role_widget.dart';
import 'package:selarashomeid/widgets/sidebar_widget.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/appbar_widget.dart';
import 'package:selarashomeid/widgets/dashboard_widget.dart';
import 'package:selarashomeid/widgets/user_widget.dart';
import 'package:selarashomeid/widgets/workspace_widget.dart';

class HomeScreen extends StatefulWidget {
  final int roleId;
  final String token;

  HomeScreen({required this.roleId, required this.token});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _menuItems = []; // Menyimpan daftar workspace
  bool _isLoading = true; // Status loading
  Widget _currentWidget =
      DashboardWidget(roleId: 0, token: ''); // Widget default

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
    _currentWidget =
        DashboardWidget(roleId: widget.roleId, token: widget.token);
  }

  /// Fetch data workspace dari API
  Future<void> _fetchMenuItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await ApiService.workspaceFind(); // Panggil API workspace
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

  /// Fungsi untuk mengganti widget berdasarkan menu yang dipilih
  void _onMenuItemSelected(String menuName, int menuId) {
    setState(() {
      if (menuName == 'Dashboard') {
        _currentWidget =
            DashboardWidget(roleId: widget.roleId, token: widget.token);
      } else if (menuName == 'User') {
        _currentWidget = UserWidget();
      } else if (menuName == 'Role') {
        _currentWidget = RoleWidget();
      } else if (menuName == 'Project') {
        _currentWidget = ProjectWidget();
      } else if (menuName == 'Division') {
        _currentWidget = DivisionWidget();
      } else if (menuName == 'Add User') {
        _currentWidget = AddUserWidget();
      } else {
        _currentWidget =
            WorkspaceWidget(workspace: menuName, workspaceId: menuId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(), // AppBar custom
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      drawer: Drawer(
        child: Sidebar(
          menuItems: _menuItems, // Kirim daftar menu
          isLoading: _isLoading, // Status loading
          roleId: widget.roleId, // Role pengguna
          onMenuItemSelected: _onMenuItemSelected, // Callback untuk menu
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // Loading indicator
            : _currentWidget, // Tampilkan widget sesuai menu
      ),
    );
  }
}
