import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class TodayRevenuePage extends StatefulWidget {
  const TodayRevenuePage({super.key});

  @override
  State<TodayRevenuePage> createState() => _TodayRevenuePageState();
}

class _TodayRevenuePageState extends State<TodayRevenuePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchCombinedData();
    });
  }

  Future<Map<String, dynamic>> _fetchCombinedData() async {
    // 1. جلب بيانات لوحة التحكم (للحصول على إجمالي اليوم)
    final dashboard = await _apiService.getAdminDashboardStats();
    
    // 2. جلب كافة التخصصات
    final specializations = await _apiService.getAllSpecializations();
    
    // 3. جلب الإيرادات لكل تخصص باستخدام Endpoint التخصصات الجديد
    // نستخدم Future.wait لجلبهم بالتوازي لسرعة الأداء
    final List<Map<String, dynamic>> breakdown = [];
    
    final revenueFutures = specializations.map((spec) => 
      _apiService.getSpecializationRevenue(spec.name).catchError((e) => {
        "totalRevenue": 0.0,
        "appointmentCount": 0
      })
    ).toList();

    final revenues = await Future.wait(revenueFutures);

    for (int i = 0; i < specializations.length; i++) {
      final revData = revenues[i];
      // نأخذ التخصصات التي تحتوي على حجوزات فقط أو نظهر الجميع حسب التصميم
      double amount = (revData['totalRevenue'] ?? revData['revenue'] ?? 0.0).toDouble();
      int count = revData['appointmentCount'] ?? revData['totalAppointments'] ?? revData['count'] ?? 0;
      
      if (count > 0 || amount > 0) {
        breakdown.add({
          "name": specializations[i].name,
          "revenue": amount,
          "count": count,
        });
      }
    }

    // ترتيب تنازلي حسب الإيرادات
    breakdown.sort((a, b) => b['revenue'].compareTo(a['revenue']));

    return {
      "dashboard": dashboard,
      "breakdown": breakdown,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: const CommonAppBar(
        title: "Today's Revenue",
        showBackButton: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text("Retry")),
                ],
              ),
            );
          }

          final dashboard = snapshot.data!["dashboard"] as AdminDashboardModel;
          final breakdown = snapshot.data!["breakdown"] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTotalHeader(dashboard.totalRevenueToday, dashboard.totalAppointmentsToday),
                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 10, 25, 10),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 18, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text("Breakdown by Specialization", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
                    ],
                  ),
                ),
                if (breakdown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[400], size: 50),
                          const SizedBox(height: 10),
                          const Text("No breakdown data available", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ...breakdown.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRevenueItem(item['name'], item['count'], item['revenue']),
                  )).toList(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalHeader(double total, int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF0056b3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text("Today's Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(
            "${total.toStringAsFixed(0)} EGP",
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text("$count Bookings Today", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String title, int count, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.medical_services_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3142))),
                const SizedBox(height: 4),
                Text("$count Hajj / Bookings", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${amount.toStringAsFixed(0)} EGP",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.green),
              ),
              const Text("Collected", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
