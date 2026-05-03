import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/Doctor/doctor_profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String doctorId;
  final String? patientId; 

  const DoctorDetailsPage({super.key, required this.doctorId, this.patientId});

  void _showBookAppointmentSheet(BuildContext context, DoctorProfileModel doctor) {
    final ApiService apiService = ApiService();
    String selectedDay = "Monday";
    final List<String> days = [
      "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        DateTime now = DateTime.now();
                        int targetDayIndex = days.indexOf(selectedDay) + 1; 
                        int currentDayIndex = now.weekday;
                        int daysToAdd = (targetDayIndex - currentDayIndex + 7) % 7;
                        
                        DateTime targetDate = now.add(Duration(days: daysToAdd));
                        String formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);

                        final appointment = CreateAppointmentModel(
                          patientId: patientId ?? "1", 
                          doctorId: doctorId,
                          dayOfWeek: selectedDay,
                          appointmentDate: formattedDate,
                        );

                        Navigator.pop(context); 
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
                        );

                        // تم التعديل هنا: استخدام String? بدلاً من bool
                        String? appointmentId = await apiService.createAppointment(appointment);
                        
                        if (context.mounted) {
                          Navigator.pop(context); // إغلاق نافذة التحميل
                          if (appointmentId != null) {
                            _showQRSuccessDialog(context, appointmentId, doctor, formattedDate);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to book appointment"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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

  void _showQRSuccessDialog(BuildContext context, String appointmentId, DoctorProfileModel doctor, String date) {
    final String qrData = jsonEncode({
      "appointmentId": appointmentId,
      "doctor": "Dr. ${doctor.firstName} ${doctor.lastName}",
      "date": date,
      "time": "TBD",
      "queue": "N/A"
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
            const SizedBox(height: 15),
            const Text("Booking Successful!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Show this QR code at the reception.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              height: 180,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 180.0,
                foregroundColor: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            Text("Dr. ${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الحوار
                  Navigator.pop(context); // العودة للشاشة السابقة
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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
        title: const Text("Booking Appointment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(context, doctor),
                const SizedBox(height: 30),
                const Text("Select Service", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information_outlined, color: primaryColor),
                      const SizedBox(width: 15),
                      const Expanded(child: Text("General Consultation", style: TextStyle(fontWeight: FontWeight.w600))),
                      Text("\$${doctor.consultationFee}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showBookAppointmentSheet(context, doctor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Continue to Book", 
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

  Widget _buildProfileCard(BuildContext context, DoctorProfileModel doctor) {
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
            radius: 35,
            backgroundColor: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
            child: Icon(
              doctor.gender == "Male" ? Icons.male : Icons.female,
              color: doctor.gender == "Male" ? Colors.blue : Colors.pink,
              size: 35,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Dr. ${doctor.firstName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: primaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorProfileScreen(doctorId: doctorId),
                          ),
                        );
                      },
                    )
                  ],
                ),
                Text(doctor.specializationName, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
