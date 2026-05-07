import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class TotalRevenuePage extends StatefulWidget {
  const TotalRevenuePage({super.key});

  @override
  State<TotalRevenuePage> createState() => _TotalRevenuePageState();
}

class _TotalRevenuePageState extends State<TotalRevenuePage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  double _totalRevenue = 0.0;
  List<Map<String, dynamic>> _specBreakdown = [];
  List<Map<String, dynamic>> _doctorBreakdown = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Basic Stats, Specs and Doctors
      final results = await Future.wait([
        _apiService.getAdminDashboardStats(),
        _apiService.getAllSpecializations(),
        _apiService.getAllDoctors(pageSize: 100),
      ]);

      final stats = results[0] as AdminDashboardModel;
      final specs = results[1] as List<SpecializationModel>;
      final doctors = results[2] as List<DoctorModel>;

      _totalRevenue = stats.totalRevenue;

      // 2. Fetch Detailed Revenue for each Specialization and Doctor in parallel
      final specFutures = specs.map((s) => _apiService.getSpecializationRevenue(s.name).catchError((_) => <String, dynamic>{}));
      final docFutures = doctors.map((d) => _apiService.getDoctorRevenue(d.id).catchError((_) => <String, dynamic>{}));

      final specResults = await Future.wait(specFutures);
      final docResults = await Future.wait(docFutures);

      // Process Specialization Data
      _specBreakdown = [];
      for (int i = 0; i < specs.length; i++) {
        final data = specResults[i] as Map<String, dynamic>;
        if (data.isEmpty) continue;
        double rev = (data['totalRevenue'] ?? data['TotalRevenue'] ?? 0.0).toDouble();
        if (rev > 0) {
          _specBreakdown.add({
            'name': specs[i].name,
            'revenue': rev,
            'count': data['appointmentCount'] ?? data['TotalAppointments'] ?? data['count'] ?? 0,
          });
        }
      }
      _specBreakdown.sort((a, b) => b['revenue'].compareTo(a['revenue']));

      // Process Doctor Data
      _doctorBreakdown = [];
      for (int i = 0; i < doctors.length; i++) {
        final data = docResults[i] as Map<String, dynamic>;
        if (data.isEmpty) continue;
        double rev = (data['totalRevenue'] ?? data['TotalRevenue'] ?? 0.0).toDouble();
        if (rev > 0) {
          _doctorBreakdown.add({
            'name': "Dr. ${doctors[i].firstName} ${doctors[i].lastName}",
            'revenue': rev,
            'count': data['appointmentCount'] ?? data['TotalAppointments'] ?? data['count'] ?? 0,
            'specialization': doctors[i].specializationName,
          });
        }
      }
      _doctorBreakdown.sort((a, b) => b['revenue'].compareTo(a['revenue']));

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching revenue details: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CommonAppBar(
        title: "Revenue Analytics",
        showBackButton: true,
        onRefresh: _loadData,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
        children: [
          _buildTotalCard(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Specializations"),
                Tab(text: "Doctors"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBreakdownList(_specBreakdown, Icons.medical_services_rounded),
                _buildBreakdownList(_doctorBreakdown, Icons.person_rounded, isDoctor: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
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
              style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(List<Map<String, dynamic>> data, IconData icon, {bool isDoctor = false}) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            const Text("No revenue records found", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    if (isDoctor)
                      Text(item['specialization'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                "${item['revenue'].toStringAsFixed(0)} EGP",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF059669)),
              ),
            ],
          ),
        );
      },
    );
  }
}
