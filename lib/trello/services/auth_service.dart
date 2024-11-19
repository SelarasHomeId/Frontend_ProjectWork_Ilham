import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:selarashomeid/trello/utils/constant.dart';

class AuthService {
  // Metode untuk login
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final url = '$apiUrl/auth/login'; // Ganti dengan endpoint login Anda
    final uri = Uri.parse(url);

    // Data body untuk permintaan POST
    final body = jsonEncode({
      "email": email,
      "password": password,
      "login_form": "mobile",
    });

    try {
      // Permintaan POST ke endpoint
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: body,
      );

      // Periksa status kode respons
      if (response.statusCode == 200) {
        // Decode JSON respons ke Map
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json; // Kembalikan respons sebagai Map
      } else {
        // Jika status kode bukan 200
        print("Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // Tangani kesalahan
      print("Exception: $e");
      return null;
    }
  }
}
