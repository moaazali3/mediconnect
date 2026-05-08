import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
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
      final List<DoctorModel> doctors = await _apiService.getAllDoctors(pageSize: 1000);
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
      backgroundColor: const Color(0xFFF1F5F9),
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
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchController.clear();
                  setState(() { _searchQuery = ""; _applySearch(); });
                }) 
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: doctor.profilePictureUrl != null ? NetworkImage(doctor.profilePictureUrl!) : null,
          child: doctor.profilePictureUrl == null 
              ? Icon(doctor.gender == "Male" ? Icons.male : Icons.female, color: primaryColor, size: 30) 
              : null,
        ),
        title: Text(
          "Dr. ${doctor.firstName} ${doctor.lastName}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(doctor.specializationName, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.work_history_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text("${doctor.experienceYears.toInt()} Years Exp.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.payments_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text("${doctor.consultationFee.toInt()} EGP", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "No doctors registered yet" : "No results for '$_searchQuery'",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
