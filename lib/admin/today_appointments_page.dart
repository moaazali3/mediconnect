import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
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
  late Future<List<AppointmentModel>> _appointmentsFuture;
  DateTime _selectedDate = DateTime.now();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _appointmentsFuture = _apiService.getAllAppointments();
    });
  }

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
            content: Text(isAccept ? "Appointment Accepted!" : "Appointment Cancelled!"),
            backgroundColor: isAccept ? Colors.green : Colors.red,
          ),
        );
        _loadData(); 
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildAppointmentItem(AppointmentModel app) {
    final bool isFinalized = app.status.toLowerCase() == "completed" || 
                           app.status.toLowerCase() == "cancelled" || 
                           app.status.toLowerCase() == "confirmed";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.patientName.isNotEmpty ? app.patientName : "Patient: ${app.patientId.substring(0, 8)}...",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Doctor: ${app.doctorName}",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      app.startTime,
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.status,
                    style: TextStyle(
                      fontSize: 11, 
                      color: _getStatusColor(app.status),
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isFinalized) ...[
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, false),
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
                    onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text("Accept"),
                  ),
                ),
              ],
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    String selectedDateYMD = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String selectedDateDMY = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        title: "Today's Appointments",
        subtitle: DateFormat('EEEE, d MMMM').format(_selectedDate),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
        ],
        onRefresh: _loadData,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<AppointmentModel>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final allAppointments = snapshot.data ?? [];
              final displayAppointments = allAppointments.where((app) {
                return app.appointmentDate.contains(selectedDateYMD) || 
                       app.appointmentDate.contains(selectedDateDMY);
              }).toList();

              displayAppointments.sort((a, b) => a.startTime.compareTo(b.startTime));

              if (displayAppointments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 15),
                      Text("No appointments for this day.", 
                        style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: displayAppointments.length,
                itemBuilder: (context, index) => _buildAppointmentItem(displayAppointments[index]),
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }
}
