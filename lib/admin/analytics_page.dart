import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/admin/today_appointments_page.dart';
import 'package:mediconnect/admin/today_doctors_page.dart';
import 'package:mediconnect/admin/today_revenue_page.dart';
import 'package:mediconnect/admin/total_doctors_page.dart';
import 'package:mediconnect/admin/total_appointments_page.dart';
import 'package:mediconnect/admin/total_revenue_page.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  AdminDashboardModel? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getAdminDashboardStats(),
        _apiService.getAllDoctors(),
        _apiService.getAllAppointments(),
      ]);

      var stats = results[0] as AdminDashboardModel;
      final allDoctors = results[1] as List;
      final allAppointments = results[2] as List<AppointmentModel>;

      final DateTime now = DateTime.now();
      final String todayYMD = DateFormat('yyyy-MM-dd').format(now);
      final String todayDMY = DateFormat('dd/MM/yyyy').format(now);

      final todayAppts = allAppointments.where((app) {
        String date = app.appointmentDate;
        return date.contains(todayYMD) || date.contains(todayDMY);
      }).toList();

      final int currentWeekday = DateTime.now().weekday;
      int activeDoctorsCount = 0;

      for (var doctor in allDoctors) {
        try {
          final schedules = await _apiService.getDoctorSchedule(doctor.id);
          bool isAvailableToday = schedules.any((schedule) {
            return schedule.isScheduledFor(currentWeekday) && schedule.isAvailable;
          });
          if (isAvailableToday) activeDoctorsCount++;
        } catch (e) {
          debugPrint("Error checking schedule: $e");
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats.copyWith(
            totalDoctorsToday: activeDoctorsCount,
            totalAppointmentsToday: todayAppts.length,
            totalCompletedAppointmentsToday: todayAppts.where((a) => a.status.toLowerCase() == 'completed').length,
            totalPendingAppointmentsToday: todayAppts.where((a) => a.status.toLowerCase() == 'pending' || a.status.toLowerCase() == 'confirmed').length,
            totalCancelledAppointmentsToday: todayAppts.where((a) => a.status.toLowerCase() == 'cancelled').length,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Overview"),
                      const SizedBox(height: 15),
                      if (_stats != null) _buildStatsGrid(_stats!),
                      const SizedBox(height: 15),
                      if (_stats != null) _buildTodayBreakdown(_stats!),
                      const SizedBox(height: 30),
                      _buildSectionHeader("Overall Breakdown"),
                      const SizedBox(height: 15),
                      if (_stats != null) _buildOverallBreakdown(_stats!),
                      const SizedBox(height: 30),
                      _buildSectionHeader("System Summary"),
                      const SizedBox(height: 15),
                      if (_stats != null) _buildQuickStats(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }

  Widget _buildStatsGrid(AdminDashboardModel stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Today Appts", 
                stats.totalAppointmentsToday.toString(), 
                Icons.calendar_today_rounded, 
                Colors.pink,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayAppointmentsPage())),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                "Active Doctors", 
                stats.totalDoctorsToday.toString(), 
                Icons.person_search_rounded, 
                Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayDoctorsPage())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatCard(
          "Today Revenue", 
          "${stats.totalRevenueToday.toStringAsFixed(0)} EGP", 
          Icons.payments_rounded, 
          Colors.green, 
          isFullWidth: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayRevenuePage())),
        ),
        const SizedBox(height: 15),
        _buildStatCard(
          "Total Appts", 
          stats.totalAppointments.toString(), 
          Icons.history_rounded, 
          Colors.indigo, 
          isFullWidth: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalAppointmentsPage())),
        ),
      ],
    );
  }

  Widget _buildTodayBreakdown(AdminDashboardModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                "Today's Appointments Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem("Completed", stats.totalCompletedAppointmentsToday, Colors.green),
              _buildStatusDivider(),
              _buildStatusItem("Pending", stats.totalPendingAppointmentsToday, Colors.orange),
              _buildStatusDivider(),
              _buildStatusItem("Cancelled", stats.totalCancelledAppointmentsToday, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallBreakdown(AdminDashboardModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                "Overall Appointments Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem("Completed", stats.totalCompletedAppointments, Colors.green),
              _buildStatusDivider(),
              _buildStatusItem("Pending", stats.totalPendingAppointments, Colors.orange),
              _buildStatusDivider(),
              _buildStatusItem("Cancelled", stats.totalCancelledAppointments, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildSmallStat("Total Patients", _stats!.totalPatients.toString(), Colors.blue),
        _buildSmallStat(
          "Total Doctors",
          _stats!.totalDoctors.toString(), 
          Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalDoctorsPage())),
        ),
        _buildSmallStat(
          "Total Appts", 
          _stats!.totalAppointments.toString(), 
          Colors.indigo,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalAppointmentsPage())),
        ),
        _buildSmallStat(
          "Total Revenue", 
          "${_stats!.totalRevenue.toStringAsFixed(0)} EGP", 
          Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalRevenuePage())),
        ),
        _buildSmallStat("Success Rate", "${(_stats!.totalCompletedAppointments / (_stats!.totalAppointments > 0 ? _stats!.totalAppointments : 1) * 100).toStringAsFixed(0)}%", Colors.green),
        _buildSmallStat("Cancellation", "${(_stats!.totalCancelledAppointments / (_stats!.totalAppointments > 0 ? _stats!.totalAppointments : 1) * 100).toStringAsFixed(0)}%", Colors.red),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12))),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
