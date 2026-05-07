import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:intl/intl.dart';

class TotalAppointmentsPage extends StatefulWidget {
  const TotalAppointmentsPage({super.key});

  @override
  State<TotalAppointmentsPage> createState() => _TotalAppointmentsPageState();
}

class _TotalAppointmentsPageState extends State<TotalAppointmentsPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        _apiService.getAllAppointments(pageSize: 5000),
        _apiService.getAllDoctors(pageSize: 2000),
        _apiService.getAllSpecializations(),
      ]).then((results) => {
        'list': results[0] as List<AppointmentModel>,
        'doctors': results[1] as List<DoctorModel>,
        'specializations': results[2] as List<SpecializationModel>,
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        title: "All Bookings",
        subtitle: _selectedDate == null ? "Grouped by Specialization" : "Records for ${DateFormat('dd MMM yyyy').format(_selectedDate!)}",
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () => setState(() => _selectedDate = null),
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

          final allAppointments = snapshot.data!['list'] as List<AppointmentModel>;
          final allDoctors = snapshot.data!['doctors'] as List<DoctorModel>;
          final allSpecs = snapshot.data!['specializations'] as List<SpecializationModel>;

          // 1. Filter by date if selected
          List<AppointmentModel> filtered = allAppointments;
          if (_selectedDate != null) {
            final String ymd = DateFormat('yyyy-MM-dd').format(_selectedDate!);
            filtered = allAppointments.where((app) => app.appointmentDate.contains(ymd)).toList();
          }

          // 2. Maps for lookup fallback and normalization
          Map<String, String> specLookup = {
            for (var s in allSpecs) s.name.trim().toLowerCase(): s.name.trim()
          };
          Map<String, String> docIdToSpec = {for (var d in allDoctors) d.id.trim().toLowerCase(): d.specializationName.trim()};
          Map<String, String> docNameToSpec = {for (var d in allDoctors) "${d.firstName} ${d.lastName}".trim().toLowerCase(): d.specializationName.trim()};

          // 3. Grouping: Map<Specialization, Map<DoctorName, List<AppointmentModel>>>
          // Initialize with all specializations from DB
          Map<String, Map<String, List<AppointmentModel>>> groupedData = {
            for (var s in allSpecs) s.name.trim(): {}
          };

          for (var appt in filtered) {
            // Priority 1: specializationName from API
            String? spec = (appt.specializationName != null && appt.specializationName!.trim().isNotEmpty)
                ? appt.specializationName!.trim()
                : null;

            // Priority 2 & 3: Fallback to doctor list lookup
            if (spec == null) {
              String docId = appt.doctorId != null ? appt.doctorId.toString().trim().toLowerCase() : "";
              String cleanName = appt.doctorName != null ? appt.doctorName.toString().trim().toLowerCase() : "";

              if (docId.isNotEmpty && docIdToSpec.containsKey(docId)) {
                spec = docIdToSpec[docId];
              } else if (cleanName.isNotEmpty && docNameToSpec.containsKey(cleanName)) {
                spec = docNameToSpec[cleanName];
              }
            }

            // تأمين إضافي للمسافات وحالة الأحرف
            String safeSpecKey = spec?.toLowerCase().trim() ?? "";

            String normalizedSpec = (spec != null && specLookup.containsKey(safeSpecKey))
                ? specLookup[safeSpecKey]!
                : (spec != null && spec.trim().isNotEmpty ? spec.trim() : "General / Others");

            String docName = (appt.doctorName != null && appt.doctorName.trim().isNotEmpty)
                ? appt.doctorName.trim()
                : "Unknown Doctor";

            groupedData.putIfAbsent(normalizedSpec, () => {});
            groupedData[normalizedSpec]!.putIfAbsent(docName, () => []);
            groupedData[normalizedSpec]![docName]!.add(appt);
          }
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sortedSpecs.length,
                  itemBuilder: (context, index) {
                    final specEntry = sortedSpecs[index];
                    final specName = specEntry.key;
                    final doctors = specEntry.value;
                    final totalSpec = doctors.values.fold(0, (p, c) => p + c.length);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.medical_services_rounded, 
                            color: totalSpec > 0 ? primaryColor : Colors.grey
                          ),
                          title: Text(specName, style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: totalSpec > 0 ? Colors.black : Colors.grey[600]
                          )),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: totalSpec > 0 ? primaryColor : Colors.grey[300], 
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text("$totalSpec", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          children: doctors.isEmpty 
                            ? [const Padding(padding: EdgeInsets.all(15), child: Text("No records for this department", style: TextStyle(color: Colors.grey, fontSize: 12)))]
                            : doctors.entries.map<Widget>((doc) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(doc.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    subtitle: Text("${doc.value.length} Bookings", style: const TextStyle(fontSize: 12)),
                                    trailing: const Icon(Icons.chevron_right, size: 18, color: primaryColor),
                                    onTap: () => _showAppointmentsList(context, doc.key, doc.value),
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

  void _showAppointmentsList(BuildContext context, String doctorName, List<AppointmentModel> appts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                      Text(doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${appts.length} Total Bookings", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("${appt.appointmentDate.split('T')[0]} | ${appt.startTime}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(appt.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appt.status,
                            style: TextStyle(color: _getStatusColor(appt.status), fontWeight: FontWeight.bold, fontSize: 10),
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
          Text("$count", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('comp') || s.contains('confirm')) return Colors.green;
    return Colors.red;
  }
}
