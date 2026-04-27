import 'package:flutter/material.dart';
import 'package:mediconnect/Doctor/doctor_home_screen.dart';
import 'package:mediconnect/home_screen.dart';
import 'package:mediconnect/LoginScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // تقدر تجرب الـ Home مباشرة دلوقتي لأن البراميترز اختيارية
    );
  }
}
