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

  void _showAppointmentsDetails(BuildContext context, String specName, List<AppointmentModel> appointments) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Bookings: $specName",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: appointments.isEmpty
                    ? const Center(child: Text("No patient details found."))
                    : ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final app = appointments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  child: Text("${index + 1}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.patientName.isNotEmpty ? app.patientName : "Patient ID: ${app.patientId.substring(0, 8)}...",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Doctor: ${app.doctorName.isNotEmpty ? app.doctorName : "ID: " + app.doctorId.substring(0,8)}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    app.startTime,
                                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Today's Overview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: Future.wait([_specializationsFuture, _doctorsFuture, _allAppointmentsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final List<SpecializationModel> specializations = snapshot.data![0];
          final List<DoctorModel> doctors = snapshot.data![1];
          final List<AppointmentModel> allAppointments = snapshot.data![2];

          // Filter today's appointments
          final todayAppointments = allAppointments.where((app) => app.appointmentDate.startsWith(todayDate)).toList();

          // Group appointments by specialization
          Map<int, List<AppointmentModel>> specGroup = {};
          for (var app in todayAppointments) {
            String specName = "";
            for (var d in doctors) {
              if (d.id.toString() == app.doctorId) {
                specName = d.specializationName;
                break;
              }
            }
            
            var spec = specializations.firstWhere(
              (s) => s.name == specName,
              orElse: () => SpecializationModel(id: -1, name: "Other", description: "")
            );
            
            if (spec.id != -1) {
              if (!specGroup.containsKey(spec.id)) specGroup[spec.id] = [];
              specGroup[spec.id]!.add(app);
            }
          }

          if (todayAppointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  Text("No appointments for today.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: specializations.length,
            itemBuilder: (context, index) {
              final spec = specializations[index];
              final list = specGroup[spec.id] ?? [];

              if (list.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showAppointmentsDetails(context, spec.name, list),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.medical_services_outlined, color: primaryColor),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      spec.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3142)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${list.length}",
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${list.length} person${list.length > 1 ? 's' : ''} booked today",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        ],
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
