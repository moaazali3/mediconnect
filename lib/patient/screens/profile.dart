import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/edit_patient_profile.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/patient_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mediconnect/LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _launchWhatsApp() async {
    const String phoneNumber = "201000000000";
    const String message = "Hello MediConnect, I need help with my account.";
    final Uri whatsappUri = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String targetId = widget.userId ?? "1"; 

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: FutureBuilder<PatientProfileModel>(
        future: _apiService.getPatientProfile(targetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No Profile Data Found"));
          }

          final profile = snapshot.data!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(profile),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "${profile.firstName} ${profile.lastName}",
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Patient Account",
                          style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PatientHistoryScreen(userId: targetId)),
                            );
                          },
                          icon: const Icon(Icons.history_rounded, color: primaryColor),
                          label: const Text("View Medical History", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildSectionTitle("Personal Information"),
                      _buildProfileCard([
                        _buildInfoRow(Icons.email_outlined, "Email", profile.email),
                        _buildDivider(),
                        _buildInfoRow(Icons.phone_android_rounded, "Phone", profile.phoneNumber),
                        _buildDivider(),
                        _buildInfoRow(Icons.location_on_outlined, "Address", profile.address ?? "No Address"),
                      ]),
                      
                      const SizedBox(height: 25),
                      _buildSectionTitle("Medical Background"),
                      _buildProfileCard([
                        _buildInfoRow(Icons.bloodtype_outlined, "Blood Type", profile.bloodType),
                        _buildDivider(),
                        _buildInfoRow(Icons.calendar_month_rounded, "Age", "${_calculateAge(profile.dateOfBirth)} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.height_rounded, "Height", "${profile.height} cm"),
                        _buildDivider(),
                        _buildInfoRow(Icons.monitor_weight_outlined, "Weight", "${profile.weight} kg"),
                        _buildDivider(),
                        _buildInfoRow(Icons.contact_emergency_rounded, "Emergency Contact", profile.emergencyContact),
                      ]),
                      
                      const SizedBox(height: 40),
                      
                      _buildActionButtons(context, targetId),
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

  Widget _buildAppBar(PatientProfileModel profile) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, Color(0xFF1E88E5)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: Icon(
                      profile.gender == "Male" ? Icons.face_rounded : Icons.face_3_rounded, 
                      size: 60, 
                      color: primaryColor
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String targetId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditPatientProfile(userId: targetId,)),
              );
              if (result == true) {
                setState(() {});
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
        const SizedBox(height: 25),
        const Divider(),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _launchWhatsApp,
            icon: const Icon(Icons.chat_rounded, color: Colors.white),
            label: const Text("Contact Support (WhatsApp)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
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
