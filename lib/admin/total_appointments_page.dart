import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';

class TotalAppointmentsPage extends StatefulWidget {
  const TotalAppointmentsPage({super.key});

  @override
  State<TotalAppointmentsPage> createState() => _TotalAppointmentsPageState();
}

class _TotalAppointmentsPageState extends State<TotalAppointmentsPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      // جلب الإحصائيات والقائمة معاً للتأكد من مطابقة الأرقام
      _dataFuture = Future.wait([
        _apiService.getAdminDashboardStats(),
        _apiService.getAllAppointments(), 
      ]).then((results) => {
        'stats': results[0] as AdminDashboardModel,
        'list': results[1] as List<AppointmentModel>,
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      child: Row(
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
                  app.patientName.isNotEmpty ? app.patientName : "Patient: ${app.patientId.length > 8 ? app.patientId.substring(0, 8) : app.patientId}...",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  "Doctor: ${app.doctorName}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  "Date: ${app.appointmentDate}",
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                  fontSize: 10, 
                  color: _getStatusColor(app.status),
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        title: "Total Appointments",
        subtitle: _selectedDate == null ? "All Time Records" : DateFormat('EEEE, d MMMM').format(_selectedDate!),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
        onRefresh: _loadData,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
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
                  ElevatedButton(onPressed: _loadData, child: const Text("Retry")),
                ],
              ),
            );
          }

          final stats = snapshot.data!['stats'] as AdminDashboardModel;
          final allAppointments = snapshot.data!['list'] as List<AppointmentModel>;

          List<AppointmentModel> appointments = allAppointments;
          if (_selectedDate != null) {
            final String ymd = DateFormat('yyyy-MM-dd').format(_selectedDate!);
            final String dmy = DateFormat('dd/MM/yyyy').format(_selectedDate!);
            appointments = allAppointments.where((app) {
              return app.appointmentDate.contains(ymd) || app.appointmentDate.contains(dmy);
            }).toList();
          }

          return Column(
            children: [
              // كارت ملخص إجمالي المواعيد في النظام
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, Color(0xFF475AD1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Text(_selectedDate == null ? "Total System Appointments" : "Appointments for Selected Day", 
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedDate == null ? stats.totalAppointments.toString() : appointments.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 15),
                            Text(
                              _selectedDate == null ? "No appointments found" : "No appointments for this day", 
                              style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) => _buildAppointmentItem(appointments[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
