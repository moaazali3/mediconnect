import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/MedicalRecordModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/patient/screens/profile.dart'; 
import 'package:intl/intl.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final String? doctorId;
  const DoctorAppointmentsPage({super.key, this.doctorId});

  @override
  State<DoctorAppointmentsPage> createState() => DoctorAppointmentsPageState();
}

class DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final ApiService _apiService = ApiService();
  
  List<DoctorAppointmentModel> _allAppointments = [];
  List<DoctorScheduleModel> _schedule = [];
  List<DateTime> _availableDates = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;
  
  String _selectedDate = "All"; 
  String _searchQuery = ""; 
  final TextEditingController _searchController = TextEditingController();

  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refreshAppointments() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String idToFetch = widget.doctorId ?? "1";
      final results = await Future.wait([
        _apiService.getDoctorAppointments(idToFetch),
        _apiService.getDoctorSchedule(idToFetch),
      ]);

      if (mounted) {
        setState(() {
          _allAppointments = (results[0] as List<DoctorAppointmentModel>)
              .where((a) => a.status.toLowerCase() == 'completed')
              .toList();
          _schedule = results[1] as List<DoctorScheduleModel>;
          _generateAvailableDates();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _generateAvailableDates() {
    _availableDates.clear();
    Set<DateTime> dateSet = {};

    for (var app in _allAppointments) {
      try {
        DateTime d = DateTime.parse(app.appointmentDate);
        dateSet.add(DateTime(d.year, d.month, d.day));
      } catch (e) {
        debugPrint("Error parsing appt date: $e");
      }
    }

    if (_schedule.isNotEmpty) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      for (int i = 0; i < 30; i++) {
        DateTime d = today.add(Duration(days: i));
        if (_schedule.any((s) => s.isScheduledFor(d.weekday))) {
          dateSet.add(d);
        }
      }
    }

    if (_schedule.isNotEmpty) {
      _availableDates = dateSet.where((d) => _schedule.any((s) => s.isScheduledFor(d.weekday))).toList();
    } else {
      _availableDates = dateSet.toList();
    }
    _availableDates.sort();
  }

  List<DoctorAppointmentModel> get _filteredAppointments {
    return _allAppointments.where((a) {
      bool matchesDate = _selectedDate == "All" || a.appointmentDate == _selectedDate;
      bool matchesSearch = a.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDate && matchesSearch;
    }).toList()
      ..sort((a, b) {
        int dateCompare = a.appointmentDate.compareTo(b.appointmentDate);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
  }

  void _navigateToProfile(DoctorAppointmentModel app) {
    if (app.patientId.isNotEmpty && app.patientId != "0") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: app.patientId, readOnly: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient data not available"), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showMedicalRecordDialog(DoctorAppointmentModel appointment, {MedicalRecordModel? existingRecord}) {
    _diagnosisController.text = existingRecord?.diagnosis ?? "";
    _prescriptionController.text = existingRecord?.prescription ?? "";
    bool isEdit = existingRecord != null;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 650;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.note_add_rounded, color: Colors.white, size: isSmallScreen ? 22 : 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEdit ? "Edit Record" : "Add Record",
                  style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
        ),
        content: SizedBox(
          width: size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "Patient: ${appointment.patientName}",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDialogTextField(
                  controller: _diagnosisController,
                  label: "Diagnosis",
                  hint: "Enter diagnosis...",
                  icon: Icons.assignment_outlined,
                  isSmall: isSmallScreen,
                ),
                const SizedBox(height: 15),
                _buildDialogTextField(
                  controller: _prescriptionController,
                  label: "Prescription",
                  hint: "List medications...",
                  icon: Icons.medication_rounded,
                  isSmall: isSmallScreen,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        actions: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("CANCEL", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_diagnosisController.text.isEmpty || _prescriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }
                  Navigator.pop(dialogContext);
                  _saveMedicalRecord(appointment, isEdit, existingRecord);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEdit ? "UPDATE" : "SAVE", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveMedicalRecord(DoctorAppointmentModel appointment, bool isEdit, MedicalRecordModel? existingRecord) async {
    setState(() => _isProcessing = true);
    try {
      bool success = isEdit
          ? await _apiService.updateMedicalRecord(existingRecord!.medicalRecordId, _diagnosisController.text, _prescriptionController.text)
          : await _apiService.createMedicalRecord(CreateMedicalRecordModel(
              appointmentId: appointment.appointmentId,
              diagnosis: _diagnosisController.text,
              prescription: _prescriptionController.text,
            ));
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully saved!"), backgroundColor: Colors.green));
        _fetchData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isSmall = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isSmall ? 2 : 3,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 650;
    final apps = _filteredAppointments;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHeader(isSmallScreen),
                  const SizedBox(height: 15),
                  _buildSearchField(), 
                  const SizedBox(height: 15),
                  _buildDateFilterSection(isSmallScreen),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("History Records", style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: primaryColor)))
                  else if (apps.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No records available.", style: TextStyle(color: Colors.grey))))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: apps.map((app) => _buildAppointmentCard(app, isSmallScreen)).toList(),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_isProcessing)
              Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: primaryColor))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Appointments History", 
              style: TextStyle(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text("${_filteredAppointments.length} Done", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search by patient name...",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildDateFilterSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Filter Date", style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterItem("All", "All"),
              ..._availableDates.map((date) {
                final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                final String displayLabel = DateFormat('EEE, d MMM').format(date);
                return _buildFilterItem(displayLabel, formattedDate);
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterItem(String label, String value) {
    bool isSelected = _selectedDate == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _buildAppointmentCard(DoctorAppointmentModel app, bool isSmall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _navigateToProfile(app),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: isSmall ? 20 : 24,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(app.patientName.isNotEmpty ? app.patientName[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            title: Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("${app.appointmentDate} • ${app.startTime}", style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text("${app.startTime} - ${app.endTime}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    Text("Q No: ${app.queueNumber}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _fetchAndEditRecord(app),
                    icon: const Icon(Icons.history_edu_rounded, size: 16),
                    label: const Text("Medical Record", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor, width: 1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndEditRecord(DoctorAppointmentModel appointment) async {
    setState(() => _isProcessing = true);
    try {
      final record = await _apiService.getMedicalRecordByAppointment(appointment.appointmentId);
      if (mounted) _showMedicalRecordDialog(appointment, existingRecord: record);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching record: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
