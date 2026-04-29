import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/patient/widgets/search_bar.dart';
import 'package:mediconnect/patient/widgets/home_banner.dart';
import 'package:mediconnect/patient/widgets/doctor_card.dart';
import 'package:mediconnect/services/api_service.dart';

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
  
  late Future<List<SpecializationModel>> _specializationsFuture;
  late Future<List<DoctorModel>> _doctorsFuture;

  @override
  void initState() {
    super.initState();
    // Store futures in state variables to prevent unnecessary re-fetching on rebuilds (like search)
    _specializationsFuture = _apiService.getAllSpecializations();
    _fetchDoctors();
  }

  void _fetchDoctors() {
    setState(() {
      _doctorsFuture = _apiService.getAllDoctors(specializationName: selectedSpecialization);
    });
  }

  void _onSpecializationTapped(String name) {
    if (selectedSpecialization != name) {
      setState(() {
        selectedSpecialization = name;
        _fetchDoctors();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        SearchBarWidget(
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 20),
        const HomeBanner(),
        const SizedBox(height: 20),
        
        // --- Specializations Section ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Specializations",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        
        FutureBuilder<List<SpecializationModel>>(
          future: _specializationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 50, 
                child: Center(child: CircularProgressIndicator(strokeWidth: 2))
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 12)),
              );
            }

            final specs = snapshot.data ?? [];
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildSpecItem("All"),
                  ...specs.map((s) => _buildSpecItem(s.name)),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        
        // --- Doctors Section ---
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Top Doctors",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<DoctorModel>>(
          future: _doctorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: primaryColor),
              ));
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Error loading doctors: ${snapshot.error}", textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _fetchDoctors, child: const Text("Retry")),
                  ],
                ),
              ));
            }
            
            var doctors = snapshot.data ?? [];
            
            // Apply search filter locally to prevent flashing/re-fetching
            if (searchQuery.isNotEmpty) {
              doctors = doctors.where((doc) {
                final fullName = "${doc.firstName} ${doc.lastName}".toLowerCase();
                return fullName.contains(searchQuery);
              }).toList();
            }

            if (doctors.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text("No doctors found"),
              ));
            }

            return Column(
              children: doctors.map<Widget>((doc) => DoctorCard(
                id: doc.id,
                name: "${doc.firstName} ${doc.lastName}",
                spec: selectedSpecialization == "All" ? "Doctor" : selectedSpecialization,
                gender: doc.gender,
                experience: doc.experienceYears,
                patientId: widget.userId,
              )).toList()
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSpecItem(String title) {
    bool isSelected = selectedSpecialization == title;
    return GestureDetector(
      onTap: () => _onSpecializationTapped(title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
