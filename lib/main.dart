import 'package:flutter/material.dart';
import 'package:mediconnect/LoginScreen.dart';
import 'package:mediconnect/admin/admin_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // خليتها تفتح على صفحة الأدمن عشان تجربها
    );
  }
}
