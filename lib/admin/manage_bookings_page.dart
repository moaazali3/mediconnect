import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/patient/screens/profile.dart'; 
import 'package:mediconnect/widgets/common_app_bar.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  final _apiService = ApiService();
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
    const String imageBaseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";

    return Scaffold(
      appBar: const CommonAppBar(
        title: "Manage Bookings",
        showBackButton: true,
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
                            itemCount: _filteredDoctors.length,
                            padding: const EdgeInsets.all(10),
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              
                              String? fullImageUrl;
                              if (doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty) {
                                fullImageUrl = doctor.profilePictureUrl!.startsWith('http') 
                                    ? doctor.profilePictureUrl 
                                    : "$imageBaseUrl${doctor.profilePictureUrl}";
                              }

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: (doctor.gender == "Male" ? Colors.blue : Colors.pink).withOpacity(0.1),
                                    backgroundImage: fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
                                    child: fullImageUrl == null
                                        ? Icon(
                                            doctor.gender == "Male" ? Icons.male : Icons.female, 
                                            color: doctor.gender == "Male" ? Colors.blue : Colors.pink,
                                            size: 25,
                                          )
                                        : null,
                                  ),
                                  title: Text("${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(doctor.specializationName),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DoctorBookingsDetail(doctor: doctor),
                                      ),
                                    ).then((_) => _fetchDoctors()); 
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
          hintText: "Search doctor by name...",
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

class DoctorBookingsDetail extends StatefulWidget {
  final DoctorModel doctor;
  const DoctorBookingsDetail({super.key, required this.doctor});

  @override
  State<DoctorBookingsDetail> createState() => _DoctorBookingsDetailState();
}

class _DoctorBookingsDetailState extends State<DoctorBookingsDetail> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  Future<void> _updateStatus(String id, bool isAccept) async {
    setState(() => _isProcessing = true);
    try {
      bool success;
      if (isAccept) {
        success = await _apiService.completeAppointmentStatus(id);
      } else {
        success = await _apiService.cancelAppointmentStatus(id);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAccept ? "Appointment Accepted!" : "Appointment Cancelled!"),
              backgroundColor: isAccept ? Colors.green : Colors.red,
            ),
          );
          setState(() {}); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const String imageBaseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";
    String? fullImageUrl;
    if (widget.doctor.profilePictureUrl != null && widget.doctor.profilePictureUrl!.isNotEmpty) {
      fullImageUrl = widget.doctor.profilePictureUrl!.startsWith('http') 
          ? widget.doctor.profilePictureUrl 
          : "$imageBaseUrl${widget.doctor.profilePictureUrl}";
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: "Bookings: ${widget.doctor.firstName}",
        showBackButton: true,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<DoctorAppointmentModel>>(
            future: _apiService.getDoctorAppointments(widget.doctor.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No bookings found for this doctor."));
              }

              final appointments = snapshot.data!;
              
              appointments.sort((a, b) {
                int dateCompare = a.appointmentDate.compareTo(b.appointmentDate);
                if (dateCompare != 0) return dateCompare;
                return a.startTime.compareTo(b.startTime);
              });

              return ListView.builder(
                itemCount: appointments.length,
                padding: const EdgeInsets.all(15),
                itemBuilder: (context, index) {
                  final app = appointments[index];
                  final bool isFinalized = app.status == "Completed" || app.status == "Cancelled" || app.status == "Confirmed";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(userId: app.patientId, readOnly: true),
                                    ),
                                  );
                                },
                                child: Text(
                                  app.patientName, 
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16, 
                                    color: primaryColor,
                                    decoration: TextDecoration.underline
                                  )
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(app.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  app.status,
                                  style: TextStyle(
                                    color: _getStatusColor(app.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Date: ${app.appointmentDate}", style: TextStyle(color: Colors.grey[700])),
                                  Text("Time: ${app.startTime} - ${app.endTime}", style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Queue: #${app.queueNumber}",
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (!isFinalized) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Accept"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'completed': 
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }
}
