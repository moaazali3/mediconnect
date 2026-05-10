import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
      backgroundColor: context.scaffoldBg,
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
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final dummyPatient = PatientProfileModel(
                          id: "dummy",
                          firstName: "Loading",
                          lastName: "Name",
                          email: "loading@loading.com",
                          phoneNumber: "0000000000",
                          dateOfBirth: "2000-01-01",
                          gender: "Male",
                          bloodType: "O+",
                          height: 170.0,
                          weight: 70.0,
                          emergencyContact: "0000000000",
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
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
                                    backgroundColor: primaryColor.withOpacity(0.15),
                                    child: const Icon(Icons.person_rounded, color: primaryColor, size: 30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${dummyPatient.firstName} ${dummyPatient.lastName}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: context.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
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
          hintStyle: TextStyle(color: context.subText.withValues(alpha: 0.7), fontSize: 14),
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
              Icon(Icons.person_search_rounded, size: 80, color: context.subText.withValues(alpha: 0.5)),
              const SizedBox(height: 15),
              Text(
                _searchQuery.isEmpty ? "No patients found" : "No results for '$_searchQuery'", 
                style: TextStyle(color: context.subText, fontSize: 16)
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
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.03),
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
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : primaryColor.withOpacity(0.15),
                    child: Icon(
                      Icons.person_rounded, 
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor, 
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.onSurface,
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
