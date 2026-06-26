import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import '../patient/patient_main_layout.dart';
import '../doctor/doctor_main_layout.dart';
import '../../core/theme/app_theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Checking Firebase Auth State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryMid),
            ),
          );
        }

        // If user is logged in to Firebase
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, prefSnapshot) {
              // Checking Shared Preferences State
              if (prefSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryMid),
                  ),
                );
              }

              final prefs = prefSnapshot.data;
              final role = prefs?.getString('userRole') ?? 'patient';

              if (role.toLowerCase() == 'doctor') {
                return const DoctorMainLayout();
              }
              return const PatientMainLayout();
            },
          );
        }

        // If no user is logged in, return LoginScreen
        return const LoginScreen();
      },
    );
  }
}
