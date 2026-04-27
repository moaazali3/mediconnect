import 'package:flutter/material.dart';
import 'package:mediconnect/patient/doctor_details_page.dart';

class DoctorCard extends StatelessWidget {
  final String id;
  final String name;
  final String spec;
  final String gender;
  final double experience;

  const DoctorCard({
    required this.id,
    required this.name,
    required this.spec,
    required this.gender,
    required this.experience,
    super.key,
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
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: (gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
              child: Icon(
                gender == "Male" ? Icons.male : Icons.female, 
                size: 35, 
                color: gender == "Male" ? Colors.blue : Colors.pink
              ),
            ),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. $name",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.history_edu, color: primaryColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "$experience Years Exp.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorDetailsPage(doctorId: id),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
