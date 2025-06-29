import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/connection_checker.dart';
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
        resetPass: false
      );

      if (response != null && response['success'] == true) {
        General.showSnackBar(context, 'Password berhasil diubah!');
        ApiService.authLogout(context);
      } else {
        debugPrint("Response tidak valid atau gagal: $response");
        General.showSnackBar(context, 'Gagal mengupdate password');
      }
    } catch (e) {
      General.showDialogError(context: context,title: "Error",message: '$e',confirmButtonText: "Ok");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionChecker(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          oldPasswordFocusNode.unfocus();
          newPasswordFocusNode.unfocus();
          confirmPasswordFocusNode.unfocus();
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              minWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER DENGAN GRADIENT
                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // OLD PASSWORD
                        _buildPasswordField(
                          controller: _oldPasswordController,
                          focusNode: oldPasswordFocusNode,
                          label: "Password Lama",
                          icon: Icons.lock,
                          obscureText: _isOldPasswordObscured,
                          toggleObscure: () {
                            setState(() {
                              _isOldPasswordObscured = !_isOldPasswordObscured;
                            });
                          },
                          validator: (value) => General.validatePassword("Password Lama", value),
                        ),
                        SizedBox(height: 16),

                        // NEW PASSWORD
                        _buildPasswordField(
                          controller: _newPasswordController,
                          focusNode: newPasswordFocusNode,
                          label: "Password Baru",
                          icon: Icons.vpn_key,
                          obscureText: _isNewPasswordObscured,
                          toggleObscure: () {
                            setState(() {
                              _isNewPasswordObscured = !_isNewPasswordObscured;
                            });
                          },
                          validator: (value) {
                            if (value == _oldPasswordController.text) {
                              return 'Password Baru Tidak Boleh Sama dengan Password Lama';
                            }
                            return General.validatePassword("Password Baru", value);
                          },
                        ),
                        SizedBox(height: 16),

                        // CONFIRM PASSWORD
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          focusNode: confirmPasswordFocusNode,
                          label: "Konfirmasi Password",
                          icon: Icons.verified_user,
                          obscureText: _isConfirmPasswordObscured,
                          toggleObscure: () {
                            setState(() {
                              _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                            });
                          },
                          validator: (value) {
                            if (value != _newPasswordController.text) {
                              return 'Konfirmasi Password Tidak Sesuai';
                            }
                            return General.validatePassword("Konfirmasi Password", value);
                          },
                        ),
                        SizedBox(height: 24),

                        // SUBMIT BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState?.validate() ?? false) {
                                changePassword(
                                  _oldPasswordController.text,
                                  _newPasswordController.text,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.red[600],
                              elevation: 6,
                            ),
                            icon: Icon(Icons.save, color: Colors.white),
                            label: Text(
                              "Simpan Perubahan",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method untuk text field dengan dekorasi menarik
  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool obscureText,
    required void Function() toggleObscure,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          prefixIcon: Icon(icon),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: toggleObscure,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
