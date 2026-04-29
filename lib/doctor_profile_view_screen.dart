import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DoctorProfileModel>(
      future: _apiService.getDoctorProfile(widget.doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFF),
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFF),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFF),
            body: Center(child: Text("No Data Found")),
          );
        }

        final doctor = snapshot.data!;
        const String dummyImageUrl = "https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg";
        final int age = _calculateAge(doctor.dateOfBirth);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
          appBar: AppBar(
            backgroundColor: primaryColor,
            elevation: 0,
            toolbarHeight: 60,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Doctor Profile",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: _buildBottomAction(doctor.phoneNumber),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityCard(doctor, dummyImageUrl),
                const SizedBox(height: 25),
                _buildStatsRow(doctor, age),
                const SizedBox(height: 30),
                _buildSectionTitle("Professional Biography"),
                _buildInfoCard(doctor.biography),
                const SizedBox(height: 25),
                _buildSectionTitle("Professional Details"),
                _buildProfileCard([
                  _buildInfoRow(Icons.payments_rounded, "Consultation Fee", "${doctor.consultationFee} EGP"),
                  _buildDivider(),
                  _buildInfoRow(Icons.phone_rounded, "Phone Number", doctor.phoneNumber),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityCard(DoctorProfileModel doctor, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. ${doctor.firstName} ${doctor.lastName}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specializationName,
                  style: TextStyle(fontSize: 15, color: primaryColor.withOpacity(0.8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DoctorProfileModel doctor, int age) {
    return Row(
      children: [
        _buildStatItem("Experience", "${doctor.experienceYears} Yrs", Icons.work_history_rounded, Colors.blue),
        _buildStatItem("Gender", doctor.gender, Icons.wc_rounded, Colors.green),
        _buildStatItem("Age", age > 0 ? "$age Yrs" : "N/A", Icons.calendar_month_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 14),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.shade100);
  }

  Widget _buildBottomAction(String phoneNumber) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () => _makePhoneCall(phoneNumber),
            icon: const Icon(Icons.phone_in_talk_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            label: const Text(
              "CALL DOCTOR NOW",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }
}
