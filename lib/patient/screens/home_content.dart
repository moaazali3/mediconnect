import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/patient/widgets/doctor_card.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/constants/shimmer_loading.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconnect/patient/screens/booking_screen.dart';

class HomeContent extends StatefulWidget {
  final String? userId;
  const HomeContent({super.key, this.userId});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ApiService _apiService = ApiService();
  String selectedSpecialization = "All";
  String searchQuery = "";

  List<SpecializationModel> _specializations = [];
  List<DoctorModel> _doctors = [];
  bool _isLoadingDoctors = true;
  bool _isLoadingSpecs = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadCachedData();
    _refreshData();
  }

  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool offline = results.contains(ConnectivityResult.none);
      if (mounted && isOffline != offline) {
        setState(() => isOffline = offline);
        if (isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are offline. Showing cached data.")),
          );
        } else {
          _refreshData();
        }
      }
    });
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSpecs = prefs.getString('cached_specs');
    final cachedDoctors = prefs.getString('cached_doctors');

    if (mounted) {
      setState(() {
        if (cachedSpecs != null) {
          Iterable l = json.decode(cachedSpecs);
          _specializations = List<SpecializationModel>.from(l.map((model) => SpecializationModel.fromJson(model)));
          _isLoadingSpecs = false;
        }
        if (cachedDoctors != null) {
          Iterable l = json.decode(cachedDoctors);
          _doctors = List<DoctorModel>.from(l.map((model) => DoctorModel.fromJson(model)));
          _apiService.cacheDoctorImages(_doctors);
          _isLoadingDoctors = false;
        }
      });
    }
  }

  Future<void> _refreshData() async {
    _fetchSpecializations();
    _fetchDoctors();
  }

  Future<void> _fetchSpecializations() async {
    try {
      final specs = await _apiService.getAllSpecializations();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_specs', json.encode(specs.map((s) => s.toJson()).toList()));
      if (mounted) setState(() { _specializations = specs; _isLoadingSpecs = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingSpecs = false);
    }
  }

  Future<void> _fetchDoctors() async {
    if (mounted) setState(() => _isLoadingDoctors = true);
    try {
      final docs = await _apiService.getAllDoctors(specializationName: "All");
      _apiService.cacheDoctorImages(docs);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_doctors', json.encode(docs.map((d) => d.toJson()).toList()));
      if (mounted) setState(() { _doctors = docs; _isLoadingDoctors = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredDoctors = List<DoctorModel>.from(_doctors);

    // 1. فلترة بالتخصص
    if (selectedSpecialization != "All") {
      filteredDoctors = filteredDoctors.where((doc) {
        return doc.specializationName.trim().toLowerCase() == selectedSpecialization.trim().toLowerCase();
      }).toList();
    }

    // 2. فلترة بالبحث
    if (searchQuery.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((doc) {
        final fullName = "${doc.firstName} ${doc.lastName}".toLowerCase();
        return fullName.contains(searchQuery);
      }).toList();
    }

    // 3. الترتيب (حسب سنين الخبرة من الأكبر للأصغر)
    filteredDoctors.sort((a, b) {
      return b.experienceYears.compareTo(a.experienceYears);
    });

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: primaryColor,
      child: ListView(
        padding: EdgeInsets.zero, // عشان الهيدر يلمس حافة الشاشة من فوق
        children: [
          if (isOffline)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.redAccent,
              child: const Center(child: Text("Offline Mode", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ),

          // --- التصميم الاحترافي الجديد للهيدر ---
          _buildModernHeader(),

          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Specializations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 15),

          _isLoadingSpecs && _specializations.isEmpty
              ? _buildSpecsShimmer()
              : _buildSpecsList(),

          const SizedBox(height: 30),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Top Doctors",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),

          _isLoadingDoctors && filteredDoctors.isEmpty && selectedSpecialization == "All" && searchQuery.isEmpty
              ? _buildDoctorsShimmer()
              : _buildDoctorsList(filteredDoctors),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- دالة تصميم الهيدر الجديد بعد التعديل ---
  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شيلنا الإشعارات وغيرنا الكلمة لـ Doctor
          const Text("Hello,", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 5),
          const Text("Find Your Doctor", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),

          const SizedBox(height: 30),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: context.inputFill,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              style: TextStyle(
                fontSize: 15,
                color: context.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "Search doctor by name...",
                hintStyle: TextStyle(
                  color: context.subText,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsShimmer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: List.generate(5, (index) => const Padding(
        padding: EdgeInsets.only(right: 12),
        child: ShimmerLoading.rectangular(height: 45, width: 90),
      ))),
    );
  }

  Widget _buildSpecsList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildSpecItem("All"),
          ..._specializations.map((s) => _buildSpecItem(s.name)),
        ],
      ),
    );
  }

  Widget _buildDoctorsShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: List.generate(3, (index) => const Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: DoctorCardShimmer(),
      ))),
    );
  }

  Widget _buildDoctorsList(List<DoctorModel> docs) {
    if (docs.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: context.subText.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text("No doctors found", style: TextStyle(color: context.subText)),
                ],
              )
          )
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: docs.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: DoctorCard(
            doctor: doc,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(
                    doctorId: doc.id,
                    doctorName: "Dr. ${doc.firstName} ${doc.lastName}",
                    specialty: doc.specializationName,
                    fee: doc.consultationFee.toString(),
                    doctorImageUrl: doc.profilePictureUrl,
                    patientId: widget.userId,
                  ),
                ),
              );
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSpecItem(String title) {
    bool isSelected = selectedSpecialization == title;
    return GestureDetector(
      onTap: () {
        if (selectedSpecialization != title) {
          setState(() => selectedSpecialization = title);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : context.filterChipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : context.filterChipBorder,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : context.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}