import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return {
      'name': name,
      'email': email,
      'initials': initials,
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
}
