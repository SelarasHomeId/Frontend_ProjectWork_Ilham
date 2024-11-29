import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Library alternatif
import '/trello/screens/login_screen.dart'; // Import LoginScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftar gambar untuk slider
    final List<String> imgList = [
      'lib/assets/slide1.png',
      'lib/assets/slide2.png',
      'lib/assets/slide3.png',
      'lib/assets/slide4.png',
      'lib/assets/slide5.png',
    ];

    final PageController _pageController =
        PageController(); // Controller untuk PageView

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
          // Slider menggunakan PageView
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imgList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imgList[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10), // Jarak antara slider dan indikator
          // Indikator untuk PageView
          SmoothPageIndicator(
            controller: _pageController,
            count: imgList.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Colors.red,
              dotColor: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: 20), // Jarak antara indikator dan konten
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
