import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';

class ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  FocusNode oldPasswordFocusNode = FocusNode();
  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
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

  // API Call to change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final data = {
      "old_password": oldPassword,
      "new_password": newPassword,
    };

    try {
      final response = await ApiService.handleUser(
        method: 'PATCH',
        userId: int.parse(userMap['id'].toString()),
        data: data,
      );
      print("Response dari API password: $response");

      if (response != null && response['success'] == true) {
        General.showSnackBar(context, 'Password berhasil diubah!');
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      } else {
        print("Response tidak valid atau gagal: $response");
        General.showSnackBar(context, 'Gagal mengupdate password');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Future.delayed(Duration(seconds: 3), () {
            Navigator.of(context).pop(); // Close the dialog after 3 seconds
          });

          return AlertDialog(
            title: Text('Error'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // Close the dialog immediately if user presses the button
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        oldPasswordFocusNode.unfocus();
        newPasswordFocusNode.unfocus();
        confirmPasswordFocusNode.unfocus();
      },
      child: AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(16, 28, 16, 16),
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        content: Stack(
          clipBehavior: Clip.none,
          children: [
            // Perubahan Utama: Container untuk Close Button
            Positioned(
              right: -10,
              top: -20,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Judul
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                  child: Text(
                    'Change Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _isOldPasswordObscured,
                        focusNode: oldPasswordFocusNode,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(),
                          labelText: 'Old Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isOldPasswordObscured
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isOldPasswordObscured =
                                    !_isOldPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Old password is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        focusNode: newPasswordFocusNode,
                        obscureText: _isNewPasswordObscured,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPasswordObscured
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordObscured =
                                    !_isNewPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'New password is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: confirmPasswordFocusNode,
                        obscureText: _isConfirmPasswordObscured,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(),
                          labelText: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordObscured
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordObscured =
                                    !_isConfirmPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            String oldPassword = _oldPasswordController.text;
                            String newPassword = _newPasswordController.text;
                            changePassword(oldPassword, newPassword);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[500],
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
