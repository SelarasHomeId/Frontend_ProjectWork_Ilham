import 'package:flutter/material.dart';
import 'package:selarashomeid/widgets/division_widget.dart';
import 'package:selarashomeid/widgets/project_widget.dart';
import 'package:selarashomeid/widgets/role_widget.dart';
import 'package:selarashomeid/widgets/sidebar_widget.dart';
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
  Widget _currentWidget = DashboardWidget(roleId: 0, token: '');

  @override
  void initState() {
    super.initState();

    _currentWidget =
        DashboardWidget(roleId: widget.roleId, token: widget.token);
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
          // Kirim daftar menu

          roleId: widget.roleId, // Role pengguna
          onMenuItemSelected: _onMenuItemSelected, // Callback untuk menu
        ),
      ),
      body: SafeArea(
        child: _currentWidget, // Tampilkan widget sesuai menu
      ),
    );
  }
}
