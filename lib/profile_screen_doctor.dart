import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/LoginScreen.dart';
import 'package:mediconnect/edit_doctor_profile.dart'; // إضافة الاستيراد

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  // بيانات الدكتور القابلة للتحديث
  String name = "Dr. Adam Doma";
  String spec = "Senior Dentist - BDS, MDS";
  String experience = "10 Years";
  String fee = "1000 EGP";
  String bio = "Professional dentist with extensive experience in oral surgery and cosmetic dentistry.";
  String email = "adam.doctor@mediconnect.com";
  String phone = "01234567890";
  String age = "35 Years";
  String address = "Cairo, Egypt";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(height: 50),
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white24,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.medical_services_rounded, size: 55, color: primaryColor),
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
                      name,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  Center(
                    child: Text(
                      spec,
                      style: const TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildSectionTitle("Professional Details"),
                  _buildProfileCard([
                    _buildInfoRow(Icons.badge_rounded, "Specialization", spec),
                    _buildDivider(),
                    _buildInfoRow(Icons.work_history_rounded, "Experience", experience),
                    _buildDivider(),
                    _buildInfoRow(Icons.payments_rounded, "Consultation Fee", fee),
                    _buildDivider(),
                    _buildInfoRow(Icons.description_rounded, "Biography", bio),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("Personal Information"),
                  _buildProfileCard([
                    _buildInfoRow(Icons.email_rounded, "Email", email),
                    _buildDivider(),
                    _buildInfoRow(Icons.phone_rounded, "Phone Number", phone),
                    _buildDivider(),
                    _buildInfoRow(Icons.cake_rounded, "Age", age),
                    _buildDivider(),
                    _buildInfoRow(Icons.location_on_rounded, "Clinic Address", address),
                  ]),

                  const SizedBox(height: 40),

                  // زر التحديث المفعّل
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditDoctorProfile()),
                        );

                        if (result != null && result is Map<String, String>) {
                          setState(() {
                            name = "Dr. ${result['fName']} ${result['lName']}";
                            spec = result['spec']!;
                            experience = "${result['exp']} Years";
                            fee = "${result['fee']} EGP";
                            bio = result['bio']!;
                            phone = result['phone']!;
                            age = "${result['age']} Years";
                            address = result['address']!;
                          });
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
