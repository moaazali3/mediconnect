import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class TotalPatientsPage extends StatefulWidget {
  const TotalPatientsPage({super.key});

  @override
  State<TotalPatientsPage> createState() => _TotalPatientsPageState();
}

class _TotalPatientsPageState extends State<TotalPatientsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<PatientProfileModel> _patients = [];
  List<PatientProfileModel> _filteredPatients = [];
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
      final List<PatientProfileModel> patients = await _apiService.getAllPatients();
      
      final Set<String> seenNames = {};
      final List<PatientProfileModel> uniquePatients = [];
      
      for (var p in patients) {
        final fullName = "${p.firstName} ${p.lastName}".toLowerCase().trim();
        if (!seenNames.contains(fullName)) {
          seenNames.add(fullName);
          uniquePatients.add(p);
        }
      }

      // Sort unique patients alphabetically by first name then last name
      uniquePatients.sort((a, b) {
        final nameA = "${a.firstName} ${a.lastName}".toLowerCase();
        final nameB = "${b.firstName} ${b.lastName}".toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _patients = uniquePatients;
          _applySearch();
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

  void _applySearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((p) {
          final fullName = "${p.firstName} ${p.lastName}".toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CommonAppBar(
        title: "System Patients",
        subtitle: "${_filteredPatients.length} Total Patients",
        showBackButton: true,
        onRefresh: _loadData,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: primaryColor,
                    child: _buildPatientList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applySearch();
          });
        },
        decoration: InputDecoration(
          hintText: "Search patients by name...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20), 
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                      _applySearch();
                    });
                  }) 
              : null,
          filled: true,
          fillColor: context.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    if (_filteredPatients.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 15),
              Text(
                _searchQuery.isEmpty ? "No patients found" : "No results for '$_searchQuery'", 
                style: TextStyle(color: Colors.grey[600], fontSize: 16)
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Patient Profile Picture with Double Thin Border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.15), width: 0.8),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.1), width: 0.8),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Icon(
                      patient.gender.toLowerCase() == "female" ? Icons.female : Icons.male, 
                      color: primaryColor, 
                      size: 30
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // Patient Info with Overflow protection
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${patient.firstName} ${patient.lastName}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
