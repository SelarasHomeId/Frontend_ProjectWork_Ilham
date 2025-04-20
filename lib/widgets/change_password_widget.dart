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

  // Function to show snackbar message
  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
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
    // double screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Old Password Field
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _isOldPasswordObscured, // Controlled by the state
              decoration: InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isOldPasswordObscured
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isOldPasswordObscured =
                          !_isOldPasswordObscured; // Toggle visibility
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

            // New Password Field
            TextFormField(
              controller: _newPasswordController,
              obscureText: _isNewPasswordObscured, // Controlled by the state
              decoration: InputDecoration(
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
                          !_isNewPasswordObscured; // Toggle visibility
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

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText:
                  _isConfirmPasswordObscured, // Controlled by the state
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordObscured
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordObscured =
                          !_isConfirmPasswordObscured; // Toggle visibility
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

            // Change Password Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  String oldPassword = _oldPasswordController.text;
                  String newPassword = _newPasswordController.text;

                  // Call the callback function passed from parent to handle password change
                  changePassword(oldPassword, newPassword);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Change Password",
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
    );
  }
}
