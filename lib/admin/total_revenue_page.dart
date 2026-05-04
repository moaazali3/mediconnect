import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
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
  List<Map<String, dynamic>> _breakdown = [];
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final specializations = await _apiService.getAllSpecializations();
      
      final revenueFutures = specializations.map((spec) => 
        _apiService.getSpecializationRevenue(spec.name).catchError((e) => {
          "totalRevenue": 0.0,
          "appointmentCount": 0
        })
      ).toList();

      final revenues = await Future.wait(revenueFutures);

      List<Map<String, dynamic>> breakdown = [];
      double total = 0.0;
      for (int i = 0; i < specializations.length; i++) {
        final revData = revenues[i];
        
        double amount = (revData['totalRevenue'] ?? 
                         revData['TotalRevenue'] ?? 
                         revData['revenue'] ?? 0.0).toDouble();
                         
        int count = revData['appointmentCount'] ?? 
                    revData['totalAppointments'] ?? 
                    revData['TotalAppointments'] ?? 
                    revData['count'] ?? 
                    revData['totalBookings'] ?? 
                    revData['TotalBookings'] ?? 0;
        
        if (amount > 0 || count > 0) {
          breakdown.add({
            "name": specializations[i].name,
            "revenue": amount,
            "count": count,
          });
          total += amount;
        }
      }

      breakdown.sort((a, b) => b['revenue'].compareTo(a['revenue']));

      setState(() {
        _breakdown = breakdown;
        _totalRevenue = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
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
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 20),
                  const Text(
                    "Revenue by Specialization",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 12),
                  if (_breakdown.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No revenue data available")))
                  else
                    ..._breakdown.map((item) => _buildRevenueItem(item)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF003366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("Overall Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            "${_totalRevenue.toStringAsFixed(0)} EGP",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
        ),
        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          "${item['revenue'].toStringAsFixed(0)} EGP",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
        ),
      ),
    );
  }
}
