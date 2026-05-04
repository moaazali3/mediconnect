import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class TotalDoctorsPage extends StatefulWidget {
  const TotalDoctorsPage({super.key});

  @override
  State<TotalDoctorsPage> createState() => _TotalDoctorsPageState();
}

class _TotalDoctorsPageState extends State<TotalDoctorsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<SpecializationModel> _specializations = [];
  Map<String, List<DoctorModel>> _doctorsBySpec = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getAllSpecializations(),
        _apiService.getAllDoctors(pageSize: 500),
      ]);

      final specs = results[0] as List<SpecializationModel>;
      final doctors = results[1] as List<DoctorModel>;

      Map<String, List<DoctorModel>> grouped = {};
      for (var spec in specs) {
        grouped[spec.name] = doctors.where((d) => d.specializationName == spec.name).toList();
      }

      if (mounted) {
        setState(() {
          _specializations = specs;
          _doctorsBySpec = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: CommonAppBar(
        title: "System Doctors",
        subtitle: "View Directory",
        showBackButton: true,
        onRefresh: _loadData,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _buildSpecializationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Find a doctor in the system...",
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear), 
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
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
    );
  }

  Widget _buildSpecializationList() {
    final filteredSpecs = _specializations.where((spec) {
      final doctors = _doctorsBySpec[spec.name] ?? [];
      if (_searchQuery.isEmpty) return doctors.isNotEmpty;
      return doctors.any((d) => "${d.firstName} ${d.lastName}".toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    if (filteredSpecs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text("No doctors match your search", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSpecs.length,
      itemBuilder: (context, index) {
        final spec = filteredSpecs[index];
        var doctors = _doctorsBySpec[spec.name] ?? [];
        
        if (_searchQuery.isNotEmpty) {
          doctors = doctors.where((d) => 
            "${d.firstName} ${d.lastName}".toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.medical_services_rounded, color: primaryColor, size: 24),
              ),
              title: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3142))),
              subtitle: Text("${doctors.length} Registered Doctors", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              childrenPadding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
              children: doctors.map((doctor) => _buildDoctorItem(doctor)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorItem(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withOpacity(0.1), width: 1)),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
            backgroundImage: doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty
                ? NetworkImage(doctor.profilePictureUrl!)
                : null,
            child: doctor.profilePictureUrl == null || doctor.profilePictureUrl!.isEmpty
                ? Icon(doctor.gender == "Male" ? Icons.male : Icons.female, 
                    size: 22, color: doctor.gender == "Male" ? Colors.blue : Colors.pink)
                : null,
          ),
        ),
        title: Text("Dr. ${doctor.firstName} ${doctor.lastName}", 
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        subtitle: Text("${doctor.experienceYears.toStringAsFixed(0)} years experience", 
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        // تم حذف trailing و onTap لجعل القائمة للعرض فقط
      ),
    );
  }
}
