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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: const Icon(Icons.person, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.doctorName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      record.doctorSpecialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(record.visitDate),
                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade100, height: 25),
          
          const Row(
            children: [
              Icon(Icons.medical_information_rounded, color: Colors.grey, size: 16),
              SizedBox(width: 6),
              Text("Diagnosis", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            record.diagnosis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 15),

          const Row(
            children: [
              Icon(Icons.medication_rounded, color: Colors.grey, size: 16),
              SizedBox(width: 6),
              Text("Prescription", style: TextStyle(color: Colors.grey, fontSize: 13)),
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
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}
