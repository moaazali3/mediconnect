import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/MedicalRecordModel.dart';
import 'package:mediconnect/services/api_service.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String? userId; 
  const PatientHistoryScreen({super.key, this.userId});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    String idToFetch = widget.userId ?? "1"; 

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: const Text(
          "Medical History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<MedicalRecordModel>>(
        future: _apiService.getPatientMedicalHistory(idToFetch),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}"),
            ));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text("No medical records found"));
          }

          records.sort((a, b) => b.createdDate.compareTo(a.createdDate));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(records[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(MedicalRecordModel record) {
    const String baseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";
    
    String displaySpec = record.doctorSpecialty.trim();
    if (displaySpec.isEmpty || displaySpec.toLowerCase() == "null") {
      displaySpec = "Medical Specialist";
    }

    String displayName = record.doctorName;
    if (!displayName.startsWith("Dr.")) {
      displayName = "Dr. $displayName";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Doctor Image with border like home_content
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.1), width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: (record.doctorImageUrl != null && record.doctorImageUrl!.isNotEmpty)
                      ? NetworkImage(record.doctorImageUrl!.startsWith('http') ? record.doctorImageUrl! : "$baseUrl${record.doctorImageUrl}")
                      : null,
                  child: (record.doctorImageUrl == null || record.doctorImageUrl!.isEmpty)
                      ? const Icon(Icons.person, color: primaryColor, size: 30)
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              // Doctor Info like DoctorCard
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 17, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displaySpec,
                      style: TextStyle(
                        color: primaryColor.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Date in Blue
              Text(
                _formatDate(record.createdDate),
                style: const TextStyle(
                  color: primaryColor, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade100, height: 25),
          
          // Diagnosis Section
          Row(
            children: [
              Icon(Icons.medical_services_rounded, color: Colors.grey.shade400, size: 16),
              const SizedBox(width: 6),
              const Text("Diagnosis", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            record.diagnosis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
          ),
          const SizedBox(height: 15),

          // Prescription Section
          Row(
            children: [
              Icon(Icons.medication_rounded, color: Colors.grey.shade400, size: 16),
              const SizedBox(width: 6),
              const Text("Prescription", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.prescription,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return "N/A";
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}
