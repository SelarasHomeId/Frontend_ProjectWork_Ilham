import 'dart:convert';
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
      return null;
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

  // ==================================================================================================== //
}
