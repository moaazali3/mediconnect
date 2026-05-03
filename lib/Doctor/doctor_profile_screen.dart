import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/Doctor/edit_doctor_profile.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  DoctorModel? _doctor;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await _apiService.getAllDoctors();
      setState(() {
        _doctor = doctors.firstWhere((d) => d.id == widget.doctorId);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  int _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
      return age;
    } catch (_) { return 0; }
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
          final String? displayImage = doctor.profilePictureUrl;

          return Column(
            children: [
              _buildFixedHeader(doctor, displayImage),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Professional Details"),
                      _buildInfoCard([
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
                      _buildInfoCard([
                        _buildInfoRow(Icons.email_outlined, "Email", doctor.email),
                        _buildDivider(),
                        _buildInfoRow(Icons.phone_android_rounded, "Phone Number", doctor.phoneNumber),
                        _buildDivider(),
                        _buildInfoRow(Icons.calendar_month_rounded, "Age", "${_calculateAge(doctor.dateOfBirth)} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.location_on_outlined, "Clinic Address", doctor.address ?? "No Address"),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Work Schedule"),
                      _buildScheduleCard(_doctor?.doctorSchedules ?? []),

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

  Widget _buildFixedHeader(DoctorProfileModel doctor, String? displayImage) {
    const String imageBaseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";
    
    Widget imageWidget;
    if (displayImage != null && displayImage.isNotEmpty) {
      final String fullImageUrl = displayImage.startsWith('http') ? displayImage : "$imageBaseUrl$displayImage";
      imageWidget = CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(fullImageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint("Error loading image: $exception");
        },
      );
    } else {
      imageWidget = CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        child: Text(
          doctor.firstName.isNotEmpty ? doctor.firstName[0].toUpperCase() : "D",
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: primaryColor),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primaryColor, Color(0xFF00397F)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 25, left: 20, right: 20),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: imageWidget,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Dr. ${doctor.firstName} ${doctor.lastName}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  Text(
                    doctor.specializationName,
                    style: const TextStyle(
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

  Widget _buildScheduleCard(List<DoctorScheduleModel> schedules) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: schedules.isEmpty
        ? const ListTile(title: Text("No work hours set", style: TextStyle(color: Colors.grey)))
        : Column(children: schedules.map((s) => ListTile(
            leading: const Icon(Icons.calendar_today_outlined, size: 18, color: primaryColor),
            title: Text(s.getDayName(), style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text("${s.startTime} - ${s.endTime}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          )).toList()),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 5, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _buildInfoCard(List<Widget> children) => Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]), child: Column(children: children));

  Widget _buildInfoRow(IconData icon, String label, String value) => ListTile(leading: Icon(icon, color: primaryColor, size: 20), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _buildDivider() => Divider(height: 1, indent: 50, endIndent: 20, color: Colors.grey.shade100);
}
