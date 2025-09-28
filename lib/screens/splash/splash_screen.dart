import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Splash screen duration - AuthWrapper will handle navigation
  }

  void _initializeApp() async {
    // Log app open event
    await FirebaseService.logScreenView('splash_screen');
    await FirebaseService.logEvent(
      'app_open',
      parameters: {'app_version': '1.0.0', 'platform': 'android'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: size.width * 0.70,
              height: size.width * 0.70,
            ),
            const SizedBox(height: 20),
            Transform(
              transform: Matrix4.translationValues(0, -85, 0),
              child: Text(
                'Book & Relax',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
