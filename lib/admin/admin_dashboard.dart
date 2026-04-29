import 'package:flutter/material.dart';
import 'package:mediconnect/admin/add_doctor_page.dart';
import 'package:mediconnect/admin/manage_bookings_page.dart';
import 'package:mediconnect/admin/manage_specializations_page.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  late Future<AdminDashboardModel> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _apiService.getAdminDashboardStats();
  }

  Future<void> _refreshData() async {
    setState(() {
      _statsFuture = _apiService.getAdminDashboardStats();
    });
  }

  void _signOut() {
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
      appBar: AppBar(
        title: const Text(
          "Admin Portal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Gradient Section
              _buildHeader(),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("System Statistics"),
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
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, Administrator",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Monitor and manage your hospital operations efficiently.",
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
              child: _buildStatCard(
                "Total Patients",
                stats.totalPatients.toString(),
                Icons.people_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                "Active Doctors",
                stats.totalDoctors.toString(),
                Icons.medical_services_rounded,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Appointments",
                stats.totalAppointments.toString(),
                Icons.event_note_rounded,
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                "Revenue",
                "${stats.totalRevenue.toStringAsFixed(0)} EGP",
                Icons.payments_rounded,
                Colors.orange.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Booking breakdown card
        Container(
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
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 20, color: Colors.grey),
                  SizedBox(width: 10),
                  Text("Appointment Breakdown", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusInfo("Completed", stats.totalCompletedAppointments, Colors.green),
                  _buildStatusInfo("Pending", stats.totalPendingAppointments, Colors.orange),
                  _buildStatusInfo("Cancelled", stats.totalCancelledAppointments, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
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
          "Register new staff",
          Icons.person_add_alt_1_rounded,
          Colors.blue.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDoctorPage())).then((_) => _refreshData()),
        ),
        _buildActionCard(
          context,
          "Bookings",
          "View schedules",
          Icons.calendar_today_rounded,
          Colors.green.shade600,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageBookingsPage())).then((_) => _refreshData()),
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
          "Full reports",
          Icons.bar_chart_rounded,
          Colors.purple.shade600,
          () {},
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
