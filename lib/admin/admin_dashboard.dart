import 'package:flutter/material.dart';
import 'package:mediconnect/admin/add_doctor_page.dart';
import 'package:mediconnect/admin/add_receptionist_page.dart';
import 'package:mediconnect/admin/manage_specializations_page.dart';
import 'package:mediconnect/admin/manage_doctors_page.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/admin/analytics_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  String _adminName = "Administrator";

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('user_name') ?? "Administrator";
    });
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = _currentIndex == 0 ? "Admin Console" : "Advanced Analytics";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        pageName: pageTitle,
        userName: _adminName,
        onLogout: _signOut,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildConsoleContent(),
          const AnalyticsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_customize_rounded),
              label: 'Console',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleContent() {
    return SingleChildScrollView(
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
                _buildSectionTitle("Management Console"),
                const SizedBox(height: 15),
                _buildManagementGrid(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
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
            "Welcome, $_adminName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Manage your clinic operations efficiently.",
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

  Widget _buildManagementGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final childRatio = screenWidth < 360 ? 0.75 : (screenWidth < 400 ? 0.85 : 1.0);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: childRatio,
      children: [
        _buildActionCard(
          context,
          "Add Doctor",
          "Register staff",
          Icons.person_add_alt_1_rounded,
          Colors.blue.shade600,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDoctorPage())),
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
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDoctorsPage())),
        ),
        _buildActionCard(
          context,
          "Specialties",
          "Manage list",
          Icons.category_rounded,
          Colors.amber.shade700,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSpecializationsPage())),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
