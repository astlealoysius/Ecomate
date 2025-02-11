import 'package:flutter/material.dart';
import '../main.dart'; // Import main.dart
import '../theme/app_theme.dart'; // Import theme

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to main app after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/logo.png', // Add your logo image to assets folder
              width: 350,
              height: 350,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
