import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
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
  double _totalRevenue = 0;
  int _totalCompletedAppointments = 0;
  List<SpecRevenue> _specsRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dashboard = await _apiService.getAdminDashboard();
      final specializations = await _apiService.getAllSpecializations();
      final doctors = await _apiService.getAllDoctors(pageSize: 1000);

      // Fetch specialization revenues in parallel to speed up loading
      final List<double> specRevenues = await Future.wait(
        specializations.map((spec) => _apiService.getSpecializationRevenue(spec.name))
      );

      List<SpecRevenue> tempSpecs = [];

      for (int i = 0; i < specializations.length; i++) {
        final spec = specializations[i];
        final specRev = specRevenues[i];
        
        final specDocs = doctors.where((d) => 
          d.specializationName.toLowerCase().trim() == spec.name.toLowerCase().trim()
        ).toList();
        
        // For each specialization, fetch its doctors' revenue in parallel
        final List<double> docRevenues = await Future.wait(
          specDocs.map((doc) => _apiService.getDoctorRevenue(doc.id))
        );
        
        List<DoctorRevenue> tempDocs = [];
        for (int j = 0; j < specDocs.length; j++) {
          if (docRevenues[j] > 0) {
            tempDocs.add(DoctorRevenue(
              name: "Dr. ${specDocs[j].firstName} ${specDocs[j].lastName}",
              revenue: docRevenues[j],
            ));
          }
        }

        if (specRev > 0 || tempDocs.isNotEmpty) {
          tempDocs.sort((a, b) => b.revenue.compareTo(a.revenue));
          tempSpecs.add(SpecRevenue(
            name: spec.name,
            totalRevenue: specRev > 0 ? specRev : tempDocs.fold(0.0, (sum, d) => sum + d.revenue),
            doctors: tempDocs,
          ));
        }
      }

      tempSpecs.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      if (mounted) {
        setState(() {
          _totalRevenue = dashboard.totalRevenue;
          _totalCompletedAppointments = dashboard.totalCompletedAppointments;
          _specsRevenue = tempSpecs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading revenue: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CommonAppBar(
        title: "Total Revenue",
        showBackButton: true,
        onRefresh: _loadData,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Revenue by Specialization"),
                  const SizedBox(height: 15),
                  if (_specsRevenue.isEmpty)
                    _buildEmptyState()
                  else
                    ..._specsRevenue.map((spec) => _buildSpecItem(spec)),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Accumulated Revenue",
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          FittedBox(
            child: Text(
              "${_totalRevenue.toStringAsFixed(0)} EGP",
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "$_totalCompletedAppointments Completed Appointments",
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildSpecItem(SpecRevenue spec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF1F5F9),
          child: Icon(Icons.category_rounded, color: primaryColor, size: 20),
        ),
        title: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Text(
          "${spec.totalRevenue.toStringAsFixed(0)} EGP",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 15),
        ),
        children: spec.doctors.isEmpty 
          ? [const Padding(padding: EdgeInsets.all(15), child: Text("No individual doctor revenue recorded", style: TextStyle(color: Colors.grey, fontSize: 12)))]
          : spec.doctors.map((doc) => _buildDoctorRow(doc)).toList(),
      ),
    );
  }

  Widget _buildDoctorRow(DoctorRevenue doc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(doc.name, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500))),
          Text("${doc.revenue.toStringAsFixed(0)} EGP", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            Text("No revenue data found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class SpecRevenue {
  final String name;
  final double totalRevenue;
  final List<DoctorRevenue> doctors;
  SpecRevenue({required this.name, required this.totalRevenue, required this.doctors});
}

class DoctorRevenue {
  final String name;
  final double revenue;
  DoctorRevenue({required this.name, required this.revenue});
}
