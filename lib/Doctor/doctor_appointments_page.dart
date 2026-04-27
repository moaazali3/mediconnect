import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final String? doctorId;
  const DoctorAppointmentsPage({super.key, this.doctorId});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    String idToFetch = widget.doctorId ?? "1";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Incoming Appointments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DoctorAppointmentModel>>(
              future: _apiService.getDoctorAppointments(idToFetch),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("Error: ${snapshot.error}"),
                    ),
                  );
                }
                
                final appointments = snapshot.data ?? [];
                
                // --- Sorting logic ---
                // We sort by date first, then by start time
                appointments.sort((a, b) {
                  int dateCompare = a.appointmentDate.compareTo(b.appointmentDate);
                  if (dateCompare != 0) return dateCompare;
                  return a.startTime.compareTo(b.startTime);
                });

                if (appointments.isEmpty) {
                  return const Center(child: Text("No appointments found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                                child: Text(
                                  appointment.patientName.isNotEmpty ? appointment.patientName[0] : "?",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appointment.patientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      "Day: ${appointment.dayOfWeek}",
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
                                child: Text(
                                  "Queue #${appointment.queueNumber}",
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 5),
                                  Text(appointment.appointmentDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${appointment.startTime} - ${appointment.endTime}",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
