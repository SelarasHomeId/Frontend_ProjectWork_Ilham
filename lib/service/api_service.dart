import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:selarashomeid/screens/login_screen.dart';
import 'package:selarashomeid/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Metode untuk login
  static Future<Map<String, dynamic>?> apiRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
    String contentType = 'application/json',
  }) async {
    final url = '$baseUrl$endpoint';
    Map<String, String> header = {'Content-Type': contentType};
    if (token != null) {
      header['Authorization'] = 'Bearer $token';
    }
    http.Response response;

    try {
      // Fungsi untuk mengirim request
      Future<http.Response> sendRequest() async {
        switch (method.toUpperCase()) {
          case 'POST':
            return contentType == 'application/json'
                ? http.post(Uri.parse(url),
                    headers: header, body: jsonEncode(body))
                : await _handleMultipartRequest(method, url, header, body);
          case 'GET':
            return http.get(Uri.parse(url), headers: header);
          case 'PUT':
            return contentType == 'application/json'
                ? http.put(Uri.parse(url),
                    headers: header, body: jsonEncode(body))
                : await _handleMultipartRequest(method, url, header, body);
          case 'DELETE':
            return http.delete(Uri.parse(url), headers: header);
          case 'PATCH':
            return contentType == 'application/json'
                ? http.patch(Uri.parse(url),
                    headers: header, body: jsonEncode(body))
                : await _handleMultipartRequest(method, url, header, body);
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
      }

      // Kirim request awal
      response = await sendRequest();

      // Jika status code 401, refresh token
      if (response.statusCode == 401 && endpoint != '/auth/login') {
        final newToken = await _refreshToken(token);
        if (newToken != null) {
          // Update header dengan token baru
          header['Authorization'] = 'Bearer $newToken';

          // Kirim ulang permintaan dengan token baru
          response = await sendRequest();
        } else {
          throw Exception('Failed to refresh token');
        }
      }

      // Periksa status response
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json;
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

// Fungsi untuk menangani multipart request
  static Future<http.Response> _handleMultipartRequest(
      String method,
      String url,
      Map<String, String> header,
      Map<String, dynamic>? body) async {
    var request = http.MultipartRequest(method, Uri.parse(url))
      ..headers.addAll(header);
    body?.forEach((key, value) {
      request.fields[key] = value;
    });
    return await http.Response.fromStream(await request.send());
  }

// Fungsi untuk refresh token
  static Future<String?> _refreshToken(String? oldToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Authorization': 'Bearer $oldToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['data']['token'];

        // Simpan token baru di SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', newToken);

        return newToken;
      } else {
        print("Failed to refresh token: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error refreshing token: $e");
      return null;
    }
  }

//get user profile
  static Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? 'User Name';
    final email = prefs.getString('email') ?? 'user@example.com';
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return {
      'name': name,
      'email': email,
      'initials': initials,
    };
  }

//Logout
  static Future<void> logout(BuildContext context) async {
    try {
      // Bersihkan token dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Hapus semua data session pengguna

      // Arahkan pengguna ke LoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false, // Menghapus semua riwayat navigasi sebelumnya
      );
    } catch (e) {
      // Tangani error jika diperlukan
      print('Error saat logout: $e');
    }
  }
}
