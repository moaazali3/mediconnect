import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/patient/screens/edit_patient_profile.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/patient/screens/patient_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool readOnly; 

  const ProfileScreen({super.key, this.userId, this.readOnly = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<PatientProfileModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final String targetId = (widget.userId == null || widget.userId!.isEmpty) ? "1" : widget.userId!;
    _profileFuture = _apiService.getPatientProfile(targetId);
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: widget.readOnly ? AppBar(
        title: const Text("Patient Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ) : null,
      body: FutureBuilder<PatientProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Error: ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() => _loadProfile()),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: const Text("Try Again", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No Profile Data Found"));
          }

          final profile = snapshot.data!;
          final String targetId = widget.userId ?? "1"; 

          return Column(
            children: [
              if (!widget.readOnly) _buildFixedHeader(profile),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.readOnly) _buildReadOnlySimpleHeader(profile),
                      
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
                        _buildInfoRow(Icons.cake_rounded, "Age", "${_calculateAge(profile.dateOfBirth)} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.height_rounded, "Height", "${profile.height} cm"),
                        _buildDivider(),
                        _buildInfoRow(Icons.monitor_weight_outlined, "Weight", "${profile.weight} kg"),
                        _buildDivider(),
                        _buildInfoRow(Icons.contact_emergency_rounded, "Emergency Contact", profile.emergencyContact),
                      ]),
                      
                      const SizedBox(height: 40),
                      if (!widget.readOnly) _buildActionButtons(context, targetId),
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

  Widget _buildReadOnlySimpleHeader(PatientProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(
              profile.gender == "Male" ? Icons.face_rounded : Icons.face_3_rounded, 
              size: 45, 
              color: primaryColor
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${profile.firstName} ${profile.lastName}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  profile.gender,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader(PatientProfileModel profile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 25, left: 20, right: 20),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  profile.gender == "Male" ? Icons.face_rounded : Icons.face_3_rounded, 
                  size: 50, 
                  color: primaryColor
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${profile.firstName} ${profile.lastName}",
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const Text(
                    "Patient Account",
                    style: TextStyle(
                      fontSize: 14, 
                      color: Colors.white70, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                _loadProfile();
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
