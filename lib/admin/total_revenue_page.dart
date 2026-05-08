import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

// --- كلاسات مساعدة لتنظيم الداتا في الشاشة ---
class SpecRevenueData {
  final String name;
  final double totalRevenue;
  List<DoctorRevenueData> doctors = [];
  SpecRevenueData({required this.name, required this.totalRevenue});
}

class DoctorRevenueData {
  final String id;
  final String name;
  final double revenue;
  DoctorRevenueData({required this.id, required this.name, required this.revenue});
}

class TotalRevenuePage extends StatefulWidget {
  const TotalRevenuePage({super.key});

  @override
  State<TotalRevenuePage> createState() => _TotalRevenuePageState();
}

class _TotalRevenuePageState extends State<TotalRevenuePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  List<SpecRevenueData> _specializationsData = [];
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
      // 1. جلب إجمالي الأرباح والحجوزات من الداشبورد
      final dashboard = await _apiService.getAdminDashboardStats();

      // 2. جلب كل التخصصات والدكاترة
      final specializations = await _apiService.getAllSpecializations();
      final doctors = await _apiService.getAllDoctors(pageSize: 1000);

      List<SpecRevenueData> finalSpecs = [];

      // 3. بناء الداتا بذكاء (لمعالجة أي باج في الباك إند)
      for (var spec in specializations) {

        // فلترة دكاترة التخصص ده (بمقارنة دقيقة تتجاهل المسافات والحروف الكابيتال)
        var specDoctors = doctors.where((d) =>
        (d.specializationName ?? "").trim().toLowerCase() == spec.name.trim().toLowerCase()
        ).toList();

        double calculatedSpecRev = 0.0;
        List<DoctorRevenueData> tempDocsList = [];

        // جلب أرباح دكاترة التخصص ده باستخدام Endpoint الدكتور
        final docRevs = await Future.wait(
            specDoctors.map((doc) => _apiService.getDoctorRevenue(doc.id))
        );

        // تجميع بيانات الدكاترة اللي حققوا أرباح
        for (int i = 0; i < specDoctors.length; i++) {
          if (docRevs[i] > 0) {
            calculatedSpecRev += docRevs[i];
            tempDocsList.add(DoctorRevenueData(
              id: specDoctors[i].id,
              name: "Dr. ${specDoctors[i].firstName} ${specDoctors[i].lastName}",
              revenue: docRevs[i],
            ));
          }
        }

        // جلب أرباح التخصص من Endpoint التخصص
        double apiSpecRev = await _apiService.getSpecializationRevenue(spec.name);

        // لو الباك إند رجع صفر بسبب مشكلة في الاسم، بنعتمد على المجموع اللي إحنا حسبناه من الدكاترة
        double actualSpecRev = apiSpecRev > 0 ? apiSpecRev : calculatedSpecRev;

        // لو التخصص ده فيه أرباح، هنضيفه في الشاشة
        if (actualSpecRev > 0 || tempDocsList.isNotEmpty) {
          tempDocsList.sort((a, b) => b.revenue.compareTo(a.revenue)); // ترتيب الدكاترة من الأعلى للأقل

          SpecRevenueData specData = SpecRevenueData(name: spec.name, totalRevenue: actualSpecRev);
          specData.doctors = tempDocsList;
          finalSpecs.add(specData);
        }
      }

      // ترتيب التخصصات من الأعلى للأقل
      finalSpecs.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      if (mounted) {
        setState(() {
          _totalRevenue = dashboard.totalRevenue;
          _totalAppointments = dashboard.totalCompletedAppointments;
          _specializationsData = finalSpecs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading revenue: $e"),
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
            _buildSectionTitle("Revenue by Specialization"),
            const SizedBox(height: 15),
            if (_specializationsData.isEmpty)
              _buildEmptyState()
            else
              ..._specializationsData.map((item) => _buildSpecializationItem(item)),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
            overflow: TextOverflow.ellipsis,
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
            "No revenue data found yet",
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
      padding: const EdgeInsets.all(25),
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
            textAlign: TextAlign.center,
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildSmallStat(Icons.calendar_month, "All Time"),
              _buildSmallStat(Icons.check_circle_outline, "$_totalAppointments Completed"),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationItem(SpecRevenueData spec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              spec.name.isNotEmpty ? spec.name[0].toUpperCase() : "",
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  spec.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: Color(0xFF1E293B)
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "${spec.totalRevenue.toStringAsFixed(0)} EGP",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: Color(0xFF059669)
                  ),
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: spec.doctors.isEmpty
              ? [const Padding(padding: EdgeInsets.all(8.0), child: Text("No doctors with revenue", style: TextStyle(color: Colors.grey)))]
              : spec.doctors.map((doc) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.grey, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    doc.name,
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${doc.revenue.toStringAsFixed(0)} EGP",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}
