import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/patient/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceptionistPendingAppointmentsPage extends StatefulWidget {
  const ReceptionistPendingAppointmentsPage({super.key});

  @override
  State<ReceptionistPendingAppointmentsPage> createState() => _ReceptionistPendingAppointmentsPageState();
}

class _ReceptionistPendingAppointmentsPageState extends State<ReceptionistPendingAppointmentsPage> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  Future<void> _updateStatus(String id, bool isAccept) async {
    setState(() => _isProcessing = true);
    try {
      bool success;
      if (isAccept) {
        success = await _apiService.completeAppointmentStatus(id);
      } else {
        success = await _apiService.cancelAppointmentStatus(id);
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccept ? "Appointment Completed!" : "Appointment Cancelled!", style: const TextStyle(color: Colors.white)),
            backgroundColor: isAccept ? Colors.green : Colors.red,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _navigateToProfile(String patientId) {
    if (patientId.isNotEmpty && patientId != "0") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: patientId,
            readOnly: true,
            showMedicalHistory: false,
          ),
        ),
      );
    }
  }

  Future<List<AppointmentModel>> _fetchPendingAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return [];

    final appointments = await _apiService.getReceptionistAppointments(userId);
    return appointments.where((a) => a.status.toLowerCase() == 'pending').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          FutureBuilder<List<AppointmentModel>>(
            future: _fetchPendingAppointments(),
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

              final appointments = snapshot.data ?? [];

              // Sort appointments by date and time
              appointments.sort((a, b) {
                int dateComp = a.appointmentDate.compareTo(b.appointmentDate);
                if (dateComp != 0) return dateComp;
                return a.startTime.compareTo(b.startTime);
              });

              if (appointments.isEmpty) {
                return const Center(child: Text("No pending appointments found"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return PendingAppointmentCard(
                    appointment: appointment,
                    onAccept: () => _updateStatus(appointment.appointmentId, true),
                    onCancel: () => _updateStatus(appointment.appointmentId, false),
                    onTapProfile: () => _navigateToProfile(appointment.patientId),
                    isProcessing: _isProcessing,
                  );
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }
}

class PendingAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onTapProfile;
  final bool isProcessing;

  const PendingAppointmentCard({
    super.key,
    required this.appointment,
    required this.onAccept,
    required this.onCancel,
    required this.onTapProfile,
    required this.isProcessing,
  });

  // دالة صغيرة عشان نشيل الثواني من الوقت
  String _formatTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5); // بياخد أول 5 حروف بس (مثال: 10:00)
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapProfile,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // التعديل السحري هنا: استبدال الأيقونة بأول حرف من الاسم
                      CircleAvatar(
                        radius: 28, // كبرناها سنة عشان تبان أشيك
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Text(
                          appointment.patientName.isNotEmpty ? appointment.patientName[0].toUpperCase() : "?",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appointment.patientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF263238),
                              ),
                            ),
                            Text(
                              "Doctor: ${appointment.doctorName}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Pending",
                          style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildInfoItem(Icons.calendar_today_rounded, appointment.appointmentDate)),
                      const SizedBox(width: 4),
                      // استخدمنا الدالة هنا عشان نقص الثواني
                      Expanded(child: _buildInfoItem(Icons.access_time_rounded, _formatTime(appointment.startTime))),
                      const SizedBox(width: 4),
                      Expanded(child: _buildInfoItem(Icons.format_list_numbered_rounded, "Queue #${appointment.queueNumber}")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("Completed", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500)
          ),
        ),
      ],
    );
  }
}