import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';

class AppointmentsPage extends StatefulWidget {
  final String? userId;
  const AppointmentsPage({super.key, this.userId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final ApiService _apiService = ApiService();

  Future<void> _cancelAppointment(String appointmentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final success = await _apiService.cancelAppointmentStatus(appointmentId);
      if (mounted) {
        Navigator.pop(context); // Close loading
        if (success) {
          setState(() {}); // Refresh list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment cancelled successfully"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to cancel appointment"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            final appointments = snapshot.data ?? [];
            if (appointments.isEmpty) {
              return const Center(child: Text("No appointments found"));
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
                  onCancel: () => _cancelAppointment(appointment.appointmentId),
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
  final VoidCallback onCancel;

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.name,
    required this.spec,
    required this.date,
    required this.time,
    required this.status,
    required this.queue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    bool isPending = status.toLowerCase() == 'pending';

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
        children: [
          Row(
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
                    Text(
                      spec,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, date),
              _buildInfoItem(Icons.access_time_rounded, time),
              _buildInfoItem(Icons.format_list_numbered_rounded, "Queue: #$queue"),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text("Cancel Appointment"),
                          content: const Text("Are you sure you want to cancel this appointment?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Keep it")),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onCancel();
                              }, 
                              child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }
}
