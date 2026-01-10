import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class SplashSlideshowPage extends StatefulWidget {
  const SplashSlideshowPage({super.key});

  @override
  State<SplashSlideshowPage> createState() => _SplashSlideshowPageState();
}

class _SplashSlideshowPageState extends State<SplashSlideshowPage> {
  @override
  void initState() {
    super.initState();

    // Wait 2.5 seconds then navigate to MainPage
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          "assets/logo_splash_screen.png", // your full-screen splash image
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
