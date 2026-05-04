import 'package:flutter/material.dart';
import 'package:mediconnect/patient/screens/booking_screen.dart';

class DoctorCard extends StatelessWidget {
  final String id;
  final String name;
  final String spec;
  final String gender;
  final double experience;
  final String? imageUrl;
  final String? patientId;

  const DoctorCard({
    required this.id,
    required this.name,
    required this.spec,
    required this.gender,
    required this.experience,
    this.imageUrl,
    this.patientId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);
    const String baseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";

    String displaySpec = spec.trim();
    if (displaySpec.isEmpty || displaySpec.toLowerCase() == "null") {
      displaySpec = "Medical Specialist";
    }

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Doctor Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: (gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty) 
                  ? NetworkImage(imageUrl!.startsWith('http') ? imageUrl! : "$baseUrl$imageUrl") 
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty) 
                  ? Icon(
                      gender == "Male" ? Icons.male : Icons.female, 
                      size: 30, 
                      color: gender == "Male" ? Colors.blue : Colors.pink
                    ) 
                  : null,
            ),
          ),
          const SizedBox(width: 15),

          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Dr. $name",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displaySpec,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.history_edu, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "${experience.toStringAsFixed(1)} Years Exp.",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Button
          SizedBox(
            width: 45,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      doctorId: id,
                      doctorName: "Dr. $name",
                      specialty: displaySpec,
                      doctorImageUrl: imageUrl,
                      patientId: patientId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
