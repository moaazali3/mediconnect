import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/admin/edit_doctor_management_page.dart';
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
  
  final int _currentWeekday = DateTime.now().weekday;
  final String _todayNameEn = DateFormat('EEEE', 'en_US').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchTodayDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayDoctors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // 1. جلب جميع الدكاترة
      final List<DoctorModel> allDoctors = await _apiService.getAllDoctors();
      List<DoctorModel> doctorsWithSchedules = [];

      // 2. جلب جداول المواعيد لكل دكتور (لأن قائمة getAllDoctors قد لا تحتوي عليها)
      // نستخدم Future.wait لتسريع العملية
      await Future.wait(allDoctors.map((doctor) async {
        try {
          final schedules = await _apiService.getDoctorSchedule(doctor.id);
          // إنشاء نسخة جديدة من الدكتور تحتوي على الجداول
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
          
          // التحقق مما إذا كان الدكتور متاحاً اليوم
          if (schedules.any((s) => s.isScheduledFor(_currentWeekday) && s.isAvailable)) {
            doctorsWithSchedules.add(updatedDoctor);
          }
        } catch (e) {
          print("Error fetching schedule for doctor ${doctor.id}: $e");
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
      print("Error in TodayDoctorsPage: $e");
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
        title: "Doctors Today",
        subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
        showBackButton: true,
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
                hintText: "Search today's doctors...",
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
                    onRefresh: _fetchTodayDoctors,
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
              _searchQuery.isEmpty ? "No doctors available today" : "No results for '$_searchQuery'",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Tip: Ensure doctors have a 'Work Schedule' set for $_todayNameEn.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    // جلب موعد اليوم لعرض الوقت
    final schedule = doctor.doctorSchedules.firstWhere(
      (s) => s.isScheduledFor(_currentWeekday),
      orElse: () => doctor.doctorSchedules.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditDoctorManagementPage(doctorId: doctor.id),
              ),
            );
            if (result == true) _fetchTodayDoctors();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
                        backgroundImage: doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty
                            ? NetworkImage(doctor.profilePictureUrl!)
                            : null,
                        child: doctor.profilePictureUrl == null || doctor.profilePictureUrl!.isEmpty
                            ? Icon(
                                doctor.gender == "Male" ? Icons.male : Icons.female, 
                                size: 30, 
                                color: doctor.gender == "Male" ? Colors.blue : Colors.pink
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 16,
                        width: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. ${doctor.firstName} ${doctor.lastName}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specializationName,
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: Colors.grey.shade500, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${schedule.startTime} - ${schedule.endTime}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
