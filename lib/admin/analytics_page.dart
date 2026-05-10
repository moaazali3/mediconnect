import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
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
import 'package:skeletonizer/skeletonizer.dart';

class AnalyticsPage extends StatefulWidget {
  final String adminName;
  const AnalyticsPage({super.key, required this.adminName});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  AdminDashboardModel? _stats;
  int _uniquePatientsCount = 0;

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
        _apiService.getAllDoctorsForAdmin(),
        _apiService.getAllSpecializations(),
      ]);

      final stats = results[0] as AdminDashboardModel;
      final todayAppts = results[1] as List<AppointmentModel>;
      final activeDoctors = results[2] as List;
      final allPatients = results[3] as List;
      final allAppts = results[4] as List<AppointmentModel>;
      final allDoctors = results[5] as List<DoctorModel>;
      final allSpecs = results[6] as List<SpecializationModel>;

      final Set<String> uniqueNames = {for (var p in allPatients) "${p.firstName} ${p.lastName}".toLowerCase().trim()};
      Map<String, String> docIdToSpec = {for (var d in allDoctors) d.id.trim().toLowerCase(): d.specializationName.trim()};
      Map<String, String> docNameToSpec = {for (var d in allDoctors) "${d.firstName} ${d.lastName}".trim().toLowerCase(): d.specializationName.trim()};

      Map<String, int> specCounts = {for (var s in allSpecs) s.name.trim(): 0};
      Map<String, int> doctorCounts = {};

      for (var appt in allAppts) {
        String docName = appt.doctorName.trim();
        if (docName.isEmpty) docName = "Unknown Doctor";
        doctorCounts[docName] = (doctorCounts[docName] ?? 0) + 1;

        String? spec = (appt.specializationName?.trim() ?? "").isNotEmpty ? appt.specializationName!.trim() : null;
        if (spec == null) {
          String docId = appt.doctorId.trim().toLowerCase();
          spec = docIdToSpec[docId] ?? docNameToSpec[docName.toLowerCase()] ?? "General";
        }
        spec = spec.trim();
        specCounts[spec] = (specCounts[spec] ?? 0) + 1;
      }

      int todayPending = todayAppts.where((a) => a.status.toLowerCase() == "pending").length;
      int todayCompleted = todayAppts.where((a) => a.status.toLowerCase() == "completed").length;
      int todayCancelled = todayAppts.where((a) => a.status.toLowerCase() == "cancelled").length;

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
          _uniquePatientsCount = uniqueNames.length;
          _topDoctorName = topName;
          _topDoctorSpec = topSpec;
          _topDoctorBookings = topBookings;
          _topSpecializations = specCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          _stats = stats.copyWith(
            totalDoctorsToday: activeDoctors.length,
            totalAppointmentsToday: todayAppts.length,
            totalPendingAppointmentsToday: todayPending,
            totalCompletedAppointmentsToday: todayCompleted,
            totalCancelledAppointmentsToday: todayCancelled,
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
    if (_error != null) return _buildErrorState();

    final isSkeleton = _isLoading;
    final displayStats = _stats ?? AdminDashboardModel(
      totalAppointments: 100,
      totalCompletedAppointments: 80,
      totalPendingAppointments: 10,
      totalCancelledAppointments: 10,
      totalRevenue: 5000,
      totalDoctors: 20,
      totalPatients: 50,
      totalDoctorsToday: 5,
      totalAppointmentsToday: 20,
      totalPendingAppointmentsToday: 5,
      totalCompletedAppointmentsToday: 10,
      totalCancelledAppointmentsToday: 5,
      totalRevenueToday: 1000,
    );

    return Skeletonizer(
      enabled: isSkeleton,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Overview Today"),
                    const SizedBox(height: 15),
                    _buildStatsGrid(displayStats),
                    const SizedBox(height: 15),
                    _buildTodayStatusesRow(displayStats),
                    const SizedBox(height: 30),
                    _buildSectionHeader("System Summary"),
                    const SizedBox(height: 15),
                    _buildOverallStatusCard(displayStats),
                    const SizedBox(height: 20),
                    _buildTopDoctorPerformanceCard(isSkeleton),
                    const SizedBox(height: 20),
                    _buildSummaryCard("Bookings by Specialization", isSkeleton ? [const MapEntry("Specialization", 10)] : _topSpecializations, Icons.category_rounded),
                    const SizedBox(height: 20),
                    _buildQuickStats(displayStats, isSkeleton),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 45),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, ${widget.adminName}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Manage your clinic operations efficiently.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatusesRow(AdminDashboardModel stats) {
    return Row(
      children: [
        Expanded(child: _buildStatusMiniCard("Completed", stats.totalCompletedAppointmentsToday.toString(), Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatusMiniCard("Pending", stats.totalPendingAppointmentsToday.toString(), Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatusMiniCard("Cancelled", stats.totalCancelledAppointmentsToday.toString(), Colors.red)),
      ],
    );
  }

  Widget _buildStatusMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: TextStyle(fontSize: 13, color: context.subText, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatusCard(AdminDashboardModel stats) {
    final int total = stats.totalAppointments;
    final double successRate = total > 0 ? (stats.totalCompletedAppointments / total) * 100 : 0;
    final double failureRate = total > 0 ? (stats.totalCancelledAppointments / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Overall Appointments Status",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatusVertical("Completed", stats.totalCompletedAppointments.toString(), Colors.green),
              _buildDivider(),
              _buildStatusVertical("Pending", stats.totalPendingAppointments.toString(), Colors.orange),
              _buildDivider(),
              _buildStatusVertical("Cancelled", stats.totalCancelledAppointments.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: context.dividerCol),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Success Rate", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.subText)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("${successRate.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Failure Rate", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.subText)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("${failureRate.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: context.dividerCol, margin: const EdgeInsets.symmetric(horizontal: 5));
  }

  Widget _buildStatusVertical(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 12, color: context.subText, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildTopDoctorPerformanceCard(bool isSkeleton) {
    if (!isSkeleton && _topDoctorName == null) return const SizedBox.shrink();

    final name = isSkeleton ? "Loading Name" : _topDoctorName!;
    final spec = isSkeleton ? "Specialization" : (_topDoctorSpec ?? "General");
    final bookings = isSkeleton ? 100 : _topDoctorBookings;

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
                          name,
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
                            spec,
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
                        "$bookings",
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.onSurface)),
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
                  child: Text(entry.key, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.onSurface, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Text("${entry.value} Bookings", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )),
          Divider(color: context.dividerCol),
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
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.onSurface));
  }

  Widget _buildStatsGrid(AdminDashboardModel stats) {
    final items = [
      _buildStatCard("Today Appts", stats.totalAppointmentsToday.toString(), Icons.calendar_today_rounded, Colors.pink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayAppointmentsPage()))),
      _buildStatCard("Active Doctors", stats.totalDoctorsToday.toString(), Icons.person_search_rounded, Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayDoctorsPage()))),
      _buildStatCard("Today Revenue", "${stats.totalRevenueToday.toStringAsFixed(0)} EGP", Icons.payments_rounded, Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TodayRevenuePage()))),
    ];
    return _buildDynamicGrid(items, spacing: 15, aspectRatio: 1.0);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.onSurface)),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: context.subText, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(AdminDashboardModel stats, bool isSkeleton) {
    final patientsCount = isSkeleton ? 50 : _uniquePatientsCount;
    final items = [
      _buildSmallStat("Patients", patientsCount.toString(), Icons.people_rounded, Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalPatientsPage()))),
      _buildSmallStat("Total Doctors", stats.totalDoctors.toString(), Icons.medical_services_rounded, Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalDoctorsPage()))),
      _buildSmallStat("Total Revenue", "${stats.totalRevenue.toStringAsFixed(0)} EGP", Icons.account_balance_wallet_rounded, Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TotalRevenuePage()))),
    ];
    return _buildDynamicGrid(items, spacing: 12, aspectRatio: 1.0);
  }

  Widget _buildSmallStat(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.onSurface)),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: context.subText, fontSize: 10, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicGrid(List<Widget> items, {required double spacing, required double aspectRatio}) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      if (i + 1 < items.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: AspectRatio(aspectRatio: aspectRatio, child: items[i])),
              SizedBox(width: spacing),
              Expanded(child: AspectRatio(aspectRatio: aspectRatio, child: items[i + 1])),
            ],
          ),
        );
      } else {
        rows.add(AspectRatio(aspectRatio: aspectRatio * 2.0, child: items[i]));
      }
      rows.add(SizedBox(height: spacing));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return Column(children: rows);
  }

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 16), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: _loadData, child: const Text("Retry"))])));
  }
}
