import 'package:flutter/material.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/admin/admin_dashboard.dart';
import 'package:mediconnect/home_screen.dart';
import 'package:mediconnect/Doctor/doctor_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  String? token = prefs.getString('auth_token');
  String? role = prefs.getString('user_role');
  String? userId = prefs.getString('user_id');

  Widget homeWidget = const LoginScreen();

  if (token != null && role != null && userId != null) {
    if (role == "admin") {
      homeWidget = const AdminDashboard();
    } else if (role == "doctor") {
      homeWidget = DoctorHomeScreen(userId: userId);
    } else {
      homeWidget = HomeScreen(userId: userId, userRole: role);
    }
  }

  runApp(MyApp(homeWidget: homeWidget));
}

class MyApp extends StatelessWidget {
  final Widget homeWidget;
  const MyApp({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: homeWidget,
    );
  }
}
