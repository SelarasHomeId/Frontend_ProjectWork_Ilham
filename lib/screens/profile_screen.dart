import 'package:flutter/material.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/change_password_widget.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, String>> userProfile;
  Map<String, String> userMap = {};

  @override
  void initState() {
    super.initState();
    userProfile = General.getUserProfile();
    userProfile.then((data) {
      setState(() {
        userMap = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil lebar layar untuk responsivitas
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Latar belakang abu-abu
      appBar: AppBar(
        title: Text("User Profile"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.0),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No user data available.'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Picture with Border
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: screenWidth * 0.15,
                              backgroundColor: General.getColorFromInitial(
                                  user['initials']!),
                              child: Text(
                                user['initials']!,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A365D),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            user['name']!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            user['email']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Menu Items Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                            "Role", Icons.account_tree, user['roleName']!),
                        _buildMenuItem(
                            "Divisi", Icons.business, user['divisiName']!),
                        _buildMenuItem(
                            "Register Date",
                            Icons.calendar_month_outlined,
                            user['createdAt']!
                                .replaceAll('T', ' ')
                                .replaceAll('Z', '')),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Change Password Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return ChangePasswordDialog();
                          },
                        );
                      },
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, String data) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        data,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w300,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
