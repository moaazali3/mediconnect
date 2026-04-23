import 'package:flutter/material.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Appointments",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: const [
          AppointmentCard(
            name: "Dr. Ahmed Mohamed",
            spec: "Cardiology Specialist",
            date: "12 May, 2024",
            time: "05:00 PM",
          ),
          AppointmentCard(
            name: "Dr. Sara Ali",
            spec: "Dental Surgeon",
            date: "15 May, 2024",
            time: "03:00 PM",
          ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String name;
  final String spec;
  final String date;
  final String time;

  const AppointmentCard({
    super.key,
    required this.name,
    required this.spec,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: const Icon(Icons.person, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: primaryColor.withOpacity(0.7)),
                    const SizedBox(width: 5),
                    Text(date, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 15),
                    Icon(Icons.access_time_rounded, size: 14, color: primaryColor.withOpacity(0.7)),
                    const SizedBox(width: 5),
                    Text(time, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
