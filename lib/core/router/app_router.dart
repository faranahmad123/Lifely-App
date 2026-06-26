import 'package:flutter/material.dart';
import '../../screens/intro/intro_screen.dart';
import '../../screens/intro/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/patient/patient_main_layout.dart';
import '../../screens/patient/scan_report_screen.dart';
import '../../screens/patient/book_appointment_screen.dart';
import '../../screens/doctor/doctor_main_layout.dart';
import '../../screens/doctor/dashboard/doctor_dashboard.dart';
import '../../screens/doctor/profile/doctor_profile_screen.dart';
import '../../screens/doctor/patients/patient_list_screen.dart';
import '../../screens/doctor/schedule/schedule_screen.dart';

class AppRouter {
  static const String intro = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String patientDashboard = '/patient';
  static const String scanReport = '/scan_report';
  static const String bookAppointment = '/book_appointment';
  static const String doctorMainLayout = '/doctor';
  static const String doctorDashboard = '/doctor_home';
  static const String doctorProfile = '/doctor_profile';
  static const String doctorSchedule = '/doctor_schedule';
  static const String doctorPatients = '/doctor_patients';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case intro:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case patientDashboard:
        return MaterialPageRoute(builder: (_) => const PatientMainLayout());
      case scanReport:
        return MaterialPageRoute(builder: (_) => const ScanReportScreen());
      case bookAppointment:
        return MaterialPageRoute(builder: (_) => const BookAppointmentScreen());
      case doctorMainLayout:
        return MaterialPageRoute(builder: (_) => const DoctorMainLayout());
      case doctorDashboard:
        return MaterialPageRoute(builder: (_) => const DoctorDashboard());
      case doctorProfile:
        return MaterialPageRoute(builder: (_) => const DoctorProfileScreen());
      case doctorSchedule:
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());
      case doctorPatients:
        return MaterialPageRoute(builder: (_) => const PatientListScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
