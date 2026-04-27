import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Adding userId to fetch profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    // If no userId is provided (not logged in or dummy data), we show a placeholder or handle it
    String idToFetch = widget.userId ?? "1"; // Default to "1" for testing if ID is missing

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<PatientProfileModel>(
        future: _apiService.getPatientProfile(idToFetch),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}"),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No Profile Data Found"));
          }

          final patient = snapshot.data!;
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withOpacity(0.2), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(
                        patient.gender == "Male" ? Icons.face_rounded : Icons.face_3_rounded, 
                        size: 80, 
                        color: primaryColor
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "${patient.firstName} ${patient.lastName}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    patient.email,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildProfileSection("Personal Info", [
                    _buildProfileField(Icons.phone_outlined, "Phone Number", patient.phoneNumber),
                    _buildProfileField(Icons.cake_outlined, "Date of Birth", patient.dateOfBirth),
                    _buildProfileField(Icons.location_on_outlined, "Address", patient.address ?? "Not set"),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  _buildProfileSection("Health Details", [
                    Row(
                      children: [
                        Expanded(child: _buildProfileField(Icons.bloodtype_outlined, "Blood", patient.bloodType)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildProfileField(Icons.height_rounded, "Height", "${patient.height} cm")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildProfileField(Icons.monitor_weight_outlined, "Weight", "${patient.weight} kg")),
                        const SizedBox(width: 10),
                        Expanded(child: _buildProfileField(Icons.contact_emergency_outlined, "Emergency", patient.emergencyContact)),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      child: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 10),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
