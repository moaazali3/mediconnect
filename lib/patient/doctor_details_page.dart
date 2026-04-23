import 'package:flutter/material.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String name;
  final String spec;

  const DoctorDetailsPage({
    super.key,
    required this.name,
    required this.spec,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 40),
            ),

            const SizedBox(height: 15),

            Text(
              name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text(spec),

            const SizedBox(height: 20),

            const Text("⭐ 4.8 (120 reviews)"),

            const SizedBox(height: 30),

            // 🔥 زرار الحجز
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Doctor booked successfully!"),
                    ),
                  );
                },
                child: const Text("Book Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}