import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/doctor_profile_screen.dart';
import 'package:mediconnect/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? userRole;

  const HomeScreen({super.key, this.userId, this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String selectedSpecializationName = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBox(),
            _buildSpecializationsSection(),
            _buildDoctorsSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello,", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const Text("Welcome to MediConnect", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        // زر الانتقال للبروفايل
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_outline, color: primaryColor, size: 22),
          ),
          onPressed: () {
            if (widget.userId != null) {
              if (widget.userRole == "doctor") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorProfileScreen(doctorId: widget.userId!)),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(patientId: widget.userId!)),
                );
              }
            }
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Looking for\nYour Doctor?",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Book Now"),
                )
              ],
            ),
          ),
          const Icon(Icons.medical_services_outlined, size: 80, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: "Search your doctor...",
            border: InputBorder.none,
            icon: Icon(Icons.search, color: primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecializationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Text("Specializations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        FutureBuilder<List<SpecializationModel>>(
          future: _apiService.getAllSpecializations(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 50);
            final specs = snapshot.data!;
            return SizedBox(
              height: 45,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                scrollDirection: Axis.horizontal,
                itemCount: specs.length + 1,
                itemBuilder: (context, index) {
                  bool isAll = index == 0;
                  String specName = isAll ? "All" : specs[index - 1].name;
                  bool isSelected = selectedSpecializationName == specName;

                  return GestureDetector(
                    onTap: () => setState(() => selectedSpecializationName = specName),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          specName,
                          style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Text("Top Doctors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        FutureBuilder<List<DoctorModel>>(
          future: _apiService.getAllDoctors(specializationName: selectedSpecializationName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${snapshot.error}")));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No doctors found")));
            }

            final doctors = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return _buildDoctorCard(doctor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              doctor.gender == "Male" ? Icons.male : Icons.female,
              color: doctor.gender == "Male" ? Colors.blue : Colors.pink,
              size: 35,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dr. ${doctor.firstName} ${doctor.lastName}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("${doctor.experienceYears} Years Experience",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    const Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorProfileScreen(doctorId: doctor.id),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text("View Profile", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          Icon(Icons.arrow_forward, color: primaryColor, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
