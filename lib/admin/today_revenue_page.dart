import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
            colorScheme: context.isDark 
                ? ColorScheme.dark(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).colorScheme.primary,
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
      final DateTime now = DateTime.now();
      final bool isToday = _selectedDate.year == now.year &&
                           _selectedDate.month == now.month &&
                           _selectedDate.day == now.day;

      print("=== [TODAY REVENUE PAGE DEBUG] ===");
      print("Selected Date: $_selectedDate");
      print("Is Today check: $isToday (Current Time: $now)");

      if (isToday) {
        // إذا كنا بنعرض أرباح اليوم الحالي، نستخدم إندبوينتس السيرفر المباشرة فائقة الدقة والسرعة!
        print("Using direct Today Revenue endpoints from Server...");
        final results = await Future.wait([
          _apiService.getAllSpecializations(),
          _apiService.getAllDoctorsForAdmin(),
        ]);

        final allSpecs = results[0] as List<SpecializationModel>;
        final allDoctors = results[1] as List<DoctorModel>;

        print("Today Mode - All Doctors Count from Server: ${allDoctors.length}");
        print("Today Mode - All Specializations Count from Server: ${allSpecs.length}");

        double calculatedTotalRevenue = 0.0;
        final List<Map<String, dynamic>> breakdown = [];

        // خريطة التخصصات لضمان عدم وجود تكرار أو مسافات زائدة
        Map<String, String> specLookup = {
          for (var s in allSpecs) s.name.trim().toLowerCase(): s.name.trim()
        };

        // جلب أرباح كل تخصص بشكل مباشر من السيرفر
        for (var spec in allSpecs) {
          // جلب دكاترة هذا التخصص
          final specDoctors = allDoctors.where((d) =>
            (d.specializationName ?? "").trim().toLowerCase() == spec.name.trim().toLowerCase()
          ).toList();

          double specRevenueToday = 0.0;
          int activeDoctorsCount = 0;

          // جلب أرباح دكاترة التخصص لليوم من السيرفر بشكل مستقل وآمن
          final docRevsToday = await Future.wait(
            specDoctors.map((doc) async {
              try {
                final rev = await _apiService.getDoctorRevenueToday(doc.id);
                print("  Today Revenue for Dr. ${doc.firstName} ${doc.lastName} (ID: ${doc.id}): $rev EGP");
                return rev;
              } catch (e) {
                print("  Error fetching today's revenue for doctor ${doc.id}: $e");
                return 0.0;
              }
            })
          );

          for (int i = 0; i < specDoctors.length; i++) {
            if (docRevsToday[i] > 0) {
              specRevenueToday += docRevsToday[i];
              activeDoctorsCount++;
            }
          }

          // جلب أرباح التخصص اليوم من الإندبوينت المباشر
          double apiSpecRevToday = 0.0;
          try {
            apiSpecRevToday = await _apiService.getSpecializationRevenueToday(spec.name);
            print("  Today Revenue for Specialization '${spec.name}': $apiSpecRevToday EGP");
          } catch (e) {
            print("  Error fetching today's revenue for specialization ${spec.name}: $e");
          }

          double finalSpecRevToday = apiSpecRevToday > 0 ? apiSpecRevToday : specRevenueToday;

          if (finalSpecRevToday > 0 || activeDoctorsCount > 0) {
            calculatedTotalRevenue += finalSpecRevToday;
            breakdown.add({
              "name": spec.name,
              "revenue": finalSpecRevToday,
              "count": activeDoctorsCount,
            });
          }
        }

        breakdown.sort((a, b) => b['revenue'].compareTo(a['revenue']));

        print("Today Direct Total Revenue: $calculatedTotalRevenue");
        print("Today Direct Breakdown: $breakdown");
        print("=== [END TODAY REVENUE PAGE DEBUG] ===");

        return {
          "totalRevenue": calculatedTotalRevenue,
          "breakdown": breakdown,
        };
      } else {
        // إذا كان المستخدم يبحث في تاريخ سابق، نستخدم الفلترة الذكية للمواعيد
        print("Using memory-based appointment filtering for custom date...");
        final results = await Future.wait([
          _apiService.getAllAppointments(pageSize: 5000),
          _apiService.getAllDoctorsForAdmin(),
          _apiService.getAllSpecializations(),
        ]);

        final allAppointments = results[0] as List<AppointmentModel>;
        final allDoctors = results[1] as List<DoctorModel>;
        final allSpecs = results[2] as List<SpecializationModel>;

        print("All Appointments Count from Server: ${allAppointments.length}");

        final String targetYMD = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final String targetDMY = DateFormat('dd/MM/yyyy').format(_selectedDate);

        final dayAppts = allAppointments.where((app) {
          String dateStr = app.appointmentDate.trim();
          if (dateStr.isEmpty) return false;

          final DateTime? parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            return parsedDate.year == _selectedDate.year &&
                   parsedDate.month == _selectedDate.month &&
                   parsedDate.day == _selectedDate.day;
          }
          return dateStr.contains(targetYMD) || dateStr.contains(targetDMY);
        }).toList();

        double calculatedTotalRevenue = 0;
        Map<String, Map<String, dynamic>> specData = {
          for (var spec in allSpecs) spec.name.trim(): {"revenue": 0.0, "count": 0}
        };

        Map<String, String> specLookup = {
          for (var s in allSpecs) s.name.trim().toLowerCase(): s.name.trim()
        };

        Map<String, DoctorModel> doctorMap = {
          for (var d in allDoctors) d.id.trim().toLowerCase(): d
        };

        for (var app in dayAppts) {
          final String cleanDocId = app.doctorId.trim().toLowerCase();
          final doc = doctorMap[cleanDocId];
          if (doc != null) {
            final String specNameLower = doc.specializationName.trim().toLowerCase();
            final String finalSpecName = specLookup[specNameLower] ?? doc.specializationName.trim();

            specData[finalSpecName] ??= {"revenue": 0.0, "count": 0};

            final status = app.status.toLowerCase().trim();
            final bool isSuccessStatus = status == 'completed' || status == 'confirmed' || status == 'paid' || status == 'success' || status == 'finished';

            if (isSuccessStatus) {
              double fee = doc.consultationFee;
              calculatedTotalRevenue += fee;
              specData[finalSpecName]!["revenue"] = (specData[finalSpecName]!["revenue"] as double) + fee;
              specData[finalSpecName]!["count"] = (specData[finalSpecName]!["count"] as int) + 1;
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
          "breakdown": breakdown,
        };
      }
    } catch (e, stack) {
      print("=== [ERROR TODAY REVENUE PAGE] ===");
      print("Exception: $e");
      print("Stacktrace: $stack");
      print("==================================");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: CommonAppBar(
        title: "Daily Revenue",
        subtitle: DateFormat('EEEE, d MMMM').format(_selectedDate),
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _selectDate(context),
          ),
        ],
        onRefresh: _loadData,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Skeletonizer(
              enabled: true,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTotalHeader(1000),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 10, 25, 15),
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 18, color: context.onSurface),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Breakdown by Specialty",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRevenueItem("Loading Specialization", 5, 500),
                  )),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}", style: TextStyle(color: context.onSurface)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text("Retry")),
                ],
              ),
            );
          }

          final totalRevenue = (snapshot.data!["totalRevenue"] as num).toDouble();
          final breakdown = snapshot.data!["breakdown"] as List<Map<String, dynamic>>;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTotalHeader(totalRevenue),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 10, 25, 15),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 18, color: context.onSurface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Breakdown by Specialty",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                if (breakdown.isEmpty)
                  _buildEmptyState()
                else
                  ...breakdown.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRevenueItem(item['name'], item['count'], item['revenue']),
                  )).toList(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: context.subText.withValues(alpha: 0.5), size: 50),
            const SizedBox(height: 10),
            Text("No revenue records for ${DateFormat('EEEE').format(_selectedDate)}",
                style: TextStyle(color: context.subText)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalHeader(double total) {
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
            "Revenue for Selected Day",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.5)
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              "${total.toStringAsFixed(0)} EGP",
              style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String title, int count, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface)
                ),
                Text("$count Appointments", style: TextStyle(color: context.subText, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${amount.toStringAsFixed(0)} EGP",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF059669)),
              ),
              Text("Collected", style: TextStyle(fontSize: 10, color: context.subText, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
