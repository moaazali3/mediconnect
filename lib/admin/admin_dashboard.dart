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
import 'package:mediconnect/services/secure_storage.dart';
import 'package:mediconnect/services/api_service.dart';
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
    await SecureStorage.deleteAllData();
    ApiService.setToken(null);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        pageName: pageTitle,
        userName: _adminName,
        onLogout: _signOut,
        onRefresh: _handleRefresh,
        isRoot: true,
        showDarkModeToggle: _currentIndex == 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _currentIndex == 0
            ? AnalyticsPage(key: _analyticsKey, adminName: _adminName)
            : _buildConsoleContent(key: const ValueKey("console")),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: primaryColor,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).cardColor,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_rounded),
                activeIcon: Icon(Icons.analytics_rounded, size: 30),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_customize_rounded),
                activeIcon: Icon(Icons.dashboard_customize_rounded, size: 30),
                label: 'Console',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleContent({Key? key}) {
    return SingleChildScrollView(
      key: key,
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
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
        primaryColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
