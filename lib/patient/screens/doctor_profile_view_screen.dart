import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorProfileViewScreen extends StatefulWidget {
  final String doctorId;
  final String? patientId;

  const DoctorProfileViewScreen({super.key, required this.doctorId, this.patientId});

  @override
  State<DoctorProfileViewScreen> createState() => _DoctorProfileViewScreenState();
}

class _DoctorProfileViewScreenState extends State<DoctorProfileViewScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String phone = phoneNumber.trim();
    if (phone.isEmpty) return;

    if (phone.startsWith('0020')) {
      phone = '+${phone.substring(2)}';
    } else if (phone.startsWith('0')) {
      phone = '+20${phone.substring(1)}';
    } else if (phone.startsWith('20') && phone.length >= 12) {
      phone = '+$phone';
    } else if (!phone.startsWith('+')) {
      phone = '+20$phone';
    }

    final Uri url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch WhatsApp")));
      }
    }
  }

  Future<Map<String, dynamic>> _fetchDoctorAndReceptionist() async {
    final results = await Future.wait([
      _apiService.getDoctorDetails(widget.doctorId, widget.patientId ?? ""),
      _apiService.getReceptionistByDoctorId(widget.doctorId).catchError((_) => null),
    ]);
    return {
      'doctor': results[0] as DoctorFullModel,
      'receptionist': results[1],
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDoctorAndReceptionist(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(child: Text("Error: ${snapshot.error ?? 'Doctor details not found.'}")),
          );
        }

        final doctor = snapshot.data!['doctor'] as DoctorFullModel;
        final receptionist = snapshot.data!['receptionist'] as ReceptionistProfileModel?;

        debugPrint("Doctor Profile URL: ${doctor.profilePictureUrl}");

        final String displayImage = (doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty)
            ? doctor.profilePictureUrl!
            : "https://via.placeholder.com/150";

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          appBar: AppBar(
            backgroundColor: primaryColor,
            elevation: 0,
            title: const Text("Doctor Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityCard(doctor, displayImage),
                const SizedBox(height: 25),
                // شلنا العُمر (age) من الدالة دي
                _buildStatsRow(doctor),
                const SizedBox(height: 30),
                if (receptionist != null) ...[
                  _buildSectionTitle("Contact Receptionist"),
                  _buildReceptionistCard(receptionist),
                  const SizedBox(height: 25),
                ],
                _buildSectionTitle("Biography"),
                _buildInfoCard(doctor.biography),
                const SizedBox(height: 25),
                _buildSectionTitle("Work Schedule"),
                _buildScheduleList(doctor.doctorSchedules),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityCard(DoctorFullModel doctor, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            backgroundColor: context.isDark ? const Color(0xFF1E293B) : Colors.grey[200],
            child: doctor.profilePictureUrl == null || doctor.profilePictureUrl!.isEmpty
                ? const Icon(Icons.person, size: 40, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Dr. ${doctor.firstName} ${doctor.lastName}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.onSurface),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specializationName.isEmpty ? "Specialist" : doctor.specializationName,
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // التعديل هنا: شلنا كارت العمر وسبنا الخبرة والسعر
  Widget _buildStatsRow(DoctorFullModel doctor) {
    return Row(
      children: [
        _buildStatItem("Experience", "${doctor.experienceYears.toStringAsFixed(0)} Yrs", Icons.work, Colors.blue),
        _buildStatItem("Fee", "${doctor.consultationFee.toStringAsFixed(0)} EGP", Icons.payments, Colors.green),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(15), border: Border.all(color: context.dividerCol)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.onSurface)),
            ),
            Text(label, style: TextStyle(color: context.subText, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionistCard(ReceptionistProfileModel receptionist) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.support_agent_rounded, color: primaryColor),
            ),
            title: Text("${receptionist.firstName} ${receptionist.lastName}", style: TextStyle(fontWeight: FontWeight.bold, color: context.onSurface)),
            subtitle: Text(receptionist.phoneNumber, style: TextStyle(fontSize: 13, color: context.subText)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(receptionist.phoneNumber),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text("Call"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(receptionist.phoneNumber),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text("WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<DoctorScheduleModel> schedules) {
    if (schedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(15)),
        child: Text("No schedule available.", style: TextStyle(color: context.subText), textAlign: TextAlign.center),
      );
    }
    return Column(
      children: schedules.map((s) => Card(
        color: context.cardBg,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.access_time, color: primaryColor),
          title: Text(s.getDayName(), style: TextStyle(fontWeight: FontWeight.bold, color: context.onSurface)),
          trailing: Text("${s.startTime} - ${s.endTime}", style: TextStyle(color: context.subText)),
          subtitle: Text(s.isAvailable ? "Available" : "Unavailable", style: TextStyle(color: s.isAvailable ? Colors.green : Colors.red, fontSize: 11)),
        ),
      )).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.onSurface)));
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(15)),
      child: Text(text.isNotEmpty ? text : "No biography provided.", style: TextStyle(color: context.subText, height: 1.5)),
    );
  }
}