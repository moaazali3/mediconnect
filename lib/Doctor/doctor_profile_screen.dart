import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/LoginScreen.dart';
import 'package:mediconnect/edit_doctor_profile.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();

  int _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: FutureBuilder<DoctorProfileModel>(
        future: _apiService.getDoctorProfile(widget.doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No Data Found"));
          }

          final doctor = snapshot.data!;
          const String dummyImageUrl = "https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg";

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [primaryColor, Color(0xFF00397F)],
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 50),
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white24,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(dummyImageUrl),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Dr. ${doctor.firstName} ${doctor.lastName}",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      Center(
                        child: Text(
                          doctor.specializationName,
                          style: const TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle("Professional Details"),
                      _buildProfileCard([
                        _buildInfoRow(Icons.badge_rounded, "Specialization", doctor.specializationName),
                        _buildDivider(),
                        _buildInfoRow(Icons.work_history_rounded, "Experience", "${doctor.experienceYears} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.payments_rounded, "Consultation Fee", "${doctor.consultationFee} EGP"),
                        _buildDivider(),
                        _buildInfoRow(Icons.description_rounded, "Biography", doctor.biography),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Personal Information"),
                      _buildProfileCard([
                        _buildInfoRow(Icons.email_rounded, "Email", doctor.email),
                        _buildDivider(),
                        _buildInfoRow(Icons.phone_rounded, "Phone Number", doctor.phoneNumber),
                        _buildDivider(),
                        _buildInfoRow(Icons.calendar_month_rounded, "Age", "${_calculateAge(doctor.dateOfBirth)} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.location_on_rounded, "Clinic Address", doctor.address ?? "No Address"),
                      ]),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditDoctorProfile(doctorId: widget.doctorId)),
                            );
                            if (result == true) {
                              setState(() {}); // Refresh data
                            }
                          },
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text("Update Profile Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                            );
                          },
                          icon: const Icon(Icons.power_settings_new_rounded),
                          label: const Text("Sign Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.shade100);
  }
}
