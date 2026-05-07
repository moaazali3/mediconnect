import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';

class SpecializationDetailPage extends StatefulWidget {
  final String specializationName;

  const SpecializationDetailPage({super.key, required this.specializationName});

  @override
  State<SpecializationDetailPage> createState() => _SpecializationDetailPageState();
}

class _SpecializationDetailPageState extends State<SpecializationDetailPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _doctorsData = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorsRevenue();
  }

  Future<void> _loadDoctorsRevenue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // هنجيب كل الدكاترة (عشان نضمن إننا جبناهم كلهم) ونفلترهم إحنا بالتخصص
      final allDoctors = await _apiService.getAllDoctors(pageSize: 1000);
      final specializationDoctors = allDoctors.where((doc) {
        return doc.specializationName?.toLowerCase().trim() == widget.specializationName.toLowerCase().trim();
      }).toList();

      List<Map<String, dynamic>> data = [];

      for (var doctor in specializationDoctors) {
        try {
          // هنا التعديل: الدالة بقت بترجع double مباشرة
          final double revenue = await _apiService.getDoctorRevenue(doctor.id);
          data.add({
            'doctor': doctor,
            'revenue': revenue,
          });
        } catch (e) {
          data.add({
            'doctor': doctor,
            'revenue': 0.0,
          });
        }
      }

      // نرتبهم من الأعلى ربحاً للأقل عشان الداشبورد تبقى احترافية
      data.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      if (mounted) {
        setState(() {
          _doctorsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${widget.specializationName} Doctors"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
          ? Center(child: Text(_error!))
          : _doctorsData.isEmpty
          ? const Center(child: Text("No doctors found in this specialization"))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _doctorsData.length,
        itemBuilder: (context, index) {
          final data = _doctorsData[index];
          final DoctorModel doctor = data['doctor'];
          return _buildDoctorRevenueCard(doctor, data['revenue']);
        },
      ),
    );
  }

  Widget _buildDoctorRevenueCard(DoctorModel doctor, dynamic revenue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: doctor.profilePictureUrl != null
                ? NetworkImage(doctor.profilePictureUrl!)
                : null,
            child: doctor.profilePictureUrl == null
                ? const Icon(Icons.person, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. ${doctor.firstName} ${doctor.lastName}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  widget.specializationName,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${(revenue as double).toStringAsFixed(0)} EGP",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "Total Revenue",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}