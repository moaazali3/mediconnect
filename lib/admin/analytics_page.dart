import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  AdminDashboardModel? _stats;
  List<AppointmentModel> _allAppointments = [];

  Map<String, int> _doctorPopularity = {};
  Map<int, int> _hourlyTraffic = {};
  double _expectedRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getAdminDashboardStats(),
        _apiService.getAllAppointments(),
      ]);

      _stats = results[0] as AdminDashboardModel;
      _allAppointments = results[1] as List<AppointmentModel>;

      _processAdvancedAnalytics();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _processAdvancedAnalytics() {
    _doctorPopularity.clear();
    _hourlyTraffic.clear();
    _expectedRevenue = 0;

    for (var app in _allAppointments) {
      String doctorId = app.doctorId.isNotEmpty ? app.doctorId : "Unknown";
      _doctorPopularity[doctorId] = (_doctorPopularity[doctorId] ?? 0) + 1;

      try {
        if (app.startTime.isNotEmpty) {
          int hour = int.parse(app.startTime.split(':')[0]);
          if (app.startTime.toUpperCase().contains("PM") && hour != 12) hour += 12;
          _hourlyTraffic[hour] = (_hourlyTraffic[hour] ?? 0) + 1;
        }
      } catch (_) {}

      if (app.status == "Pending") {
        _expectedRevenue += 200; 
      }
    }

    var sortedEntries = _doctorPopularity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _doctorPopularity = Map.fromEntries(sortedEntries.take(5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(
        title: "Advanced Analytics",
        showBackButton: true,
        onRefresh: _loadData,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Strategic Insights"),
                        const SizedBox(height: 15),
                        _buildExpectedRevenueCard(),
                        const SizedBox(height: 25),
                        _buildSectionHeader("Top Requested Doctor IDs"),
                        const SizedBox(height: 15),
                        _buildDoctorPopularityList(),
                        const SizedBox(height: 25),
                        _buildSectionHeader("Peak Operating Hours"),
                        const SizedBox(height: 15),
                        _buildTrafficChart(),
                        const SizedBox(height: 25),
                        _buildSectionHeader("System Summary"),
                        const SizedBox(height: 15),
                        _buildQuickStats(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }

  Widget _buildExpectedRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade50, radius: 25, child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Projected Revenue (Pending)", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text("${_expectedRevenue.toStringAsFixed(0)} EGP", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorPopularityList() {
    if (_doctorPopularity.isEmpty) return const Text("No booking data available");
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: _doctorPopularity.entries.map((e) {
          double maxVal = _doctorPopularity.values.isNotEmpty ? _doctorPopularity.values.first.toDouble() : 1.0;
          double progress = e.value / maxVal;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Doctor: ${e.key.length > 8 ? e.key.substring(0, 8) : e.key}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text("${e.value} bookings", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade100, color: Colors.teal, minHeight: 6, borderRadius: BorderRadius.circular(10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrafficChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (index) {
          int count = _hourlyTraffic[index] ?? 0;
          int maxTraffic = _hourlyTraffic.values.fold(0, (max, e) => e > max ? e : max);
          double heightFactor = maxTraffic == 0 ? 0 : count / maxTraffic;
          if (index < 8 || index > 22) return const SizedBox.shrink();
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 15,
                height: 120 * heightFactor + 2,
                decoration: BoxDecoration(color: count > 0 ? primaryColor : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 8),
              Text("${index > 12 ? index - 12 : index}${index >= 12 ? 'p' : 'a'}", style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_stats == null) return const SizedBox();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildSmallStat("Total Patients", _stats!.totalPatients.toString(), Colors.blue),
        _buildSmallStat("Active Doctors", _stats!.totalDoctors.toString(), Colors.teal),
        _buildSmallStat("Total Appts", _stats!.totalAppointments.toString(), Colors.indigo),
        _buildSmallStat("Total Revenue", "${_stats!.totalRevenue.toStringAsFixed(0)} EGP", Colors.orange),
        _buildSmallStat("Success Rate", "${(_stats!.totalCompletedAppointments / (_stats!.totalAppointments > 0 ? _stats!.totalAppointments : 1) * 100).toStringAsFixed(0)}%", Colors.green),
        _buildSmallStat("Cancellation", "${(_stats!.totalCancelledAppointments / (_stats!.totalAppointments > 0 ? _stats!.totalAppointments : 1) * 100).toStringAsFixed(0)}%", Colors.red),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
