import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';

class DoctorProfileViewScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileViewScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileViewScreen> createState() => _DoctorProfileViewScreenState();
}

class _DoctorProfileViewScreenState extends State<DoctorProfileViewScreen> {
  final ApiService _apiService = ApiService();

  int _calculateAge(String dobString) {
    try {
      DateTime dob = DateTime.parse(dobString);
      DateTime today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
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
          final int age = _calculateAge(doctor.dateOfBirth);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
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
                      const SizedBox(height: 30),

                      _buildSectionTitle("About Doctor"),
                      _buildProfileCard([
                        _buildInfoRow(Icons.badge_rounded, "Specialization", doctor.specializationName),
                        _buildDivider(),
                        _buildInfoRow(Icons.cake_rounded, "Age", age > 0 ? "$age Years" : "N/A"),
                        _buildDivider(),
                        _buildInfoRow(Icons.work_history_rounded, "Experience", "${doctor.experienceYears} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.payments_rounded, "Consultation Fee", "${doctor.consultationFee} EGP"),
                        _buildDivider(),
                        _buildInfoRow(Icons.description_rounded, "Biography", doctor.biography),
                      ]),

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
            color: Colors.black.withOpacity(0.04),
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
              color: primaryColor.withOpacity(0.08),
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
