import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/admin/today_appointments_page.dart';
import 'package:mediconnect/admin/today_doctors_page.dart';
import 'package:mediconnect/admin/today_revenue_page.dart';
import 'package:mediconnect/admin/total_doctors_page.dart';
import 'package:mediconnect/admin/total_appointments_page.dart';
import 'package:mediconnect/admin/total_revenue_page.dart';
import 'package:mediconnect/admin/total_patients_page.dart';

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
  int _uniquePatientsCount = 0;
  
  // Today's Status Counts
  int _todayPending = 0;
  int _todayConfirmed = 0;
  int _todayCancelled = 0;

  // Top Doctor Info
  String? _topDoctorName;
  String? _topDoctorSpec;
  int _topDoctorBookings = 0;
  
  List<MapEntry<String, int>> _topSpecializations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final results = await Future.wait([
        _apiService.getAdminDashboardStats(),
        _apiService.getTodayAppointments(),
        _apiService.getDoctorsWorkingToday(),
        _apiService.getAllPatients(),
        _apiService.getAllAppointments(pageSize: 5000), 
        _apiService.getAllDoctors(pageSize: 2000),
        _apiService.getAllSpecializations(),
      ]);

      final stats = results[0] as AdminDashboardModel;
      final todayAppts = results[1] as List<AppointmentModel>;
      final activeDoctors = results[2] as List;
      final allPatients = results[3] as List;
      final allAppts = results[4] as List<AppointmentModel>;
      final allDoctors = results[5] as List<DoctorModel>;
      final allSpecs = results[6] as List<SpecializationModel>;

      // Count today's statuses
      int pending = 0;
      int confirmed = 0;
      int cancelled = 0;
      for (var appt in todayAppts) {
        final s = appt.status.toLowerCase();
        if (s == 'pending' || s == 'waiting') pending++;
        else if (s == 'confirmed' || s == 'accepted' || s == 'completed') confirmed++;
        else if (s == 'cancelled' || s == 'rejected') cancelled++;
      }

      // 1. Unique Patients
      final Set<String> uniqueNames = {for (var p in allPatients) "${p.firstName} ${p.lastName}".toLowerCase().trim()};

      // 2. Lookup Maps
      Map<String, String> docIdToSpec = {for (var d in allDoctors) d.id.trim().toLowerCase(): d.specializationName.trim()};
      Map<String, String> docNameToSpec = {for (var d in allDoctors) "${d.firstName} ${d.lastName}".trim().toLowerCase(): d.specializationName.trim()};

      // 3. Initialize Spec Counts
      Map<String, int> specCounts = {for (var s in allSpecs) s.name.trim(): 0};
      Map<String, int> doctorCounts = {};

      for (var appt in allAppts) {
        String docName = appt.doctorName.trim();
        if (docName.isEmpty) docName = "Unknown Doctor";
        doctorCounts[docName] = (doctorCounts[docName] ?? 0) + 1;

        // Determine Spec
        String? spec = (appt.specializationName?.trim() ?? "").isNotEmpty ? appt.specializationName!.trim() : null;
        if (spec == null) {
          String docId = appt.doctorId.trim().toLowerCase();
          spec = docIdToSpec[docId] ?? docNameToSpec[docName.toLowerCase()] ?? "General";
        }
        
        spec = spec.trim();
        specCounts[spec] = (specCounts[spec] ?? 0) + 1;
      }

      // Find Top Doctor
      String? topName;
      String? topSpec;
      int topBookings = 0;
      if (doctorCounts.isNotEmpty) {
        var sortedDocs = doctorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        topName = sortedDocs.first.key;
        topBookings = sortedDocs.first.value;
        topSpec = docNameToSpec[topName.toLowerCase()] ?? "General";
      }

      if (mounted) {
        setState(() {
          _todayPending = pending;
          _todayConfirmed = confirmed;
          _todayCancelled = cancelled;
          _uniquePatientsCount = uniqueNames.length;
          _topDoctorName = topName;
          _topDoctorSpec = topSpec;
          _topDoctorBookings = topBookings;
          _topSpecializations = specCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          _stats = stats.copyWith(
            totalDoctorsToday: activeDoctors.length,
            totalAppointmentsToday: todayAppts.length,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryColor));
    if (_error != null) return _buildErrorState();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Overview Today"),
            const SizedBox(height: 15),
            _buildStatsGrid(_stats!),
            const SizedBox(height: 20),
            _buildTodayStatusCard(),
            const SizedBox(height: 30),
            _buildSectionHeader("System Summary"),
            const SizedBox(height: 15),
            _buildTopDoctorPerformanceCard(),
            const SizedBox(height: 20),
            _buildSummaryCard("Bookings by Specialization", _topSpecializations, Icons.medical_services_rounded),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's Appointment Status",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildStatusItem("Pending", _todayPending, Colors.orange, Icons.hourglass_empty_rounded)),
              Expanded(child: _buildStatusItem("Confirmed", _todayConfirmed, Colors.green, Icons.check_circle_outline_rounded)),
              Expanded(child: _buildStatusItem("Cancelled", _todayCancelled, Colors.red, Icons.cancel_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "$count",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopDoctorPerformanceCard() {
    if (_topDoctorName == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
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
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.star_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Top Performing Doctor",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _topDoctorName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _topDoctorSpec ?? "General",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$_topDoctorBookings",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Bookings",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<MapEntry<String, int>> data, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142))
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...data.take(5).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${entry.value} Bookings", 
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)
                ),
              ],
            ),
          )),
          const Divider(),
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalAppointmentsPage())),
              child: const Text("View All Records", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title, 
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
    );
  }

  Widget _buildStatsGrid(AdminDashboardModel stats) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildStatCard("Today Appts", stats.totalAppointmentsToday.toString(), Icons.calendar_today_rounded, Colors.pink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayAppointmentsPage())))),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard("Active Doctors", stats.totalDoctorsToday.toString(), Icons.person_search_rounded, Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayDoctorsPage())))),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildWideStatCard("Today Revenue", "${stats.totalRevenueToday.toStringAsFixed(0)} EGP", Icons.payments_rounded, Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayRevenuePage()))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildSmallStat("Patients", _uniquePatientsCount.toString(), Icons.people_rounded, Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalPatientsPage())))),
              const SizedBox(width: 12),
              Expanded(child: _buildSmallStat("Total Doctors", _stats!.totalDoctors.toString(), Icons.medical_services_rounded, Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalDoctorsPage())))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildWideStatCard("Total Revenue", "${_stats!.totalRevenue.toStringAsFixed(0)} EGP", Icons.account_balance_wallet_rounded, Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalRevenuePage()))),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 16), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: _loadData, child: const Text("Retry"))])));
  }
}
