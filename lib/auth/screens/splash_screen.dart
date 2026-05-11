import 'package:flutter/material.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/admin/admin_dashboard.dart';
import 'package:mediconnect/home_screen.dart';
import 'package:mediconnect/Doctor/doctor_home_screen.dart';
import 'package:mediconnect/receptionist/receptionist_dashboard.dart';
import 'package:mediconnect/services/secure_storage.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  Future<void> _initializeApp() async {
    // 1. Minimum delay for the logo visibility
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 2. Auth & Session Logic
      String? token = await SecureStorage.readData(key: 'auth_token');
      ApiService.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString('user_role');
      String? userId = prefs.getString('user_id');

      Widget targetScreen = const LoginScreen();

      if (token != null && role != null && userId != null) {
        final refreshResult = await ApiService().refreshToken();

        if (refreshResult.success) {
          final String lowerRole = role.toLowerCase();
          if (lowerRole == "admin") {
            targetScreen = const AdminDashboard();
          } else if (lowerRole == "doctor") {
            targetScreen = DoctorHomeScreen(userId: userId);
          } else if (lowerRole == "receptionist") {
            targetScreen = const ReceptionistDashboard();
          } else {
            targetScreen = HomeScreen(userId: userId, userRole: role);
          }
        } else {
          // Refresh failed — clear session
          await SecureStorage.deleteAllData();
          ApiService.setToken(null);
          await prefs.clear();
        }
      }

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      debugPrint("Splash initialization error: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on theme
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF4F7FA);
    final Color textColor = isDark ? const Color(0xFF4A90D9) : const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with a subtle animation or just centered
            Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/images/img.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            CircularProgressIndicator(
              color: textColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              "MediConnect",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
