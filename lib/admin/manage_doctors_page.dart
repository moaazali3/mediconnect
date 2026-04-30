import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/admin/edit_doctor_management_page.dart';

class ManageDoctorsPage extends StatefulWidget {
  const ManageDoctorsPage({super.key});

  @override
  State<ManageDoctorsPage> createState() => _ManageDoctorsPageState();
}

class _ManageDoctorsPageState extends State<ManageDoctorsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<DoctorModel> _allDoctors = [];
  List<DoctorModel> _filteredDoctors = [];
  List<SpecializationModel> _specializations = [];
  
  String _selectedSpec = "All";
  String _searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final specs = await _apiService.getAllSpecializations();
      setState(() {
        _specializations = specs;
      });
      await _fetchDoctors();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    }
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await _apiService.getAllDoctors(specializationName: _selectedSpec);
      setState(() {
        _allDoctors = doctors;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching doctors: $e")),
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
          return fullName.contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Doctors", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchDoctors,
                    child: _filteredDoctors.isEmpty
                        ? const Center(child: Text("No doctors found"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(15),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundImage: doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty
                                        ? NetworkImage(doctor.profilePictureUrl!)
                                        : null,
                                    child: doctor.profilePictureUrl == null || doctor.profilePictureUrl!.isEmpty
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  title: Text("Dr. ${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(doctor.specializationName),
                                  trailing: const Icon(Icons.edit, color: primaryColor),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditDoctorManagementPage(doctorId: doctor.id),
                                      ),
                                    );
                                    if (result == true) _fetchDoctors();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by name...",
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
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applySearch();
          });
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _specializations.length + 1,
        itemBuilder: (context, index) {
          String name = index == 0 ? "All" : _specializations[index - 1].name;
          bool isSelected = _selectedSpec == name;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSpec = name;
                  });
                  _fetchDoctors();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
