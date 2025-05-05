import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/home_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:awesome_dialog/awesome_dialog.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _resetEmailController = TextEditingController();
  FocusNode _loginEmailFocusNode = FocusNode();
  FocusNode _loginPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isDialogLoading = false;
  bool _isIconClicked = false;
  bool _isHovered = false;

  void _login() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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
          final createdAt = response['data']['data']['created_at'];
          final id = response['data']['data']['id'];
          final roleId = response['data']['data']['role']['id'];
          final divisiId = response['data']['data']['divisi']['id'];
          final roleName = response['data']['data']['role']['name'];
          final divisiName = response['data']['data']['divisi']['name'];

          await General.saveToSharedPreferences({
            'token': token,
            'email': email,
            'name': name,
            'createdAt': createdAt,
            'id': id,
            'roleId': roleId,
            'divisiId': divisiId,
            'roleName': roleName,
            'divisiName': divisiName,
          });
          _showSuccessDialog();
          _navigateToDashboard(roleId, token);
        } else {
          // Handle khusus untuk akun terkunci
          if (response != null && response['data'] != null) {
            if (response['data']['error'] == 'unauthorized' &&
                response['data']['message'] == 'this account is locked') {
              _showAccountLockedDialog();
            } else {
              _showErrorDialog(
                  response['message'] ?? 'Username atau password salah');
            }
          } else {
            _showErrorDialog(response?['message'] ??
                'Terjadi kesalahan yang tidak diketahui');
          }
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

  void _showAccountLockedDialog() {
    setState(() {
      _isDialogLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isDialogLoading = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange, // Warna orange untuk peringatan
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: Duration(seconds: 1),
                      scale: 1.2,
                      child: Text(
                        '😞', // Emoji sedih
                        style: TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Akun Terkunci',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Akun anda terkunci, anda tidak bisa melakukan Login. Silahkan hubungi admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    });
  }

  void _showErrorDialog(String message) {
    setState(() {
      _isDialogLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isDialogLoading = false;
      });

      // Menampilkan dialog
      General.showDialogError(
          context: context,
          title: "Login Error",
          message: "Email atau Password Salah, Silahkan Input Kembali ",
          confirmButtonText: "Oke");
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

      // Menampilkan dialog sukses
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container untuk background hijau dan ikon check
                Container(
                  width:
                      double.infinity, // Agar container memenuhi lebar dialog
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green, // Background hijau untuk sukses
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: Duration(seconds: 1),
                      scale: 1.2, // Memberikan animasi pada ikon
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 80, // Ukuran ikon yang besar
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Login Sukses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "You have successfully logged in!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Tombol OK
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Menutup dialog
                    // Setelah dialog sukses, navigasi ke Home Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          roleId: 1,
                          token: '', // Gantilah dengan token yang sesuai
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green[900],
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    });
  }

  // Reset password pop-up
  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -15,
                      right: -15,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isIconClicked = !_isIconClicked;
                          });
                          Future.delayed(Duration(milliseconds: 200), () {
                            Navigator.of(context).pop();
                            _resetEmailController
                                .clear(); // Clear the email input when dialog is closed
                          });
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isHovered = true;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isHovered = false;
                            });
                          },
                          child: AnimatedScale(
                            scale: _isIconClicked ? 0.7 : 1.0,
                            duration: Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.close,
                                color: _isHovered ? Colors.red : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 40,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Masukkan email Anda untuk menerima tautan reset password:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _resetEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: UnderlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 0),
                      child: Icon(
                        Icons.mail_outline,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          String email = _resetEmailController.text.trim();

                          if (email.isEmpty) {
                            General.showSnackBar(
                                context, "Email tidak boleh kosong");
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            final response =
                                await ApiService.sendForgotPasswordEmail(email);

                            debugPrint('Response dari API: $response');

                            setState(() {
                              _isLoading = false;
                            });

                            if (response != null &&
                                response['success'] == true) {
                              _showResetSuccessDialog();
                            } else {
                              General.showDialogError(
                                  context: context,
                                  title: "error",
                                  message: 'Email Tidak Terdaftar!',
                                  confirmButtonText: "oke");
                            }
                          } catch (e) {
                            debugPrint('Error saat mengirim email reset: $e');
                            setState(() {
                              _isLoading = false;
                            });
                            General.showDialogError(
                                context: context,
                                title: "Error",
                                message: 'Terjadi kesalahan: $e',
                                confirmButtonText: "Oke");
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

// Menampilkan dialog sukses reset password
  void _showResetSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
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
  void dispose() {
    // Menambahkan dispose untuk controller baru
    _usernameController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Ini akan mendeteksi sentuhan di luar text field
        behavior: HitTestBehavior
            .opaque, // Agar sentuhan di luar widget lainnya tetap terdeteksi
        onTap: () {
          // Unfocus jika ada text field yang aktif
          _loginEmailFocusNode.unfocus();
          _loginPasswordFocusNode.unfocus();
        },
        child: Stack(
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
                                    focusNode: _loginEmailFocusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.account_circle),
                                      border: UnderlineInputBorder(),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.red),
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
                                    focusNode: _loginPasswordFocusNode,
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
                                        borderSide:
                                            BorderSide(color: Colors.red),
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
                                      child: Text('Login'),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _showPasswordResetDialog,
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 7, 54, 92),
                                        fontSize: 16,
                                      ),
                                    ),
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
      ),
    );
  }
}
