import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';

class RoleWidget extends StatefulWidget {
  @override
  _RoleWidgetState createState() => _RoleWidgetState();
}

class _RoleWidgetState extends State<RoleWidget> {
  List<dynamic> roles = [];
  bool _isLoading = true;

  // Memanggil API untuk mendapatkan data role
  Future<void> fetchRoles() async {
    try {
      final result = await ApiService.getRoles();
      if (result != null) {
        setState(() {
          roles = result['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching roles: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : roles.isEmpty
              ? Center(child: Text('Tidak ada roles untuk ditampilkan'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header - judul
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  'Role Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              // Tampilkan data role sebagai paragraf
                              ...roles.map(
                                (role) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${role['name']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Description: ${role['description']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                      ],
                                    ),
                                  );
                                },
                              ).toList(),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}
