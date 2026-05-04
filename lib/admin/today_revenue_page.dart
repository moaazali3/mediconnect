import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';

class TodayRevenuePage extends StatefulWidget {
  const TodayRevenuePage({super.key});

  @override
  State<TodayRevenuePage> createState() => _TodayRevenuePageState();
}

class _TodayRevenuePageState extends State<TodayRevenuePage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;
  DateTime _selectedDate = DateTime.now();

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<Map<String, dynamic>> _fetchCombinedData() async {
    try {
      final results = await Future.wait([
        _apiService.getAllAppointments(),
        _apiService.getAllDoctors(pageSize: 500),
        _apiService.getAllSpecializations(),
      ]);

      final allAppointments = results[0] as List<AppointmentModel>;
      final allDoctors = results[1] as List<DoctorModel>;
      final allSpecs = results[2] as List<SpecializationModel>;

      final String targetYMD = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final String targetDMY = DateFormat('dd/MM/yyyy').format(_selectedDate);

      // فلترة مواعيد اليوم المختار
      final dayAppts = allAppointments.where((app) {
        String date = app.appointmentDate;
        return date.contains(targetYMD) || date.contains(targetDMY);
      }).toList();

      double calculatedTotalRevenue = 0;
      Map<String, Map<String, dynamic>> specData = {
        for (var spec in allSpecs) spec.name: {"revenue": 0.0, "count": 0}
      };

      Map<String, DoctorModel> doctorMap = {for (var d in allDoctors) d.id: d};

      for (var app in dayAppts) {
        final doc = doctorMap[app.doctorId];
        if (doc != null) {
          specData[doc.specializationName] ??= {"revenue": 0.0, "count": 0};
          specData[doc.specializationName]!["count"] = (specData[doc.specializationName]!["count"] as int) + 1;
          
          // احتساب الإيرادات فقط للمواعيد المكتملة
          if (app.status.toLowerCase() == 'completed') {
            double fee = doc.consultationFee;
            calculatedTotalRevenue += fee;
            specData[doc.specializationName]!["revenue"] = (specData[doc.specializationName]!["revenue"] as double) + fee;
          }
        }
      }

      final List<Map<String, dynamic>> breakdown = [];
      specData.forEach((name, data) {
        if (data["count"] > 0 || data["revenue"] > 0) {
          breakdown.add({
            "name": name,
            "revenue": data["revenue"],
            "count": data["count"],
          });
        }
      });

      breakdown.sort((a, b) => b['revenue'].compareTo(a['revenue']));

      return {
        "totalRevenue": calculatedTotalRevenue,
        "totalAppts": dayAppts.length,
        "breakdown": breakdown,
      };
    } catch (e) {
      debugPrint("Error in TodayRevenuePage: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        title: "Revenue by Day",
        subtitle: DateFormat('EEEE, d MMMM').format(_selectedDate),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
        ],
        onRefresh: _loadData,
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

          final totalRevenue = (snapshot.data!["totalRevenue"] as num).toDouble();
          final totalAppts = snapshot.data!["totalAppts"] as int;
          final breakdown = snapshot.data!["breakdown"] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTotalHeader(totalRevenue, totalAppts),
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
                          Text("No revenue data for ${DateFormat('EEEE').format(_selectedDate)}", 
                            style: const TextStyle(color: Colors.grey)),
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
          const Text("Revenue for Selected Day", style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1)),
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
                Text("$count Appts for this Day", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
            child: const Icon(Icons.payments_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3142))),
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
