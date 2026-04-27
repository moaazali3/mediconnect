import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String doctorId;
  const DoctorDetailsPage({super.key, required this.doctorId});

  void _showBookAppointmentSheet(BuildContext context, String doctorId) {
    final ApiService apiService = ApiService();
    String selectedDay = "Monday";
    final List<String> days = [
      "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Preferred Day",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedDay = value);
                      }
                    },
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        final appointment = CreateAppointmentModel(
                          patientId: "1", // Use proper ID in production
                          doctorId: doctorId,
                          dayOfWeek: selectedDay,
                        );

                        Navigator.pop(context); 
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
                        );

                        bool success = await apiService.createAppointment(appointment);
                        
                        if (context.mounted) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? "Appointment Booked Successfully!" : "Failed to book appointment"),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Doctor Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<DoctorProfileModel>(
        future: apiService.getDoctorProfile(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          }

          final doctor = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(doctor),
                const SizedBox(height: 25),
                const Text("Biography", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(doctor.biography, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 25),
                _buildInfoSection(Icons.work_outline, "Experience", "${doctor.experienceYears} Years"),
                _buildInfoSection(Icons.payments_outlined, "Consultation Fee", "\$${doctor.consultationFee}"),
                _buildInfoSection(Icons.phone_outlined, "Phone Number", doctor.phoneNumber),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showBookAppointmentSheet(context, doctorId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Book Appointment", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(DoctorProfileModel doctor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
            child: Icon(
              doctor.gender == "Male" ? Icons.male : Icons.female,
              color: doctor.gender == "Male" ? Colors.blue : Colors.pink,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dr. ${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(doctor.specializationName, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 5),
                    Text("4.9 (120 reviews)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[600])),
              Text(content, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
