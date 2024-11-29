import 'package:flutter/material.dart';
import '/trello/screens/login_screen.dart'; // Import LoginScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen',
            style: TextStyle(color: Colors.white)), // Teks putih
        backgroundColor: Color.fromRGBO(224, 29, 24, 1), // Mengatur warna RGB
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white), // Ikon putih
            onPressed: () {
              // Navigasi ke LoginScreen dengan animasi loading
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LoadingScreen()), // Ganti dengan LoadingScreen
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20), // Jarak antara slider dan konten
          Center(
            child: Text('Welcome to Home Screen!'),
          ),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulasi loading sebelum navigasi ke LoginScreen
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Animasi loading
      ),
    );
  }
}
