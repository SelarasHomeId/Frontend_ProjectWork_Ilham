import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/home_screen.dart';
import 'package:selarashomeid/screens/login_screen.dart';
import 'package:selarashomeid/utils/connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    await Future.delayed(Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final roleId = prefs.getInt('roleId') ?? 0;

    if (token != '') {
      return {
        'isLoggedIn': true,
        'token': token,
        'roleId': roleId,
      };
    } else {
      return {
        'isLoggedIn': false,
        'token': token,
        'roleId': roleId,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SelarasHome App',
      theme: ThemeData(
          primarySwatch: Colors.blue, // Tema aplikasi
          expansionTileTheme: ExpansionTileThemeData(
              tilePadding: EdgeInsets.symmetric(horizontal: 8))),
      initialRoute: '/',
      routes: {
        '/': (context) => ConnectionChecker(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _checkLoginStatus,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SplashScreen();
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
            )
        )
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(seconds: 1),
          builder: (context, value, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (value < 1.0)
                      Transform.rotate(
                        angle: 3.14,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                      ),
                    Image.asset(
                      'assets/selaras_logo2.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                if (value >= 1.0) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/animation_say_hello.gif',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hello Developer Selaras!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
