import 'package:flutter/material.dart';
import 'package:mediconnect/admin/add_doctor_page.dart';
import 'package:mediconnect/admin/add_receptionist_page.dart';
import 'package:mediconnect/admin/manage_specializations_page.dart';
import 'package:mediconnect/admin/manage_doctors_page.dart';
import 'package:mediconnect/admin/manage_receptionists_page.dart';
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
  int _currentIndex = 1;
  String _adminName = "Administrator";

  Key _analyticsKey = UniqueKey();

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

  void _handleRefresh() {
    _loadAdminInfo();
    setState(() {
      _analyticsKey = UniqueKey();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Dashboard Refreshed"),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = _currentIndex == 1 ? "Admin Console" : "Advanced Analytics";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        pageName: pageTitle,
        userName: _adminName,
        onLogout: _signOut,
        onRefresh: _handleRefresh,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AnalyticsPage(key: _analyticsKey, adminName: _adminName),
          _buildConsoleContent(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_customize_rounded),
              label: 'Console',
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
    final List<Widget> items = [
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
        "Receptionists",
        "Manage staff",
        Icons.badge_rounded,
        Colors.orange.shade600,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageReceptionistsPage())),
      ),
      _buildActionCard(
        context,
        "Specialties",
        "Manage list",
        Icons.category_rounded,
        Colors.amber.shade700,
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSpecializationsPage())),
      ),
    ];

    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      if (i + 1 < items.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: items[i]),
              const SizedBox(width: 15),
              Expanded(child: items[i + 1]),
            ],
          ),
        );
      } else {
        // إذا كان العنصر وحيداً، نجعله يأخذ العرض الكامل
        rows.add(
          SizedBox(
            width: double.infinity,
            child: items[i],
          ),
        );
      }
      rows.add(const SizedBox(height: 15));
    }

    return Column(children: rows);
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
