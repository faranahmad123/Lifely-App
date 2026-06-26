import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../intro/intro_screen.dart';
import '../auth/auth_wrapper.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Simulate a tiny delay for smooth visual transition if needed, though not strictly required
    await Future.delayed(const Duration(milliseconds: 500));
    return prefs.getBool('hasSeenIntro') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFirstLaunch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.primaryDark,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final hasSeenIntro = snapshot.data ?? false;
        if (hasSeenIntro) {
          return const AuthWrapper();
        } else {
          return const IntroScreen();
        }
      },
    );
  }
}
