import 'package:flutter/material.dart';
import 'package:mediconnect/Booking_Screen.dar.dart';
import 'package:mediconnect/LoginScreen.dart';
import 'package:mediconnect/patient_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: LoginScreen(),
       //home: PatientHistoryScreen(),
      home: BookingScreen(),
    );
  }
}
