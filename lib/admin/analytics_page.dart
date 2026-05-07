import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/admin/today_appointments_page.dart';
import 'package:mediconnect/admin/today_doctors_page.dart';
import 'package:mediconnect/admin/today_revenue_page.dart';
import 'package:mediconnect/admin/total_doctors_page.dart';
import 'package:mediconnect/admin/total_appointments_page.dart';
import 'package:mediconnect/admin/total_revenue_page.dart';
import 'package:mediconnect/admin/total_patients_page.dart';

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
  int _uniquePatientsCount = 0;
  String? _topDoctorName;
  String? _topDoctorSpecialization;
  String? _topDoctorImageUrl;
  int _topDoctorBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getAdminDashboardStats(),
        _apiService.getTodayAppointments(),
        _apiService.getDoctorsWorkingToday(),
        _apiService.getAllPatients(),
        _apiService.getAllAppointments(pageSize: 2000),
        _apiService.getAllDoctors(pageSize: 1000),
      ]);

      final stats = results[0] as AdminDashboardModel;
      final todayAppts = results[1] as List<AppointmentModel>;
      final activeDoctors = results[2] as List;
      final allPatients = results[3] as List;
      final allAppts = results[4] as List<AppointmentModel>;
      final allDoctors = results[5] as List<DoctorModel>;

      // Count unique patients
      final Set<String> uniqueNames = {};
      for (var p in allPatients) {
        uniqueNames.add("${p.firstName} ${p.lastName}".toLowerCase().trim());
      }

      // Calculate most booked doctor
      String? topDocId;
      int maxBookings = 0;
      String? topDocName;
      String? topDocSpec;
      String? topDocImage;
      
      if (allAppts.isNotEmpty) {
        Map<String, int> doctorBookingsCount = {};
        Map<String, String> doctorNamesMap = {};
        
        for (var appt in allAppts) {
          // Use doctorId if available, fallback to doctorName to ensure we count something
          final id = appt.doctorId.trim().isNotEmpty ? appt.doctorId.trim() : appt.doctorName.trim();
          if (id.isNotEmpty) {
            doctorBookingsCount[id] = (doctorBookingsCount[id] ?? 0) + 1;
            if (appt.doctorName.isNotEmpty) {
              doctorNamesMap[id] = appt.doctorName;
            }
          }
        }
        
        if (doctorBookingsCount.isNotEmpty) {
          var sorted = doctorBookingsCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          topDocId = sorted.first.key;
          maxBookings = sorted.first.value;
          topDocName = doctorNamesMap[topDocId] ?? topDocId;

          // Try to find more details from allDoctors list
          try {
            final doctor = allDoctors.firstWhere((d) => 
              d.id.trim() == topDocId || 
              "${d.firstName} ${d.lastName}".trim().toLowerCase() == topDocName?.toLowerCase()
            );
            topDocName = "${doctor.firstName} ${doctor.lastName}";
            topDocSpec = doctor.specializationName;
            topDocImage = doctor.profilePictureUrl;
          } catch (_) {
            // If not found in allDoctors, keep what we have from appointments
          }
        }
      }

      if (mounted) {
        setState(() {
          _uniquePatientsCount = uniqueNames.length;
          _topDoctorName = topDocName;
          _topDoctorSpecialization = topDocSpec;
          _topDoctorImageUrl = topDocImage;
          _topDoctorBookings = maxBookings;
          _stats = stats.copyWith(
            totalDoctorsToday: activeDoctors.length,
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
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text("Retry", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Overview Today"),
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
                      _buildTopDoctorCard(),
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

  Widget _buildTopDoctorCard() {
    if (_topDoctorName == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF475AD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: _topDoctorImageUrl != null && _topDoctorImageUrl!.isNotEmpty
                  ? Image.network(
                      _topDoctorImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 35),
                    )
                  : const Icon(Icons.star_rounded, color: Colors.white, size: 35),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Most Booked Doctor",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _topDoctorName!,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_topDoctorSpecialization != null && _topDoctorSpecialization!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _topDoctorSpecialization!,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _topDoctorBookings.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Bookings",
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        _buildSmallStat(
          "Total Patients", 
          _uniquePatientsCount.toString(), 
          Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalPatientsPage())),
        ),
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
