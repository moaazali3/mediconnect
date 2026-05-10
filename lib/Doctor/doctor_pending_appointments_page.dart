import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/patient/screens/profile.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DoctorPendingAppointmentsPage extends StatefulWidget {
  final String? doctorId;
  const DoctorPendingAppointmentsPage({super.key, this.doctorId});

  @override
  State<DoctorPendingAppointmentsPage> createState() => DoctorPendingAppointmentsPageState();
}

class DoctorPendingAppointmentsPageState extends State<DoctorPendingAppointmentsPage> {
  final ApiService _apiService = ApiService();

  List<DoctorAppointmentModel> _allAppointments = [];
  List<DoctorScheduleModel> _schedule = [];
  List<DateTime> _availableDates = [];
  bool _isLoading = true;
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

    // 2. Add working days from schedule for the next 30 days (as in doctor_appointments_page)
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final apps = _filteredAppointments;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: ListView(
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
                Skeletonizer(
                  enabled: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(4, (index) => _buildAppointmentCard(
                        DoctorAppointmentModel(
                          appointmentId: "dummy",
                          doctorId: "dummy",
                          patientId: "dummy",
                          patientName: "Loading Patient Name",
                          appointmentDate: "2024-01-01",
                          startTime: "10:00",
                          endTime: "10:30",
                          status: "pending",
                          dayOfWeek: "Monday",
                          queueNumber: 1,
                        ),
                      )),
                    ),
                  ),
                )
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
              "Pending Appointment",
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
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search by patient name...",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: context.inputFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
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

  // التعديل هنا: نفس التصميم بالظبط بتاع صفحة الـ History
  Widget _buildFilterItem(String label, String value) {
    bool isSelected = _selectedDate == value;
    return GestureDetector(
      onTap: () {
        if (_selectedDate != value) {
          setState(() => _selectedDate = value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : context.filterChipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : context.filterChipBorder,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isSelected ? Colors.white : context.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(DoctorAppointmentModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _navigateToProfile(app),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: Text(
                app.patientName.isNotEmpty ? app.patientName[0].toUpperCase() : "?",
                style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
            title: Text(
              app.patientName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "${app.appointmentDate} • ${app.startTime}",
              style: TextStyle(fontSize: 11, color: context.subText),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      "${app.startTime} - ${app.endTime}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  "Q No: ${app.queueNumber}",
                  style: TextStyle(color: context.subText, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}