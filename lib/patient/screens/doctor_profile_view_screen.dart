import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/PaymentModel.dart';

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

  Future<void> _handlePaymentAndBooking(DoctorFullModel doctor) async {
    if (widget.patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first to book an appointment.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final payment = PaymentModel(
        paymentId: "", 
        appointmentId: "", 
        createdDate: DateTime.now().toIso8601String(),
        paymentMethod: "Online",
        paymentStatus: "Completed",
        amount: doctor.consultationFee,
      );

      final success = await _apiService.createPayment(payment);

      if (!mounted) return;
      Navigator.pop(context); 

      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment failed. Please try again."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Success!\nYour appointment and payment were successful.", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Great!"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DoctorFullModel>(
      future: _apiService.getDoctorDetails(widget.doctorId, widget.patientId ?? ""),
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

        final doctor = snapshot.data!;
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
          bottomNavigationBar: _buildBottomBar(doctor),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityCard(doctor, displayImage),
                const SizedBox(height: 25),
                _buildStatsRow(doctor, age),
                const SizedBox(height: 30),
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
              children: [
                Text("Dr. ${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(doctor.specializationName, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
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
        _buildStatItem("Age", age > 0 ? "$age Yrs" : "N/A", Icons.calendar_month, Colors.orange),
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
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

  Widget _buildBottomBar(DoctorFullModel doctor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Booking Fee", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("${doctor.consultationFee.toStringAsFixed(0)} EGP", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: doctor.isAppleToAppointment ? () => _handlePaymentAndBooking(doctor) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: doctor.isAppleToAppointment ? primaryColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(doctor.isAppleToAppointment ? "BOOK & PAY NOW" : "UNAVAILABLE"),
            ),
          ],
        ),
      ),
    );
  }
}
