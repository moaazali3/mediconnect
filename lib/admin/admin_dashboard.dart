import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mediconnect/admin/add_doctor_page.dart';
import 'package:mediconnect/admin/manage_bookings_page.dart';
import 'package:mediconnect/constants/colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.8),
                  Colors.white,
                ],
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.05)),
          
          SafeArea(
            child: Center( // Center everything for larger screens
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Limit width on tablets/desktop
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Welcome Text or Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: primaryColor,
                              child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 35),
                            ),
                            SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome,", style: TextStyle(fontSize: 16, color: Colors.black54)),
                                Text("System Admin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Grid of Management Cards - Responsive Column Count
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Change column count based on width
                            int crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
                            if (constraints.maxWidth > 900) crossAxisCount = 4;
                            
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              children: [
                                _buildAdminCard(
                                  context,
                                  title: "Add Doctor",
                                  icon: Icons.person_add_rounded,
                                  color: Colors.blue.shade700,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDoctorPage())),
                                ),
                                _buildAdminCard(
                                  context,
                                  title: "Manage Bookings",
                                  icon: Icons.calendar_month_rounded,
                                  color: Colors.green.shade700,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageBookingsPage())),
                                ),
                                _buildAdminCard(
                                  context,
                                  title: "Specializations",
                                  icon: Icons.category_rounded,
                                  color: Colors.orange.shade700,
                                  onTap: () {
                                    // TODO: Implement specializations management
                                  },
                                ),
                                _buildAdminCard(
                                  context,
                                  title: "Analytics",
                                  icon: Icons.analytics_rounded,
                                  color: Colors.purple.shade700,
                                  onTap: () {
                                    // TODO: Implement analytics
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
