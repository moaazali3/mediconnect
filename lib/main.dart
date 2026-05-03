import 'package:flutter/material.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/admin/admin_dashboard.dart';
import 'package:mediconnect/home_screen.dart';
import 'package:mediconnect/Doctor/doctor_home_screen.dart';
import 'package:mediconnect/receptionist/receptionist_dashboard.dart';
import 'package:mediconnect/services/secure_storage.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorage.init();
  
  // تحميل التوكن المحفوظ في الذاكرة للطلبات القادمة
  String? token = await SecureStorage.readData(key: 'auth_token');
  ApiService.setToken(token);
  
  final prefs = await SharedPreferences.getInstance();
  String? role = prefs.getString('user_role');
  String? userId = prefs.getString('user_id');

  Widget homeWidget = const LoginScreen();

  if (token != null && role != null && userId != null) {
    final String lowerRole = role.toLowerCase();
    if (lowerRole == "admin") {
      homeWidget = const AdminDashboard();
    } else if (lowerRole == "doctor") {
      homeWidget = DoctorHomeScreen(userId: userId);
    } else if (lowerRole == "receptionist") {
      homeWidget = const ReceptionistDashboard();
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
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0D47A1),
      ),
      home: homeWidget,
    );
  }
}
