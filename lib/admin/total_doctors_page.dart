import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/DoctorModel.dart';
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
  
  List<DoctorModel> _allDoctors = [];
  List<DoctorModel> _filteredDoctors = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchAllDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllDoctors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<DoctorModel> doctors = await _apiService.getAllDoctorsForAdmin();
      
      // Sort by experience years (Descending)
      doctors.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));

      if (mounted) {
        setState(() {
          _allDoctors = doctors;
          _applySearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching doctors: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _applySearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredDoctors = _allDoctors;
      } else {
        _filteredDoctors = _allDoctors.where((doctor) {
          final fullName = "${doctor.firstName} ${doctor.lastName}".toLowerCase();
          final spec = doctor.specializationName.toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase()) || spec.contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: CommonAppBar(
        title: "All Doctors",
        subtitle: "${_allDoctors.length} Total Registered",
        showBackButton: true,
        onRefresh: _fetchAllDoctors,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchAllDoctors,
                    color: primaryColor,
                    child: _filteredDoctors.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) => _buildDoctorCard(_filteredDoctors[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applySearch();
          });
        },
        decoration: InputDecoration(
          hintText: "Search by name or specialization...",
          hintStyle: TextStyle(color: context.subText.withValues(alpha: 0.7), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () {
                  _searchController.clear();
                  setState(() { _searchQuery = ""; _applySearch(); });
                }) 
              : null,
          filled: true,
          fillColor: context.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture with Double Thin Border to match image
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.dividerCol, width: 0.8),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.dividerCol, width: 0.8),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: context.scaffoldBg,
                backgroundImage: (doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty)
                    ? NetworkImage(doctor.profilePictureUrl!)
                    : null,
                child: (doctor.profilePictureUrl == null || doctor.profilePictureUrl!.isEmpty)
                    ? const Icon(
                        Icons.person,
                        color: primaryColor,
                        size: 30,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Fix for overflow
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Dr. ${doctor.firstName} ${doctor.lastName}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: doctor.isAppleToAppointment 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: doctor.isAppleToAppointment 
                              ? Colors.green.withValues(alpha: 0.3) 
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        doctor.isAppleToAppointment ? "Active" : "Inactive",
                        style: TextStyle(
                          color: doctor.isAppleToAppointment ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.category_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      doctor.specializationName,
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.work_history_outlined, size: 14, color: context.subText),
                    const SizedBox(width: 4),
                    Text("${doctor.experienceYears.toInt()} Years Exp.", style: TextStyle(color: context.subText, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 80, color: context.subText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No doctors registered yet" : "No results for '$_searchQuery'",
            style: TextStyle(color: context.subText, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
