import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/Doctor/edit_doctor_profile.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/constants/api_constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();

  int _calculateAge(String dob) {
    if (dob.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
      return age;
    } catch (_) { return 0; }
  }

  // ميثود لجلب البروفايل والمواعيد معاً لضمان ظهور البيانات
  Future<Map<String, dynamic>> _fetchFullProfile() async {
    final results = await Future.wait([
      _apiService.getDoctorProfile(widget.doctorId),
      _apiService.getDoctorSchedule(widget.doctorId),
    ]);
    
    return {
      'profile': results[0] as DoctorProfileModel,
      'schedules': results[1] as List<DoctorScheduleModel>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchFullProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            final dummyDoctor = DoctorProfileModel(
              firstName: "Loading",
              lastName: "Name",
              specializationName: "Specialization",
              experienceYears: 5,
              biography: "Loading biography text goes here...",
              consultationFee: 100,
              dateOfBirth: "2000-01-01",
              gender: "Male",
              phoneNumber: "000000000",
              email: "loading@loading.com",
            );
            
            return Skeletonizer(
              enabled: true,
              child: Column(
                children: [
                  _buildFixedHeader(dummyDoctor, ""),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Professional Details"),
                          _buildInfoCard([
                            _buildInfoRow(Icons.badge_rounded, "Specialization", dummyDoctor.specializationName),
                            _buildDivider(),
                            _buildInfoRow(Icons.work_history_rounded, "Experience", "${dummyDoctor.experienceYears.toStringAsFixed(0)} Years"),
                            _buildDivider(),
                            _buildInfoRow(Icons.payments_rounded, "Consultation Fee", "${dummyDoctor.consultationFee.toStringAsFixed(0)} EGP"),
                            _buildDivider(),
                            _buildInfoRow(Icons.description_rounded, "Biography", dummyDoctor.biography.isNotEmpty ? dummyDoctor.biography : "No biography provided"),
                          ]),

                          const SizedBox(height: 25),
                          _buildSectionTitle("Personal Information"),
                          _buildInfoCard([
                            _buildInfoRow(Icons.email_outlined, "Email", dummyDoctor.email ?? ""),
                            _buildDivider(),
                            _buildInfoRow(Icons.phone_android_rounded, "Phone Number", dummyDoctor.phoneNumber),
                            _buildDivider(),
                            _buildInfoRow(Icons.calendar_month_rounded, "Age", "20 Years"),
                            _buildDivider(),
                            _buildInfoRow(Icons.location_on_outlined, "Clinic Address", dummyDoctor.address ?? "No Address"),
                          ]),

                          const SizedBox(height: 25),
                          _buildSectionTitle("Work Schedule"),
                          _buildScheduleCard([
                            DoctorScheduleModel(scheduleId: "1", doctorId: "dummy", dayOfWeek: 1, startTime: "10:00:00", endTime: "18:00:00", isAvailable: true),
                            DoctorScheduleModel(scheduleId: "2", doctorId: "dummy", dayOfWeek: 2, startTime: "10:00:00", endTime: "18:00:00", isAvailable: true),
                          ]),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text("Update Profile Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.power_settings_new_rounded),
                              label: const Text("Sign Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No Data Found"));
          }

          final doctor = snapshot.data!['profile'] as DoctorProfileModel;
          final schedules = snapshot.data!['schedules'] as List<DoctorScheduleModel>;
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
                        _buildInfoRow(Icons.work_history_rounded, "Experience", "${doctor.experienceYears.toStringAsFixed(0)} Years"),
                        _buildDivider(),
                        _buildInfoRow(Icons.payments_rounded, "Consultation Fee", "${doctor.consultationFee.toStringAsFixed(0)} EGP"),
                        _buildDivider(),
                        _buildInfoRow(Icons.description_rounded, "Biography", doctor.biography.isNotEmpty ? doctor.biography : "No biography provided"),
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
                      _buildScheduleCard(schedules),

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
    Widget imageWidget;
    if (displayImage != null && displayImage.isNotEmpty) {
      final String fullImageUrl = displayImage.startsWith('http') ? displayImage : "${ApiConstants.serverUrl}$displayImage";
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : primaryColor.withOpacity(0.15),
        child: Icon(
            Icons.person_rounded,
            size: 50,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.03), blurRadius: 10)],
      ),
      child: schedules.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("No work hours set", style: TextStyle(color: context.subText), textAlign: TextAlign.center),
          )
        : Column(children: schedules.map((s) => Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, size: 18, color: primaryColor),
                title: Text(s.getDayName(), style: TextStyle(fontWeight: FontWeight.w600, color: context.onSurface)),
                trailing: Text("${s.startTime} - ${s.endTime}", style: TextStyle(color: context.subText, fontWeight: FontWeight.bold)),
                subtitle: Text(s.isAvailable ? "Available" : "Unavailable", style: TextStyle(color: s.isAvailable ? Colors.green : Colors.red, fontSize: 11)),
              ),
              if (schedules.last != s) Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerCol),
            ],
          )).toList()),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 10),
    child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.onSurface)),
  );

  Widget _buildInfoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.03), blurRadius: 10)],
    ),
    child: Column(children: children),
  );

  Widget _buildInfoRow(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: primaryColor, size: 20),
    title: Text(label, style: TextStyle(fontSize: 12, color: context.subText)),
    subtitle: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.onSurface)),
  );

  Widget _buildDivider() => Divider(height: 1, indent: 50, endIndent: 20, color: context.dividerCol);
}
