import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';

class Sidebar extends StatefulWidget {
  final List<Map<String, dynamic>> menuItems;
  final bool isLoading;
  final int roleId;
  final Function(String) onMenuItemSelected; // Callback untuk memilih menu

  Sidebar({
    required this.menuItems,
    required this.isLoading,
    required this.roleId,
    required this.onMenuItemSelected, // Terima callback
  });

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final ValueNotifier<bool> _isWorkspaceExpanded = ValueNotifier(false);
  final ValueNotifier<bool> _isMasterDataExpanded = ValueNotifier(false);

  @override
  void dispose() {
    _isWorkspaceExpanded.dispose();
    _isMasterDataExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        width: screenWidth * 0.75,
        color: Colors.grey[200],
        child: widget.isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header User dengan FutureBuilder
                  FutureBuilder<Map<String, String>>(
                    future: General.getUserProfile(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading profile'));
                      } else if (snapshot.hasData) {
                        final user = snapshot.data!;
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
                                        color: const Color.fromARGB(
                                            255, 21, 55, 83),
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
                                    user['email']!,
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
                                    ApiService.authLogout(context);
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
                              widget.onMenuItemSelected('Dashboard');
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
                                children: widget.menuItems.map((item) {
                                  return ListTile(
                                    leading:
                                        Icon(Icons.subdirectory_arrow_right),
                                    title: Text(item['name']),
                                    onTap: () {
                                      widget.onMenuItemSelected(item['name']);
                                      Navigator.pop(context);
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            // Master Data
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
                                    leading: Icon(Icons.person),
                                    title: Text('User'),
                                    onTap: () {
                                      widget.onMenuItemSelected('User');
                                    },
                                  ),
                                  if (widget.roleId == 1)
                                    ListTile(
                                      leading: Icon(Icons.business),
                                      title: Text('Divisi'),
                                      onTap: () {
                                        widget.onMenuItemSelected('Divisi');
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
