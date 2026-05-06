import 'package:flutter/material.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ماتنساش تتأكد إن مسار ملف التعديل ده صح عندك
import 'package:mediconnect/receptionist/edit_receptionist_profile.dart';

class ReceptionistProfilePage extends StatefulWidget {
  final String? userId;
  const ReceptionistProfilePage({super.key, this.userId});

  @override
  State<ReceptionistProfilePage> createState() => _ReceptionistProfilePageState();
}

class _ReceptionistProfilePageState extends State<ReceptionistProfilePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  ReceptionistProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  String _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return "N/A";
    try {
      DateTime dob = DateTime.parse(dobString);
      DateTime today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return "$age Years";
    } catch (e) {
      return "N/A";
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = widget.userId ?? prefs.getString('user_id') ?? "1";
      final profile = await _apiService.getReceptionistProfile(id);

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(backgroundColor: Color(0xFFF8FAFF), body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column( // شيلنا الـ SafeArea والـ ScrollView من هنا وبدأنا بـ Column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurvedHeader(), // الهيدر الأزرق بقى ثابت فوق بره السكرول

          Expanded( // باقي الصفحة جوه Expanded عشان تاخد المساحة اللي فاضلة وتسكرول براحتها
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildSectionTitle("Personal Information"),
                    _buildProfileCard([
                      _buildInfoRow(Icons.email_outlined, "Email", _profile?.email ?? "N/A"),
                      _buildDivider(),
                      _buildInfoRow(Icons.person_outline, "First Name", _profile?.firstName ?? "N/A"),
                      _buildDivider(),
                      _buildInfoRow(Icons.person_outline, "Last Name", _profile?.lastName ?? "N/A"),
                      _buildDivider(),
                      _buildInfoRow(Icons.cake_rounded, "Age", _calculateAge(_profile?.dateOfBirth)),
                    ]),

                    const SizedBox(height: 25),

                    _buildSectionTitle("Work Details"),
                    _buildProfileCard([
                      _buildInfoRow(Icons.phone_android_rounded, "Phone Number", _profile?.phoneNumber ?? "N/A"),
                      _buildDivider(),
                      _buildInfoRow(Icons.medical_services_outlined, "Assigned Doctor", _profile?.doctorName != null && _profile!.doctorName!.isNotEmpty ? "Dr. ${_profile!.doctorName}" : "Not Assigned"),
                    ]),

                    const SizedBox(height: 40),
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 25, left: 20, right: 20),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.face_3_rounded, size: 50, color: primaryColor),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Medical Receptionist",
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
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
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () async {
              // نفتح صفحة التعديل الجديدة، ولما نرجع نعمل Refresh
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditReceptionistProfile(userId: widget.userId)),
              );
              if (result == true) {
                _fetchProfile();
              }
            },
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            label: const Text("Update Profile Info", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
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
            onPressed: _signOut,
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
            label: const Text("Sign Out", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}