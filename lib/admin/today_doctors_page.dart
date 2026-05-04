import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/admin/manage_bookings_page.dart'; 
import 'package:mediconnect/widgets/common_app_bar.dart';

class TodayDoctorsPage extends StatefulWidget {
  const TodayDoctorsPage({super.key});

  @override
  State<TodayDoctorsPage> createState() => _TodayDoctorsPageState();
}

class _TodayDoctorsPageState extends State<TodayDoctorsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<DoctorModel> _todayDoctors = [];
  List<DoctorModel> _filteredDoctors = [];
  bool _isLoading = true;
  String _searchQuery = "";
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchDoctorsForSelectedDate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(String time) {
    if (time.isEmpty) return "";
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return "${parts[0]}:${parts[1]}"; 
      }
    } catch (e) {
      return time;
    }
    return time;
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
      _fetchDoctorsForSelectedDate();
    }
  }

  Future<void> _fetchDoctorsForSelectedDate() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // الحصول على رقم يوم الأسبوع من التاريخ المختار
    final int targetWeekday = _selectedDate.weekday;

    try {
      final List<DoctorModel> allDoctors = await _apiService.getAllDoctors();
      List<DoctorModel> doctorsWithSchedules = [];

      await Future.wait(allDoctors.map((doctor) async {
        try {
          final schedules = await _apiService.getDoctorSchedule(doctor.id);
          final updatedDoctor = DoctorModel(
            id: doctor.id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specializationName: doctor.specializationName,
            experienceYears: doctor.experienceYears,
            biography: doctor.biography,
            consultationFee: doctor.consultationFee,
            dateOfBirth: doctor.dateOfBirth,
            gender: doctor.gender,
            isAppleToAppointment: doctor.isAppleToAppointment,
            profilePictureUrl: doctor.profilePictureUrl,
            doctorSchedules: schedules,
          );
          
          // التأكد من وجود جدول للطبيب في اليوم المختار وأنه متاح
          if (schedules.any((s) => s.isScheduledFor(targetWeekday) && s.isAvailable)) {
            doctorsWithSchedules.add(updatedDoctor);
          }
        } catch (e) {
          debugPrint("Error fetching schedule for doctor ${doctor.id}: $e");
        }
      }));

      if (mounted) {
        setState(() {
          _todayDoctors = doctorsWithSchedules;
          _applySearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in TodayDoctorsPage: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching doctors: $e")),
        );
      }
    }
  }

  void _applySearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredDoctors = _todayDoctors;
      } else {
        _filteredDoctors = _todayDoctors.where((doctor) {
          final fullName = "${doctor.firstName} ${doctor.lastName}".toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase()) || 
                 doctor.specializationName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        title: "Doctors by Day",
        subtitle: DateFormat('EEEE, d MMMM').format(_selectedDate),
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _selectDate(context),
          ),
        ],
        onRefresh: _fetchDoctorsForSelectedDate,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applySearch();
                });
              },
              decoration: InputDecoration(
                hintText: "Search doctors...",
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear), 
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                            _applySearch();
                          });
                        }) 
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchDoctorsForSelectedDate,
                    child: _filteredDoctors.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return _buildDoctorCard(doctor);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? "No doctors available for ${DateFormat('EEEE').format(_selectedDate)}" 
                  : "No results for '$_searchQuery'",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    // جلب موعد اليوم لعرض الوقت بناءً على اليوم المختار
    final int targetWeekday = _selectedDate.weekday;
    final schedule = doctor.doctorSchedules.firstWhere(
      (s) => s.isScheduledFor(targetWeekday),
      orElse: () => doctor.doctorSchedules.isNotEmpty ? doctor.doctorSchedules.first : throw "No schedule found",
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // فتح مواعيد الطبيب مباشرة
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorBookingsDetail(doctor: doctor),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withValues(alpha: 0.1),
                    backgroundImage: doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(doctor.profilePictureUrl!)
                        : null,
                    child: doctor.profilePictureUrl == null || doctor.profilePictureUrl!.isEmpty
                        ? Icon(
                            doctor.gender == "Male" ? Icons.male : Icons.female, 
                            size: 26, 
                            color: doctor.gender == "Male" ? Colors.blue : Colors.pink
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Dr. ${doctor.firstName} ${doctor.lastName}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specializationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryColor.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: Colors.grey.shade500, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
