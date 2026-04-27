import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';

class ConsultationRecord {
  final String doctorName;
  final String specialty;
  final String date;
  final String diagnosis;
  final List<String> prescription;
  final String imageUrl;

  ConsultationRecord({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.diagnosis,
    required this.prescription,
    required this.imageUrl,
  });
}

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final List<ConsultationRecord> records = [];

  @override
  void initState() {
    super.initState();
    const String dummyUrl = "https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg";
    // Dummy Data
    records.addAll([
      ConsultationRecord(
        doctorName: "Dr. Adam Doma",
        specialty: "Senior Dentist",
        date: "12 Oct 2026",
        diagnosis: "Gingivitis",
        prescription: ["Chlorhexidine Mouthwash", "Ibuprofen 400mg"],
        imageUrl: dummyUrl,
      ),
      ConsultationRecord(
        doctorName: "Dr. Sarah Johnson",
        specialty: "Cardiologist",
        date: "05 Sep 2026",
        diagnosis: "Mild Hypertension",
        prescription: ["Lisinopril 5mg", "Amlodipine 2.5mg"],
        imageUrl: dummyUrl,
      ),
      ConsultationRecord(
        doctorName: "Dr. Michael Chen",
        specialty: "General Physician",
        date: "20 Aug 2026",
        diagnosis: "Acute Bronchitis",
        prescription: ["Azithromycin 500mg", "Cough Syrup", "Panadol 500mg"],
        imageUrl: dummyUrl,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(records[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(ConsultationRecord record) {
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
          // Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: NetworkImage(record.imageUrl),
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
                      record.specialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                record.date,
                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade100, height: 25),
          
          // Diagnosis Section
          Row(
            children: const [
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

          // Prescription Section
          Row(
            children: const [
              Icon(Icons.medication_rounded, color: Colors.grey, size: 16),
              SizedBox(width: 6),
              Text("Prescription", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: record.prescription.map((med) => Chip(
              label: Text(med, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
              backgroundColor: primaryColor.withOpacity(0.08),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
