import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';

class Sidebar extends StatefulWidget {
  final int roleId;
  final Function(String, int) onMenuItemSelected; // Callback untuk memilih menu

  Sidebar({
    required this.roleId,
    required this.onMenuItemSelected, // Terima callback
  });

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Map<String, dynamic>> _menuItems = [];
  final ValueNotifier<bool> _isWorkspaceExpanded = ValueNotifier(false);
  final ValueNotifier<bool> _isMasterDataExpanded = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchMenuItems();
  }

  @override
  void dispose() {
    _isWorkspaceExpanded.dispose();
    _isMasterDataExpanded.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuItems() async {
    try {
      final response =
          await ApiService.workspaceFind(); // Panggil API workspace
      setState(() {
        _menuItems = response;
      });
    } catch (e) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat menu: $e')),
      );
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Konfirmasi Logout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Apakah Anda yakin ingin logout?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.0, color: Colors.black54),
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(context)
                                .pop(); // Tutup dialog menggunakan context dialog

                            // Gunakan parent context yang valid
                            final parentContext = context
                                .findRootAncestorStateOfType<NavigatorState>()!
                                .context;

                            ApiService.authLogout(
                                parentContext); // Pass parent context
                          },
                          child: Text('Ya'),
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          child: Text(
                            'Tidak',
                            style: TextStyle(color: Colors.red[900]),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Tutup dialog
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        width: screenWidth * 0.75,
        color: Colors.grey[200],
        child: Column(
          children: [
            // Header User dengan FutureBuilder
            FutureBuilder<Map<String, dynamic>>(
              future: General.getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading profile'));
                } else if (snapshot.hasData) {
                  final user = snapshot.data!;
                  final roleName = user['roleName'];
                  final divisiName = user['divisiName'];
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/profil_bg.png'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5),
                            BlendMode.darken), // Darken effect
                      ),
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.09,
                              backgroundColor: Colors.white,
                              child: Text(
                                user['initials']!,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.08,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 21, 55, 83),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              user['name']!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              roleName + ' - ' + divisiName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: screenWidth * 0.07,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showLogoutDialog(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox();
              },
            ),
            // Menu Sidebar
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  children: [
                    ListTile(
                      leading: Icon(Icons.dashboard),
                      title: Text('Dashboard'),
                      onTap: () {
                        widget.onMenuItemSelected('Dashboard', 0);
                        Navigator.pop(context);
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      // Workspaces
                      valueListenable: _isWorkspaceExpanded,
                      builder: (context, isExpanded, child) {
                        return ExpansionTile(
                          leading: Icon(Icons.workspaces),
                          title: Text('Workspace'),
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (isExpanded) {
                            _isWorkspaceExpanded.value = isExpanded;
                          },
                          children: _menuItems.map((item) {
                            return ListTile(
                              leading: Icon(Icons.subdirectory_arrow_right),
                              title: Text(item['name']),
                              onTap: () {
                                widget.onMenuItemSelected(
                                    item['name'], item['id']);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (widget.roleId == 1)
                      ValueListenableBuilder<bool>(
                        valueListenable: _isMasterDataExpanded,
                        builder: (context, isExpanded, child) {
                          return ExpansionTile(
                            leading: Icon(Icons.settings),
                            title: Text('Master Data'),
                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (isExpanded) {
                              _isMasterDataExpanded.value = isExpanded;
                            },
                            children: [
                              ListTile(
                                leading: Icon(Icons.work),
                                title: Text('Project'),
                                onTap: () {
                                  widget.onMenuItemSelected('Project', 0);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.group),
                                title: Text('User'),
                                onTap: () {
                                  widget.onMenuItemSelected('User', 0);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.account_tree),
                                title: Text('Role'),
                                onTap: () {
                                  widget.onMenuItemSelected('Role', 0);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.business),
                                title: Text('Division'),
                                onTap: () {
                                  widget.onMenuItemSelected('Division', 0);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
