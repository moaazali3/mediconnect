import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class TodayAppointmentsPage extends StatefulWidget {
  const TodayAppointmentsPage({super.key});

  @override
  State<TodayAppointmentsPage> createState() => _TodayAppointmentsPageState();
}

class _TodayAppointmentsPageState extends State<TodayAppointmentsPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        _apiService.getAllSpecializations(),
        _apiService.getAllDoctors(),
        _apiService.getAllAppointments(),
      ]);
    });
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
                                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                                  child: Text("${index + 1}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.patientName.isNotEmpty ? app.patientName : "Patient: ${app.patientId.length > 8 ? app.patientId.substring(0, 8) : app.patientId}...",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Doctor: ${app.doctorName.isNotEmpty ? app.doctorName : "ID: ${app.doctorId.length > 8 ? app.doctorId.substring(0, 8) : app.doctorId}"}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
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
      appBar: const CommonAppBar(
        title: "Today's Appointments",
        showBackButton: true,
      ),
      body: FutureBuilder(
        future: _dataFuture,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text("Retry")),
                ],
              ),
            );
          }

          final List<DoctorModel> doctors = snapshot.data![1];
          final List<AppointmentModel> allAppointments = snapshot.data![2];

          // Filter today's appointments - be robust with the date format using 'contains'
          final todayAppointments = allAppointments.where((app) => app.appointmentDate.contains(todayDate)).toList();

          // Group appointments by specialization name for better visibility
          Map<String, List<AppointmentModel>> specGroup = {};
          for (var app in todayAppointments) {
            String specName = "Other";
            for (var d in doctors) {
              if (d.id.toString() == app.doctorId.toString()) {
                specName = d.specializationName.isNotEmpty ? d.specializationName : "General";
                break;
              }
            }
            specGroup.putIfAbsent(specName, () => []).add(app);
          }

          if (todayAppointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  Text("No appointments for today.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  Text("Checked for: $todayDate", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  if (allAppointments.isNotEmpty) 
                    Text("Total appointments on server: ${allAppointments.length}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }

          final groupNames = specGroup.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: groupNames.length,
            itemBuilder: (context, index) {
              final name = groupNames[index];
              final list = specGroup[name]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showAppointmentsDetails(context, name, list),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
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
                                      name,
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
