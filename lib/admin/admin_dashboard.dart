import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/admin/add_doctor_page.dart';
import 'package:mediconnect/admin/add_receptionist_page.dart'; // استيراد صفحة الإضافة الجديدة
import 'package:mediconnect/admin/manage_bookings_page.dart';
import 'package:mediconnect/admin/manage_specializations_page.dart';
import 'package:mediconnect/admin/manage_doctors_page.dart';
import 'package:mediconnect/admin/today_appointments_page.dart';
import 'package:mediconnect/admin/today_doctors_page.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/admin/qr_scanner_page.dart';
import 'package:mediconnect/admin/analytics_page.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  late Future<AdminDashboardModel> _statsFuture;
  String _adminName = "Administrator";
  int _calculatedDoctorsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadAdminInfo();
  }

  void _loadDashboardData() {
    _statsFuture = _getCombinedStats();
  }

  Future<AdminDashboardModel> _getCombinedStats() async {
    try {
      final stats = await _apiService.getAdminDashboardStats();
      final allDoctors = await _apiService.getAllDoctors();
      final int currentWeekday = DateTime.now().weekday;
      int count = 0;
      for (var doctor in allDoctors) {
        bool isAvailableToday = doctor.doctorSchedules.any((schedule) {
          return schedule.isScheduledFor(currentWeekday) && schedule.isAvailable;
        });
        if (isAvailableToday) count++;
      }
      if (mounted) {
        setState(() {
          _calculatedDoctorsToday = count;
        });
      }
      return stats.copyWith(totalDoctorsToday: count);
    } catch (e) {
      debugPrint("Error loading admin stats: $e");
      return AdminDashboardModel(
        totalAppointmentsToday: 0,
        totalDoctorsToday: 0,
        totalRevenueToday: 0,
        totalPendingAppointmentsToday: 0,
        totalCompletedAppointmentsToday: 0,
        totalCancelledAppointmentsToday: 0,
        totalAppointments: 0,
        totalDoctors: 0,
        totalCancelledAppointments: 0,
        totalCompletedAppointments: 0,
        totalPatients: 0,
        totalPendingAppointments: 0,
        totalRevenue: 0,
      );
    }
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('user_name') ?? "Administrator";
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadDashboardData();
    });
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        pageName: "Admin Portal",
        userName: _adminName,
        onRefresh: _refreshData,
        onLogout: _signOut,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Today's Overview"),
                    const SizedBox(height: 15),
                    FutureBuilder<AdminDashboardModel>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30.0),
                              child: CircularProgressIndicator(color: primaryColor),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return _buildErrorCard(snapshot.error.toString());
                        } else if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return _buildStatsGrid(snapshot.data!);
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Management Console"),
                    const SizedBox(height: 15),
                    _buildManagementGrid(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 45),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back, $_adminName",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Everything is running smoothly today.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardModel stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TodayAppointmentsPage()),
                  );
                },
                child: _buildStatCard(
                  "Today's Appts",
                  stats.totalAppointmentsToday.toString(),
                  Icons.today_rounded,
                  Colors.pink,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TodayDoctorsPage()),
                  );
                },
                child: _buildStatCard(
                  "Doctors Today",
                  stats.totalDoctorsToday.toString(),
                  Icons.person_search_rounded,
                  Colors.blue,
                ),
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
        ),
        const SizedBox(height: 15),
        _buildBreakdownCard(
          "Today's Appointment Status",
          stats.totalCompletedAppointmentsToday,
          stats.totalPendingAppointmentsToday,
          stats.totalCancelledAppointmentsToday,
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(String title, int completed, int pending, int cancelled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusInfo("Completed", completed, Colors.green),
              _buildStatusInfo("Pending", pending, Colors.orange),
              _buildStatusInfo("Cancelled", cancelled, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          context,
          "Add Doctor",
          "Register staff",
          Icons.person_add_alt_1_rounded,
          Colors.blue.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDoctorPage())).then((_) => _refreshData()),
        ),
        _buildActionCard(
          context,
          "Add Receptionist",
          "Support staff",
          Icons.person_add_alt_rounded,
          Colors.indigo.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddReceptionistPage())),
        ),
        _buildActionCard(
          context,
          "Doctors List",
          "Schedules & Fees",
          Icons.medical_services_rounded,
          Colors.teal.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDoctorsPage())).then((_) => _refreshData()),
        ),
        _buildActionCard(
          context,
          "Bookings",
          "View appointments",
          Icons.calendar_today_rounded,
          Colors.green.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageBookingsPage())).then((_) => _refreshData()),
        ),
        _buildActionCard(
          context,
          "Scan QR",
          "Confirm attendance",
          Icons.qr_code_scanner_rounded,
          Colors.orange.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerPage())),
        ),
        _buildActionCard(
          context,
          "Specialties",
          "Manage list",
          Icons.category_rounded,
          Colors.amber.shade700,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSpecializationsPage())),
        ),
        _buildActionCard(
          context,
          "Analytics",
          "Reports",
          Icons.bar_chart_rounded,
          Colors.purple.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage())),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 30),
          const SizedBox(height: 10),
          Text(
            "Could not load dashboard data",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}
