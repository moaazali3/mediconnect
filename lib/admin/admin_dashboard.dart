import 'package:flutter/material.dart';
import 'package:mediconnect/admin/add_doctor_page.dart';
import 'package:mediconnect/admin/manage_bookings_page.dart';
import 'package:mediconnect/constants/colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildAdminCard(
            context,
            title: "Add Doctor",
            icon: Icons.person_add_rounded,
            color: Colors.blue.shade700,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDoctorPage()));
            },
          ),
          _buildAdminCard(
            context,
            title: "Manage Bookings",
            icon: Icons.calendar_month_rounded,
            color: Colors.green.shade700,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageBookingsPage()));
            },
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
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
