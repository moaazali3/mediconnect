import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:intl/intl.dart';

class TodayAppointmentsPage extends StatefulWidget {
  const TodayAppointmentsPage({super.key});

  @override
  State<TodayAppointmentsPage> createState() => _TodayAppointmentsPageState();
}

class _TodayAppointmentsPageState extends State<TodayAppointmentsPage> {
  final ApiService _apiService = ApiService();
  late Future<List<SpecializationModel>> _specializationsFuture;
  late Future<List<DoctorModel>> _doctorsFuture;
  late Future<List<AppointmentModel>> _allAppointmentsFuture;

  @override
  void initState() {
    super.initState();
    _specializationsFuture = _apiService.getAllSpecializations();
    _doctorsFuture = _apiService.getAllDoctors();
    _allAppointmentsFuture = _apiService.getAllAppointments();
  }

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Appointments", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: Future.wait([_specializationsFuture, _doctorsFuture, _allAppointmentsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final List<SpecializationModel> specializations = snapshot.data![0];
          final List<DoctorModel> doctors = snapshot.data![1];
          final List<AppointmentModel> allAppointments = snapshot.data![2];

          // Filter for today's appointments
          final todayAppointments = allAppointments.where((app) => app.appointmentDate.startsWith(todayDate)).toList();

          // Count today's appointments per specialization
          Map<int, int> specCount = {};
          for (var app in todayAppointments) {
            // Find doctor for this appointment
            var doctor = doctors.firstWhere((d) => d.id.toString() == app.doctorId, 
                orElse: () => DoctorModel(id: "0", firstName: "", lastName: "", specializationName: "", gender: "", experienceYears: 0));
            
            var spec = specializations.firstWhere((s) => s.name == doctor.specializationName,
                orElse: () => SpecializationModel(id: -1, name: "", description: ""));
            
            if (spec.id != -1) {
              specCount[spec.id] = (specCount[spec.id] ?? 0) + 1;
            }
          }

          if (todayAppointments.isEmpty) {
            return const Center(child: Text("No appointments scheduled for today."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specializations.length,
            itemBuilder: (context, index) {
              final spec = specializations[index];
              final count = specCount[spec.id] ?? 0;

              if (count == 0) return const SizedBox.shrink();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.category, color: primaryColor),
                  ),
                  title: Text(
                    spec.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(spec.description.length > 50 ? "${spec.description.substring(0, 50)}..." : spec.description),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$count",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
