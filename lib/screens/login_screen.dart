import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/home_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isDialogLoading = false;

  void _login() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Arahkan ke Dashboard jika token tersedia, atau ke Login jika tidak
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(roleId: 1, token: token),
        ),
      );
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _usernameController.text.trim();
      String password = _passwordController.text;

      try {
        final response = await ApiService.authLogin(email, password);

        setState(() {
          _isLoading = false;
        });

        if (response != null && response['success'] == true) {
          final token = response['data']['token'];
          final email = response['data']['data']['email'];
          final name = response['data']['data']['name'];
          final id = response['data']['data']['id'];
          final roleId = response['data']['data']['role']['id'];
          final divisiId = response['data']['data']['divisi']['id'];
          final roleName = response['data']['data']['role']['name'];
          final divisiName = response['data']['data']['divisi']['name'];

          await General.saveToSharedPreferences({
            'token': token,
            'email': email,
            'name': name,
            'id': id,
            'roleId': roleId,
            'divisiId': divisiId,
            'roleName': roleName,
            'divisiName': divisiName,
          });
          _navigateToDashboard(roleId, token);
        } else {
          _showErrorDialog(
              response?['message'] ?? 'Username atau password salah');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Terjadi kesalahan: $e');
      }
    }
  }

  void _navigateToDashboard(int roleId, String token) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(roleId: roleId, token: token),
      ),
    );
  }

  void _showErrorDialog(String message) {
    setState(() {
      _isDialogLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isDialogLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Login Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  void _showSuccessDialog() {
    setState(() {
      _isDialogLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isDialogLoading = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(
                  roleId: 1,
                  token: '',
                )),
      );
    });
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded, // Menambahkan ikon tanda seru
                color: Colors.red,
                size: 30, // Ukuran ikon
              ),
              SizedBox(width: 10), // Jarak antara ikon dan teks
              Text('Reset Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your email to receive a password reset link:'),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showResetSuccessDialog();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showResetSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(vertical: 20.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                "Permintaan Reset Password Telah dikirim ke Email kamu, Pastikan Email yang Anda Input Sudah Benar",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.0),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with reduced opacity and blend mode
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/background.jpg'), // Background image path
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/selaras_logo2.png', // Logo path
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: 400.0,
                        maxHeight: 450.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 24.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                          SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.account_circle),
                                    border: UnderlineInputBorder(),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan Email';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 30),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: UnderlineInputBorder(),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan password';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 213, 37, 29),
                                        foregroundColor: Colors.white),
                                    child: _isLoading
                                        ? CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255)),
                                          )
                                        : Text('Login'),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showPasswordResetDialog,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text('Forgot Password?'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isDialogLoading)
            AnimatedOpacity(
              opacity: _isLoading || _isDialogLoading ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
