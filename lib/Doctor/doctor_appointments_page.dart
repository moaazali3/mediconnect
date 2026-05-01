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
  bool _isProcessing = false;

  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String id, bool isAccept, {DoctorAppointmentModel? appointment}) async {
    if (isAccept && appointment != null) {
      _showMedicalRecordDialog(appointment);
      return;
    }

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
              content: Text(isAccept ? "Appointment Completed!" : "Appointment Cancelled!"),
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

  void _showMedicalRecordDialog(DoctorAppointmentModel appointment) {
    _diagnosisController.clear();
    _prescriptionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Medical Record - ${appointment.patientName}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: "Diagnosis", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _prescriptionController,
                decoration: const InputDecoration(labelText: "Prescription", border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (_diagnosisController.text.isEmpty || _prescriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              Navigator.pop(context); // Close dialog
              setState(() => _isProcessing = true);

              try {
                // 1. Create Medical Record using appointmentId
                final recordSuccess = await _apiService.createMedicalRecord(
                  appointmentId: appointment.appointmentId,
                  diagnosis: _diagnosisController.text,
                  prescription: _prescriptionController.text,
                );

                if (recordSuccess) {
                  // 2. Complete Appointment Status
                  await _apiService.completeAppointmentStatus(appointment.appointmentId);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Success: Record created & Appointment completed"), backgroundColor: Colors.green),
                    );
                    setState(() {}); // Refresh list
                  }
                } else {
                  throw "Failed to create medical record";
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text("SAVE & COMPLETE"),
          ),
        ],
      ),
    );
  }

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
      body: Stack(
        children: [
          Column(
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
                    
                    var appointments = snapshot.data ?? [];
                    
                    // Sorting logic: Date then Start Time
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
                        final bool isFinalized = appointment.status == "Completed" || appointment.status == "Cancelled";

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
                                          "Day: ${appointment.dayOfWeek} • ${appointment.status}",
                                          style: TextStyle(
                                            color: appointment.status == "Completed" 
                                              ? Colors.green 
                                              : (appointment.status == "Cancelled" ? Colors.red : Colors.grey.shade600), 
                                            fontSize: 13,
                                            fontWeight: isFinalized ? FontWeight.bold : FontWeight.normal
                                          ),
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
                              if (!isFinalized) ...[
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isProcessing ? null : () => _updateStatus(appointment.appointmentId, false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text("Cancel"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isProcessing ? null : () => _updateStatus(appointment.appointmentId, true, appointment: appointment),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text("Accept"),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
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
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }
}
