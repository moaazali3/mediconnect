import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppointmentsPage extends StatefulWidget {
  final String? userId;
  const AppointmentsPage({super.key, this.userId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    String idToFetch = widget.userId ?? "1";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: FutureBuilder<List<PatientAppointmentModel>>(
          future: _apiService.getPatientAppointments(idToFetch),
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

            final appointments = (snapshot.data ?? [])
                .where((a) => a.status.toLowerCase() == 'pending')
                .toList();

            // Sort appointments by date
            appointments.sort((a, b) {
              try {
                DateTime dateA = DateTime.parse(a.appointmentDate);
                DateTime dateB = DateTime.parse(b.appointmentDate);
                return dateA.compareTo(dateB);
              } catch (e) {
                return 0;
              }
            });

            if (appointments.isEmpty) {
              return const Center(child: Text("No pending appointments found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return AppointmentCard(
                  appointmentId: appointment.appointmentId,
                  name: "Dr. ${appointment.doctorName}",
                  spec: appointment.dayOfWeek,
                  date: appointment.appointmentDate,
                  time: "${appointment.startTime} - ${appointment.endTime}",
                  status: appointment.status,
                  queue: appointment.queueNumber,
                  imageUrl: appointment.doctorImageUrl,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String name;
  final String spec;
  final String date;
  final String time;
  final String status;
  final int queue;
  final String? imageUrl;

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.name,
    required this.spec,
    required this.date,
    required this.time,
    required this.status,
    required this.queue,
    this.imageUrl,
  });

  void _showQRCode(BuildContext context) {
    // تجهيز البيانات التي سيحتويها الـ QR
    final String qrData = jsonEncode({
      "appointmentId": appointmentId,
      "doctor": name,
      "date": date,
      "queue": queue
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Appointment QR Code", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Present this code at the hospital reception.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String baseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";

    Widget profileImage;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      String fullImageUrl = imageUrl!.startsWith('http') ? imageUrl! : "$baseUrl$imageUrl";
      profileImage = ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          fullImageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: primaryColor, size: 30),
        ),
      );
    } else {
      profileImage = const Icon(Icons.person, color: primaryColor, size: 30);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: profileImage,
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
                    Text(
                      spec,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showQRCode(context),
                icon: const Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 28),
                tooltip: "Show QR Code",
              ),
            ],
          ),
          const Divider(height: 30),

          // الحل هنا: استخدمنا Wrap بدل Row عشان لو الشاشة ضيقة ينزل الباقي في السطر اللي تحته
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8, // المسافة الأفقية بين العناصر
            runSpacing: 10, // المسافة الرأسية لو نزلوا في سطر جديد
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, date),
              _buildInfoItem(Icons.access_time_rounded, time),
              _buildInfoItem(Icons.format_list_numbered_rounded, "Queue: #$queue"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min, // مهمة جداً عشان الـ Wrap يعرف حجم العنصر بالظبط ومياخدش مساحة زيادة
      children: [
        Icon(icon, size: 14, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}