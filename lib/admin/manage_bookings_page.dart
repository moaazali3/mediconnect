import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  final _apiService = ApiService();
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _apiService.getAllDoctors();
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading doctors: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Bookings", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _doctors.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.person, color: primaryColor),
                    ),
                    title: Text("${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(doctor.specializationName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorBookingsDetail(doctor: doctor),
                        ),
                      ).then((_) => setState(() {})); // Refresh when returning
                    },
                  ),
                );
              },
            ),
    );
  }
}

class DoctorBookingsDetail extends StatefulWidget {
  final DoctorModel doctor;
  const DoctorBookingsDetail({super.key, required this.doctor});

  @override
  State<DoctorBookingsDetail> createState() => _DoctorBookingsDetailState();
}

class _DoctorBookingsDetailState extends State<DoctorBookingsDetail> {
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

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAccept ? "Appointment Accepted!" : "Appointment Cancelled!"),
              backgroundColor: isAccept ? Colors.green : Colors.red,
            ),
          );
          setState(() {}); // Refresh list
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookings: ${widget.doctor.firstName}", style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<DoctorAppointmentModel>>(
            future: _apiService.getDoctorAppointments(widget.doctor.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No bookings found for this doctor."));
              }

              final appointments = snapshot.data!;
              
              // Sorting logic: Date then Start Time
              appointments.sort((a, b) {
                int dateCompare = a.appointmentDate.compareTo(b.appointmentDate);
                if (dateCompare != 0) return dateCompare;
                return a.startTime.compareTo(b.startTime);
              });

              return ListView.builder(
                itemCount: appointments.length,
                padding: const EdgeInsets.all(15),
                itemBuilder: (context, index) {
                  final app = appointments[index];
                  final bool isFinalized = app.status == "Completed" || app.status == "Cancelled" || app.status == "Confirmed";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(app.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  app.status,
                                  style: TextStyle(
                                    color: _getStatusColor(app.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Date: ${app.appointmentDate}", style: TextStyle(color: Colors.grey[700])),
                                  Text("Time: ${app.startTime} - ${app.endTime}", style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Queue: #${app.queueNumber}",
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (!isFinalized) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Accept"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'completed': 
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }
}
