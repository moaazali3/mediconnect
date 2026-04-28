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
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class DoctorBookingsDetail extends StatelessWidget {
  final DoctorModel doctor;
  const DoctorBookingsDetail({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Scaffold(
      appBar: AppBar(
        title: Text("Bookings: ${doctor.firstName}", style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<DoctorAppointmentModel>>(
        future: apiService.getDoctorAppointments(doctor.id),
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
          return ListView.builder(
            itemCount: appointments.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              final app = appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: ${app.appointmentDate}"),
                      Text("Time: ${app.startTime} - ${app.endTime}"),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: app.status.toLowerCase() == 'confirmed' ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      app.status,
                      style: TextStyle(
                        color: app.status.toLowerCase() == 'confirmed' ? Colors.green.shade900 : Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
