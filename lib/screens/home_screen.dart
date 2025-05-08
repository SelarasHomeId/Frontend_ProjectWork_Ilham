import 'package:flutter/material.dart';
import 'package:selarashomeid/utils/connection_checker.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/division_widget.dart';
import 'package:selarashomeid/widgets/project_widget.dart';
import 'package:selarashomeid/widgets/role_widget.dart';
import 'package:selarashomeid/widgets/sidebar_widget.dart';
import 'package:selarashomeid/widgets/appbar_widget.dart';
import 'package:selarashomeid/widgets/dashboard_widget.dart';
import 'package:selarashomeid/widgets/user_widget.dart';
import 'package:selarashomeid/widgets/workspace_widget.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  final int roleId;
  final String token;
  final String? toWorkspaceName;
  final int? toWorkspaceId;

  HomeScreen(
      {required this.roleId,
      required this.token,
      this.toWorkspaceId,
      this.toWorkspaceName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Widget _currentWidget;
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();

    _currentWidget =
        DashboardWidget(roleId: widget.roleId, token: widget.token);

    if (widget.toWorkspaceName != null && widget.toWorkspaceId != null) {
      _currentWidget = WorkspaceWidget(
          workspace: widget.toWorkspaceName!,
          workspaceId: widget.toWorkspaceId!);
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
      } else {
        _currentWidget =
            WorkspaceWidget(workspace: menuName, workspaceId: menuId);
      }
    });
  }

  /// Fungsi untuk menangani tombol back
  void _onPopInvoked(bool didPop, dynamic result) {
    if (didPop) return; // Jika pop sudah diproses oleh sistem, biarkan saja

    if (_currentWidget is! DashboardWidget) {
      // Jika bukan di Dashboard, kembali ke Dashboard
      setState(() {
        _currentWidget =
            DashboardWidget(roleId: widget.roleId, token: widget.token);
      });
    } else {
      // Jika sudah di Dashboard, tekan dua kali dalam 800ms untuk keluar
      DateTime now = DateTime.now();
      if (_lastPressed == null ||
          now.difference(_lastPressed!) > Duration(milliseconds: 800)) {
        _lastPressed = now;
        General.showSnackBar(
          context,
          "Tekan kembali untuk keluar",
        );
      } else {
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionChecker(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _onPopInvoked,
        child: Scaffold(
          appBar: AppBarWidget(),
          backgroundColor: const Color.fromARGB(255, 248, 248, 248),
          drawer: Drawer(
            child: Sidebar(
              roleId: widget.roleId,
              onMenuItemSelected: _onMenuItemSelected,
            ),
          ),
          body: SafeArea(
            child: _currentWidget,
          ),
        ),
      )
    );
  }
}
