import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class TotalRevenuePage extends StatefulWidget {
  const TotalRevenuePage({super.key});

  @override
  State<TotalRevenuePage> createState() => _TotalRevenuePageState();
}

class _TotalRevenuePageState extends State<TotalRevenuePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  double _totalRevenue = 0.0;
  int _totalAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Fetch data
      final results = await Future.wait([
        _apiService.getAllAppointments(),
        _apiService.getAllDoctors(pageSize: 1000),
      ]);

      final List<AppointmentModel> allAppointments = results[0] as List<AppointmentModel>;
      final List<DoctorModel> allDoctors = results[1] as List<DoctorModel>;

      // Create a map for quick doctor lookup with trimmed IDs
      Map<String, DoctorModel> doctorMap = {for (var d in allDoctors) d.id.trim(): d};
      
      double calculatedTotalRevenue = 0;
      List<Map<String, dynamic>> transactions = [];

      for (var app in allAppointments) {
        final doctorId = app.doctorId.trim();
        final doc = doctorMap[doctorId];
        
        final status = app.status.toLowerCase().trim();
        
        // Include any successful/completed status
        if (status == 'completed' || status == 'confirmed' || status == 'paid' || status == 'success') {
          double fee = doc?.consultationFee ?? 0.0;
          calculatedTotalRevenue += fee;
          
          transactions.add({
            "patientName": app.patientName.isNotEmpty ? app.patientName : "Patient",
            "doctorName": doc != null ? "Dr. ${doc.firstName} ${doc.lastName}" : (app.doctorName.isNotEmpty ? app.doctorName : "Doctor"),
            "specialization": doc?.specializationName ?? (app.specializationName ?? "General"),
            "fee": fee,
            "date": app.appointmentDate,
            "status": app.status,
          });
        }
      }

      // Sort by date descending (Newest first)
      transactions.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _totalRevenue = calculatedTotalRevenue;
          _totalAppointments = transactions.length;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), 
      appBar: CommonAppBar(
        title: "Revenue Details",
        showBackButton: true,
        onRefresh: _loadData,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("All Transactions"),
                  const SizedBox(height: 15),
                  if (_transactions.isEmpty)
                    _buildEmptyState()
                  else
                    ..._transactions.map((item) => _buildTransactionItem(item)).toList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text(
            "No successful transactions found",
            style: TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF1E3A8A)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Accumulated Revenue", 
            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              "${_totalRevenue.toStringAsFixed(0)} EGP",
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 42, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallStat(Icons.calendar_month, "All Time"),
              const SizedBox(width: 20),
              _buildSmallStat(Icons.people_outline, "$_totalAppointments Appts"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['patientName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item['specialization']} - ${item['doctorName']}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  item['date'],
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${item['fee'].toStringAsFixed(0)} EGP",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF059669),
                ),
              ),
              const Text(
                "Paid",
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
