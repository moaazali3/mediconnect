import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/patient/widgets/search_bar.dart';
import 'package:mediconnect/patient/widgets/home_banner.dart';
import 'package:mediconnect/patient/widgets/doctor_card.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/constants/shimmer_loading.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final docs = await _apiService.getAllDoctors(specializationName: selectedSpecialization);
      _apiService.cacheDoctorImages(docs); 
      final prefs = await SharedPreferences.getInstance();
      if (selectedSpecialization == "All") {
        await prefs.setString('cached_doctors', json.encode(docs.map((d) => d.toJson()).toList()));
      }
      if (mounted) setState(() { _doctors = docs; _isLoadingDoctors = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredDoctors = List<DoctorModel>.from(_doctors);
    if (searchQuery.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((doc) {
        final fullName = "${doc.firstName} ${doc.lastName}".toLowerCase();
        return fullName.contains(searchQuery);
      }).toList();
    }

    // Sort alphabetically, ignoring the "dr" prefix if it exists
    filteredDoctors.sort((a, b) {
      String nameA = "${a.firstName} ${a.lastName}".toLowerCase();
      String nameB = "${b.firstName} ${b.lastName}".toLowerCase();

      if (nameA.startsWith("dr")) {
        nameA = nameA.substring(2).trim();
        if (nameA.startsWith(".")) nameA = nameA.substring(1).trim();
      }
      if (nameB.startsWith("dr")) {
        nameB = nameB.substring(2).trim();
        if (nameB.startsWith(".")) nameB = nameB.substring(1).trim();
      }

      return nameA.compareTo(nameB);
    });

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        children: [
          if (isOffline)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.redAccent,
              child: const Center(child: Text("Offline Mode", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
          const SizedBox(height: 20),
          SearchBarWidget(onChanged: (value) => setState(() => searchQuery = value.toLowerCase())),
          const SizedBox(height: 20),
          const HomeBanner(),
          const SizedBox(height: 20),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Specializations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          
          _isLoadingSpecs && _specializations.isEmpty 
            ? _buildSpecsShimmer()
            : _buildSpecsList(),

          const SizedBox(height: 20),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Top Doctors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          _isLoadingDoctors && filteredDoctors.isEmpty
            ? _buildDoctorsShimmer()
            : _buildDoctorsList(filteredDoctors),
            
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSpecsShimmer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: List.generate(5, (index) => const Padding(
        padding: EdgeInsets.only(right: 10),
        child: ShimmerLoading.rectangular(height: 40, width: 80),
      ))),
    );
  }

  Widget _buildSpecsList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: List.generate(3, (index) => const DoctorCardShimmer())),
    );
  }

  Widget _buildDoctorsList(List<DoctorModel> docs) {
    if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No doctors found")));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: docs.map((doc) => DoctorCard(
          id: doc.id,
          name: "${doc.firstName} ${doc.lastName}",
          spec: doc.specializationName.isEmpty ? "Specialist" : doc.specializationName,
          gender: doc.gender,
          experience: doc.experienceYears,
          imageUrl: doc.profilePictureUrl,
          patientId: widget.userId,
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
          _fetchDoctors();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
        ),
        child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
