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
          _showSuccessDialog();
          _navigateToDashboard(roleId, token);
        } else {
          // Handle khusus untuk akun terkunci
          if (response != null && response['data'] != null) {
            if (response['data']['error'] == 'unauthorized' &&
                response['data']['message'] == 'this account is locked') {
              _showAccountLockedDialog(); // Tampilkan dialog jika akun terkunci
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
                // Container untuk background merah dan ikon
                Container(
                  width:
                      double.infinity, // Agar container memenuhi lebar dialog
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red, // Background merah
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: Duration(seconds: 1),
                      scale: 1.2, // Memberikan efek animasi pada ikon
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 80, // Ukuran ikon yang besar
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Judul dan pesan
                Text(
                  'Login Error',
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
                    message,
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
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[900],
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
                            // Animasi zoom-out ketika ikon ditekan
                            _isIconClicked = !_isIconClicked;
                          });
                          Future.delayed(Duration(milliseconds: 200), () {
                            Navigator.of(context)
                                .pop(); // Tutup dialog setelah animasi
                          });
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isHovered = true; // Efek hover aktif
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isHovered = false; // Efek hover tidak aktif
                            });
                          },
                          child: AnimatedScale(
                            scale: _isIconClicked ? 0.7 : 1.0, // Efek zoom out
                            duration: Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.close,
                                color: _isHovered
                                    ? Colors.red
                                    : Colors.black, // Ubah warna saat hover
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
                    border: UnderlineInputBorder(), // Menghapus border kotak
                    isDense:
                        true, // Mengurangi tinggi padding di dalam textfield
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 10), // Mengurangi padding kiri kanan
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 0),
                      child: Icon(
                        Icons.mail_outline, // Ikon Mail di kiri
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null // Disable button saat sedang loading
                      : () async {
                          String email = _resetEmailController.text.trim();

                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Email tidak boleh kosong")));
                            return;
                          }

                          setState(() {
                            _isLoading = true; // Tampilkan indikator loading
                          });

                          try {
                            final response =
                                await ApiService.sendForgotPasswordEmail(email);

                            // Debugging log untuk memeriksa response
                            debugPrint('Response dari API: $response');

                            if (response != null &&
                                response['success'] == true) {
                              // Jika sukses
                              setState(() {
                                _isLoading = false; // Selesai loading
                              });
                              _showResetSuccessDialog();
                            } else {
                              setState(() {
                                _isLoading = false; // Selesai loading
                              });
                              // Menampilkan error jika gagal
                              _showErrorResetDialog(response?['message'] ??
                                  'Gagal mengirim email reset password');
                            }
                          } catch (e) {
                            // Menangkap error saat pemanggilan API
                            debugPrint('Error saat mengirim email reset: $e');
                            setState(() {
                              _isLoading = false; // Selesai loading
                            });
                            _showErrorResetDialog('Terjadi kesalahan: $e');
                          }
                        },
                  child: Text('Submit'),
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

// Menampilkan dialog loading saat menunggu API response
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Agar pengguna tidak bisa menutup dialog ini
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
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

// Menampilkan dialog error jika gagal mengirim reset password
  void _showErrorResetDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  Icons.error,
                  color: Colors.red,
                  size: 80,
                ),
                SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.0),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: Text('OK'),
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
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _showPasswordResetDialog,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color:
                                          const Color.fromARGB(255, 7, 54, 92),
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
    );
  }
}
