import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
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

  int _calculateAge(String dobString) {
    if (dobString.isEmpty) return 0;
    try {
      DateTime dob = DateTime.parse(dobString);
      DateTime today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
        
        // Print the profile picture URL for debugging
        debugPrint("Doctor Profile URL: ${doctor.profilePictureUrl}");

        final age = _calculateAge(doctor.dateOfBirth);
        final String displayImage = (doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty)
            ? doctor.profilePictureUrl!
            : "https://via.placeholder.com/150";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFF),
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
                _buildStatsRow(doctor, age),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            backgroundColor: Colors.grey[200],
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildStatsRow(DoctorFullModel doctor, int age) {
    return Row(
      children: [
        _buildStatItem("Experience", "${doctor.experienceYears.toStringAsFixed(0)} Yrs", Icons.work, Colors.blue),
        _buildStatItem("Fee", "${doctor.consultationFee.toStringAsFixed(0)} EGP", Icons.payments, Colors.green),
        _buildStatItem("Age", age > 0 ? "$age Yrs" : "N/A", Icons.cake, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionistCard(ReceptionistProfileModel receptionist) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: const Icon(Icons.support_agent_rounded, color: primaryColor),
            ),
            title: Text("${receptionist.firstName} ${receptionist.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(receptionist.phoneNumber, style: const TextStyle(fontSize: 13)),
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: const Text("No schedule available.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      );
    }
    return Column(
      children: schedules.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.access_time, color: primaryColor),
          title: Text(s.getDayName(), style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text("${s.startTime} - ${s.endTime}", style: const TextStyle(color: Colors.grey)),
          subtitle: Text(s.isAvailable ? "Available" : "Unavailable", style: TextStyle(color: s.isAvailable ? Colors.green : Colors.red, fontSize: 11)),
        ),
      )).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Text(text.isNotEmpty ? text : "No biography provided.", style: const TextStyle(color: Colors.grey, height: 1.5)),
    );
  }
}
