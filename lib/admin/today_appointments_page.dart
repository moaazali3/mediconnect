import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TodayAppointmentsPage extends StatefulWidget {
  const TodayAppointmentsPage({super.key});

  @override
  State<TodayAppointmentsPage> createState() => _TodayAppointmentsPageState();
}

class _TodayAppointmentsPageState extends State<TodayAppointmentsPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;
  DateTime _selectedDate = DateTime.now();
  bool _hasUserSelectedDate = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        _hasUserSelectedDate 
            ? _apiService.getAllAppointments(pageSize: 5000) 
            : _apiService.getTodayAppointments(),
        _apiService.getAllDoctorsForAdmin(),
        _apiService.getAllSpecializations(),
      ]).then((results) => {
        'appointments': results[0] as List<AppointmentModel>,
        'doctors': results[1] as List<DoctorModel>,
        'specializations': results[2] as List<SpecializationModel>,
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasUserSelectedDate = true;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: CommonAppBar(
        title: "Today's Bookings",
        subtitle: DateFormat('EEEE, d MMMM').format(_selectedDate),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
          if (_hasUserSelectedDate)
            IconButton(
              icon: const Icon(Icons.today, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                  _hasUserSelectedDate = false;
                });
                _loadData();
              },
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
              child: Column(
                children: [
                  _buildHeader(100),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: const Icon(Icons.category_rounded, color: primaryColor),
                              title: const Text("Loading Specialization", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                                child: const Text("10", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: context.inputFill, borderRadius: BorderRadius.circular(12)),
                                  child: const ListTile(
                                    title: Text("Loading Doctor", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    subtitle: Text("10 Bookings", style: TextStyle(fontSize: 12)),
                                    trailing: Icon(Icons.chevron_right, size: 18, color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: const Text("Retry", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            );
          }

          final allAppts = snapshot.data!['appointments'] as List<AppointmentModel>;
          final allDoctors = snapshot.data!['doctors'] as List<DoctorModel>;
          final allSpecs = snapshot.data!['specializations'] as List<SpecializationModel>;

          // 1. Filter by date
          List<AppointmentModel> filtered = allAppts;
          if (_hasUserSelectedDate) {
            filtered = allAppts.where((app) {
              String appDate = app.appointmentDate.split('T')[0].trim();
              return appDate == selectedDateStr || app.appointmentDate.contains(selectedDateStr);
            }).toList();
          }

          // 2. Build Lookup & Normalization Maps
          Map<String, String> specLookup = {
            for (var s in allSpecs) s.name.trim().toLowerCase(): s.name.trim()
          };
          Map<String, String> docIdToSpec = {
            for (var d in allDoctors) d.id.trim().toLowerCase(): d.specializationName.trim()
          };
          Map<String, String> docNameToSpec = {
            for (var d in allDoctors) "${d.firstName} ${d.lastName}".trim().toLowerCase(): d.specializationName.trim()
          };

          // 3. Grouping - Initialize with ALL specs from DB to ensure none are "missing"
          Map<String, Map<String, List<AppointmentModel>>> groupedData = {
            for (var s in allSpecs) s.name.trim(): {}
          };

          for (var appt in filtered) {
            String? spec = (appt.specializationName?.trim() ?? "").isNotEmpty 
                ? appt.specializationName!.trim() 
                : null;

            if (spec == null) {
              String docId = appt.doctorId.trim().toLowerCase();
              String docName = appt.doctorName.trim();
              spec = docIdToSpec[docId] ?? docNameToSpec[docName.toLowerCase()] ?? "Uncategorized";
            }

            // Normalize to match DB name
            String finalSpec = specLookup[spec.toLowerCase()] ?? spec;
            String finalDocName = appt.doctorName.trim().isNotEmpty ? appt.doctorName.trim() : "Unknown Doctor";

            groupedData.putIfAbsent(finalSpec, () => {});
            groupedData[finalSpec]!.putIfAbsent(finalDocName, () => []);
            groupedData[finalSpec]![finalDocName]!.add(appt);
          }

          // 4. Sort: Prioritize sections with bookings, then alphabetical
          var sortedSpecs = groupedData.entries.toList()
            ..sort((a, b) {
              int sumA = a.value.values.fold(0, (p, c) => p + c.length);
              int sumB = b.value.values.fold(0, (p, c) => p + c.length);
              if (sumA != sumB) return sumB.compareTo(sumA);
              return a.key.compareTo(b.key);
            });

          return Column(
            children: [
              _buildHeader(filtered.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: sortedSpecs.length,
                  itemBuilder: (context, index) {
                    final specEntry = sortedSpecs[index];
                    final specName = specEntry.key;
                    final doctors = specEntry.value;
                    final totalSpec = doctors.values.fold(0, (p, c) => p + c.length);

                    // Skip empty specs if they are "Uncategorized" or if user only wants active ones
                    // But here we keep them to solve the "missing spec" issue
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Icon(
                            specName == "Uncategorized" ? Icons.help_outline : Icons.category_rounded,
                            color: totalSpec > 0 ? primaryColor : context.subText
                          ),
                          title: Text(specName, style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: totalSpec > 0 ? context.onSurface : context.subText
                          )),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: totalSpec > 0 ? primaryColor : context.filterChipBg, 
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text("$totalSpec", style: TextStyle(color: totalSpec > 0 ? Colors.white : context.subText, fontWeight: FontWeight.bold)),
                          ),
                          children: doctors.isEmpty 
                            ? [Padding(padding: const EdgeInsets.all(15), child: Text("No bookings for this department", style: TextStyle(fontSize: 12, color: context.subText)))]
                            : doctors.entries.map<Widget>((doc) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: context.inputFill, borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(doc.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    subtitle: Text("${doc.value.length} Bookings", style: const TextStyle(fontSize: 12)),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: primaryColor),
                                    onTap: () => _showDoctorAppointments(context, doc.key, doc.value),
                                  ),
                                );
                              }).toList()..add(const SizedBox(height: 10)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDoctorAppointments(BuildContext context, String name, List<AppointmentModel> appts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.onSurface)),
                      Text("${appts.length} Appointments", style: TextStyle(color: context.subText)),
                    ],
                  ),
                ),
                IconButton(icon: Icon(Icons.close, color: context.onSurface), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: appts.length,
                itemBuilder: (context, i) {
                  final appt = appts[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.dividerCol),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: primaryColor,
                          radius: 18,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt.patientName, style: TextStyle(fontWeight: FontWeight.bold, color: context.onSurface)),
                              Text("${appt.startTime} - ${appt.endTime}", style: TextStyle(color: context.subText, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appt.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appt.status,
                            style: TextStyle(color: _getStatusColor(appt.status), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryColor, Color(0xFF475AD1)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text("Total Appointments", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text("$count", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('comp') || s.contains('finish') || s.contains('confirm')) return Colors.green;
    return Colors.red;
  }
}
