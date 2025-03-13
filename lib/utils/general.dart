import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class General {
  static Future<void> saveToSharedPreferences(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    data.forEach((key, value) async {
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else {
        throw UnsupportedError(
            'Tipe data $key dengan nilai $value tidak didukung');
      }
    });
  }

  static Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> removeFromSharedPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      await prefs.remove(key);
    }
  }

  static Future<void> editSharedPreferences(
      String key, dynamic newValue) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(key)) {
      if (newValue is String) {
        await prefs.setString(key, newValue);
      } else if (newValue is int) {
        await prefs.setInt(key, newValue);
      } else if (newValue is double) {
        await prefs.setDouble(key, newValue);
      } else if (newValue is bool) {
        await prefs.setBool(key, newValue);
      } else {
        throw UnsupportedError('Tipe data untuk key "$key" tidak didukung');
      }
    }
  }

  static Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? 'User Name';
    final email = prefs.getString('email') ?? 'user@example.com';
    final roleName = prefs.getString('roleName') ?? ' - ';
    final divisiName = prefs.getString('divisiName') ?? ' - ';
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return {
      'name': name,
      'email': email,
      'initials': initials,
      'roleName': roleName,
      'divisiName': divisiName,
    };
  }

  String colorToString(Color color) {
    String colorString = color.value.toString(); // Mengubah menjadi string
    return colorString;
  }

  Color stringToColor(String colorString) {
    int colorInt = int.parse(colorString); // Mengonversi string ke integer
    Color color = Color(colorInt); // Mengubah integer menjadi Color
    return color;
  }

  static String buildQueryParams(Map<String, String>? params) {
    if (params == null || params.isEmpty) return '';
    return '?${Uri(queryParameters: params).query}';
  }

  static String getDateFilter(String filter) {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd'); // Format YYYY-MM-DD
    String startDate = "";
    String endDate = "";

    if (filter == "Today") {
      startDate = formatter.format(now);
      endDate = formatter.format(now);
    } else if (filter == "This Week") {
      DateTime startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)); // Senin awal minggu
      DateTime endOfWeek =
          startOfWeek.add(Duration(days: 6)); // Minggu akhir minggu

      startDate = formatter.format(startOfWeek);
      endDate = formatter.format(endOfWeek);
    } else if (filter == "This Month") {
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth =
          DateTime(now.year, now.month + 1, 0); // Hari terakhir bulan ini

      startDate = formatter.format(startOfMonth);
      endDate = formatter.format(endOfMonth);
    }

    return startDate.isNotEmpty && endDate.isNotEmpty
        ? '$startDate' '_' '$endDate'
        : "";
  }

  static Future<void> showSnackBar(
      BuildContext context, dynamic message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SizedBox(
          width: 200, // Lebar maksimum Snackbar
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating, // Supaya tidak full width
        margin: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Snackbar rounded
        ),
        backgroundColor: Colors.black87, // Warna lebih elegan
      ),
    );
  }
}
