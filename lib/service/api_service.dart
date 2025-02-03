import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:selarashomeid/screens/login_screen.dart';
import 'package:selarashomeid/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ==================================================================================================== //

  // function api request for use api backend
  static Future<Map<String, dynamic>?> apiRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
    String contentType = 'application/json',
  }) async {
    // init
    http.Response response;
    final url = '$baseUrl$endpoint';
    Map<String, String> header = {'Content-Type': contentType};

    if (token != null) {
      header['Authorization'] = 'Bearer $token';
    }

    try {
      // function hit api
      Future<http.Response> hitAPI() async {
        switch (method.toUpperCase()) {
          case 'POST':
            if (contentType == 'application/json') {
              return http.post(
                Uri.parse(url),
                headers: header,
                body: jsonEncode(body),
              );
            }
            return _handleMultipartRequest(method, url, header, body);
          case 'GET':
            return http.get(Uri.parse(url), headers: header);
          case 'PUT':
            if (contentType == 'application/json') {
              return http.put(
                Uri.parse(url),
                headers: header,
                body: jsonEncode(body),
              );
            }
            return _handleMultipartRequest(method, url, header, body);
          // return contentType == 'application/json'
          //     ? http.put(Uri.parse(url),
          //         headers: header, body: jsonEncode(body))
          //     : await _handleMultipartRequest(method, url, header, body);
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

      // hit api
      response = await hitAPI();
      // cek if refresh token needed
      if (response.statusCode == 401 && endpoint != '/auth/login') {
        final newToken = await _refreshToken(token);

        if (newToken != null) {
          header['Authorization'] = 'Bearer $newToken';
          response = await hitAPI();
        } else {
          throw Exception('Failed to refresh token');
        }
      }

      // return body
      final Map<String, dynamic> jsonBody = jsonDecode(response.body);
      return jsonBody;
    } catch (e) {
      // return null;
      rethrow;
    }
  }

  // function hit api with multipart/form-data
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

  // function refresh token
  static Future<String?> _refreshToken(String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', newToken);
        return newToken;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==================================================================================================== //

  // auth
  static Future<Map<String, dynamic>?> authLogin(
      String email, String password) async {
    final response = await apiRequest(
        method: 'POST',
        endpoint: '/auth/login',
        body: {'email': email, 'password': password, 'login_from': 'mobile'},
        token: null,
        contentType: 'application/json');

    return response;
  }

  static Future<void> authLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await apiRequest(
        method: 'POST',
        endpoint: '/auth/logout',
        body: null,
        token: token,
        contentType: 'application/json');

    if (response != null && response['success'] == true) {
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false);
    }
  }

  // workspace
  static Future<List<Map<String, dynamic>>> workspaceFind() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await apiRequest(
      method: 'GET',
      endpoint: '/workspace',
      body: null,
      token: token,
      contentType: 'application/json',
    );

    return List<Map<String, dynamic>>.from(response?['data']['data']);
  }

  // Send email forgot password
  static Future<Map<String, dynamic>?> sendForgotPasswordEmail(
      String email) async {
    final response = await apiRequest(
      method: 'POST',
      endpoint: '/auth/send-email/forgot-password',
      body: {'email': email},
      token: null, // Token tidak diperlukan untuk reset password
      contentType: 'application/json',
    );

    return response;
  }

  // Fungsi untuk mendapatkan notifikasi
  static Future<Map<String, dynamic>?> getNotifications(String token) async {
    final response = await apiRequest(
      method: 'GET',
      endpoint: '/notifikasi?order=created_at&order_by=desc',
      body: null,
      token: token,
      contentType: 'application/json',
    );
    return response;
  }

  static Future<dynamic> handleBoard({
    required String method, // 'GET', 'POST', 'PUT', 'DELETE'
    required int workspaceId, // Tidak boleh null dan wajib diisi
    int? boardId, // Diperlukan untuk Update dan Delete
    Map<String, dynamic>? data, // Body data untuk Create atau Update
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Ambil token dari local storage

    // Tentukan endpoint berdasarkan metode
    String endpoint;
    if (method == 'GET') {
      endpoint = '/board/$workspaceId?order=sort_number&order_by=asc';
    } else if (method == 'POST') {
      endpoint = '/board'; // Endpoint untuk create board
    } else if (method == 'PUT' && boardId != null) {
      endpoint = '/board/$boardId'; // Endpoint untuk update board
    } else if (method == 'DELETE' && boardId != null) {
      endpoint = '/board/$boardId'; // Endpoint untuk delete board
    } else {
      throw Exception('Parameter tidak lengkap untuk operasi $method');
    }

    // Panggil API sesuai metode
    final response = await apiRequest(
      method: method,
      endpoint: endpoint,
      body: data,
      token: token,
      contentType: 'application/json',
    );

    // Validasi response
    if (response != null && response['success'] == true) {
      if (method == 'GET') {
        return List<Map<String, dynamic>>.from(response['data']['data']);
      } else {
        return response['data']; // Return hasil operasi selain GET
      }
    } else {
      throw Exception('Operasi $method gagal pada endpoint $endpoint');
    }
  }

  static Future<dynamic> handleTask({
    required String method, // 'GET', 'POST', 'PUT', 'DELETE'
    required int boardId, // Tidak boleh null dan wajib diisi
    int? taskId,
    Map<String, dynamic>? data, // Body data untuk Create atau Update
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Ambil token dari local storage

    // Tentukan endpoint berdasarkan metode
    String endpoint;
    if (method == 'GET') {
      endpoint = '/task/$boardId?order=sort_number&order_by=asc';
    } else if (method == 'POST') {
      endpoint = '/task'; // Endpoint untuk create board
    } else if (method == 'PUT' && taskId != null) {
      endpoint = '/task/$taskId'; // Endpoint untuk update board
    } else if (method == 'DELETE' && taskId != null) {
      endpoint = '/task/$taskId'; // Endpoint untuk delete board
    } else {
      throw Exception('Parameter tidak lengkap untuk operasi $method');
    }

    // Panggil API sesuai metode
    final response = await apiRequest(
      method: method,
      endpoint: endpoint,
      body: data,
      token: token,
      contentType: method == 'PUT' ? 'multipart/form-data' : 'application/json',
    );
    try {
      final encodeValue = json.encode(response);
      log(encodeValue, name: endpoint);
    } catch (e) {}

    // Validasi response
    if (response != null && response['success'] == true) {
      if (method == 'GET') {
        final currentData = response['data']['data'] ?? [];
        return List<Map<String, dynamic>>.from(currentData);
      } else {
        return response['data']; // Return hasil operasi selain GET
      }
    } else {
      throw Exception('Operasi $method gagal pada endpoint $endpoint');
    }
  }

  static Future<dynamic> handleLabel({
    required String method, // 'GET', 'POST', 'PUT', 'DELETE'
    int? labelId,
    Map<String, dynamic>? data, // Body data untuk Create atau Update
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Ambil token dari local storage

    // Tentukan endpoint berdasarkan metode
    String endpoint;
    if (method == 'GET') {
      endpoint = '/task/label${labelId != null ? "/$labelId" : ""}';
    } else if (method == 'POST') {
      endpoint = '/task/label'; // Endpoint untuk create board
    } else if (method == 'PUT' && labelId != null) {
      endpoint = '/task/label/$labelId'; // Endpoint untuk update board
    } else if (method == 'DELETE' && labelId != null) {
      endpoint = '/task/label/$labelId'; // Endpoint untuk delete board
    } else {
      throw Exception('Parameter tidak lengkap untuk operasi $method');
    }

    // Panggil API sesuai metode
    final response = await apiRequest(
      method: method,
      endpoint: endpoint,
      body: data,
      token: token,
      contentType: method == 'PUT' ? 'multipart/form-data' : 'application/json',
    );
    try {
      final encodeValue = json.encode(response);
      log(encodeValue, name: endpoint);
    } catch (e) {}

    // Validasi response
    if (response != null && response['success'] == true) {
      if (method == 'GET') {
        final currentData = response['data']['data'] ?? [];
        return List<Map<String, dynamic>>.from(currentData);
      } else {
        return response['data']; // Return hasil operasi selain GET
      }
    } else {
      throw Exception('Operasi $method gagal pada endpoint $endpoint');
    }
  }

  static Future<dynamic> handleDetailTask(
    int taskId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Ambil token dari local storage

    // Tentukan endpoint berdasarkan metode
    String endpoint = "/task/detail/$taskId";
    // Panggil API sesuai metode
    final response = await apiRequest(
      method: "GET",
      endpoint: endpoint,
      token: token,
    );
    try {
      final encodeValue = json.encode(response);
      log(encodeValue, name: endpoint);
    } catch (e) {}

    // Validasi response
    if (response != null && response['success'] == true) {
      return response['data']['data']; // Return hasil operasi selain GET
    } else {
      throw Exception('Operasi GET gagal pada endpoint $endpoint');
    }
  }

  // ==================================================================================================== //
}
