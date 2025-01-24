import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/home_screen.dart';
import 'package:selarashomeid/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Map<String, dynamic>> _checkLoginStatus;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus = _checkUserLoginStatus();
  }

  Future<Map<String, dynamic>> _checkUserLoginStatus() async {
    await Future.delayed(Duration(seconds: 3)); // Delay 3 detik
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final roleId = prefs.getInt('roleId') ?? 0;

    return {
      'isLoggedIn': token != null && token.isNotEmpty,
      'token': token ?? '',
      'roleId': roleId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SelarasHome App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tema aplikasi
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<Map<String, dynamic>>(
              future: _checkLoginStatus,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData) {
                  var data = snapshot.data!;
                  bool isLoggedIn = data['isLoggedIn'];
                  String token = data['token'];
                  int roleId = data['roleId'];

                  if (isLoggedIn) {
                    return HomeScreen(roleId: roleId, token: token);
                  } else {
                    return LoginScreen();
                  }
                } else {
                  return LoginScreen();
                }
              },
            ),
      },
    );
  }
}
