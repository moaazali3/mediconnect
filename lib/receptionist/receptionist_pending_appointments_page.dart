import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/patient/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ReceptionistPendingAppointmentsPage extends StatefulWidget {
  const ReceptionistPendingAppointmentsPage({super.key});

  @override
  State<ReceptionistPendingAppointmentsPage> createState() => _ReceptionistPendingAppointmentsPageState();
}

class _ReceptionistPendingAppointmentsPageState extends State<ReceptionistPendingAppointmentsPage> {
  final ApiService _apiService = ApiService();
  
  List<AppointmentModel> _allAppointments = [];
  List<DoctorScheduleModel> _schedule = [];
  List<DateTime> _availableDates = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  String _selectedDate = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception("User not logged in");

      // 1. Fetch Receptionist Profile to get Doctor ID
      final profile = await _apiService.getReceptionistProfile(userId);
      
      // 2. Fetch Appointments and Schedule in parallel
      final results = await Future.wait([
        _apiService.getReceptionistAppointments(userId),
        if (profile.doctorId != null && profile.doctorId != "0")
          _apiService.getDoctorSchedule(profile.doctorId!)
        else
          Future.value(<DoctorScheduleModel>[]),
      ]);

      if (mounted) {
        setState(() {
          _allAppointments = (results[0] as List<AppointmentModel>)
              .where((a) => a.status.toLowerCase() == 'pending')
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

    // 1. Add dates from existing pending appointments
    for (var app in _allAppointments) {
      try {
        DateTime d = DateTime.parse(app.appointmentDate);
        dateSet.add(DateTime(d.year, d.month, d.day));
      } catch (e) {
        debugPrint("Error parsing appt date: $e");
      }
    }

    // 2. Add working days from schedule for the next 30 days
    if (_schedule.isNotEmpty) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      for (int i = 0; i < 30; i++) {
        DateTime d = today.add(Duration(days: i));
        // Using the same logic as doctor_pending_appointments_page
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

  List<AppointmentModel> get _filteredAppointments {
    return _allAppointments.where((a) {
      bool matchesDate = _selectedDate == "All" || a.appointmentDate == _selectedDate;
      bool matchesSearch = a.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          a.doctorName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDate && matchesSearch;
    }).toList()
      ..sort((a, b) {
        int dateCompare = a.appointmentDate.compareTo(b.appointmentDate);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
  }

  Future<void> _updateStatus(String id, bool isAccept) async {
    setState(() => _isProcessing = true);
    try {
      bool success;
      if (isAccept) {
        success = await _apiService.completeAppointmentStatus(id);
      } else {
        success = await _apiService.cancelAppointmentStatus(id);
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccept ? "Appointment Completed!" : "Appointment Cancelled!", style: const TextStyle(color: Colors.white)),
            backgroundColor: isAccept ? Colors.green : Colors.red,
          ),
        );
        // Refresh data after update
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _navigateToProfile(String patientId) {
    if (patientId.isNotEmpty && patientId != "0") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userId: patientId,
            readOnly: true,
            showMedicalHistory: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apps = _filteredAppointments;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchField(),
                  const SizedBox(height: 20),
                  _buildDateFilterSection(),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Pending Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: primaryColor),
                    ))
                  else if (_errorMessage != null)
                    Center(child: Column(
                      children: [
                        Text("Error: $_errorMessage"),
                        ElevatedButton(onPressed: _fetchData, child: const Text("Retry"))
                      ],
                    ))
                  else if (apps.isEmpty && _selectedDate != "All")
                      Center(child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text("No pending appointments on ${DateFormat('EEE, d MMM').format(DateTime.parse(_selectedDate))}"),
                      ))
                    else if (apps.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text("No pending appointments found"),
                        ))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: apps.map((app) => _buildAppointmentCard(app)).toList(),
                          ),
                        ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator(color: primaryColor)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              "Pending Appointments",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              softWrap: true,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text("${_allAppointments.length} Pending", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
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
        decoration: InputDecoration(
          hintText: "Search patient or doctor...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: context.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildDateFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Filter by Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
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
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : context.filterChipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryColor : context.filterChipBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

  Widget _buildAppointmentCard(AppointmentModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToProfile(app.patientId),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Text(
                            app.patientName.isNotEmpty ? app.patientName[0].toUpperCase() : "?",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 22)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.patientName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: context.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                                "Doctor: ${app.doctorName}",
                                style: TextStyle(color: context.subText, fontSize: 13)
                            ),
                            const SizedBox(height: 2),
                            Text(
                                "${app.dayOfWeek}, ${app.appointmentDate}",
                                style: TextStyle(color: context.subText, fontSize: 13)
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${_formatTime(app.startTime)} - ${_formatTime(app.endTime)}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "Q No: ${app.queueNumber}",
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("Completed", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
