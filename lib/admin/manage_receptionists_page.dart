import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:mediconnect/constants/api_constants.dart';
import 'package:mediconnect/admin/edit_receptionist_management_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ManageReceptionistsPage extends StatefulWidget {
  const ManageReceptionistsPage({super.key});

  @override
  State<ManageReceptionistsPage> createState() => _ManageReceptionistsPageState();
}

class _ManageReceptionistsPageState extends State<ManageReceptionistsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ReceptionistProfileModel> _allReceptionists = [];
  List<ReceptionistProfileModel> _filteredReceptionists = [];
  
  String _searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final List<DoctorModel> doctors = await _apiService.getAllDoctorsForAdmin();
      List<ReceptionistProfileModel> receptionists = [];
      
      final List<ReceptionistProfileModel?> results = await Future.wait(
        doctors.map((doc) => _apiService.getReceptionistByDoctorId(doc.id))
      );

      for (var res in results) {
        if (res != null) {
          receptionists.add(res);
        }
      }

      if (mounted) {
        setState(() {
          _allReceptionists = receptionists;
          _applySearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _applySearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredReceptionists = _allReceptionists;
      } else {
        _filteredReceptionists = _allReceptionists.where((rec) {
          final fullName = "${rec.firstName} ${rec.lastName}".toLowerCase();
          final docName = (rec.doctorName ?? "").toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase()) || 
                 docName.contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _confirmDelete(ReceptionistProfileModel receptionist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
            ),
            const SizedBox(height: 15),
            const Text(
              "Delete Receptionist",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF263238)),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete ${receptionist.firstName} ${receptionist.lastName}?\nThis action cannot be undone.",
          textAlign: TextAlign.center,
          style: TextStyle(color: context.subText, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: context.dividerCol),
                  ),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(color: context.subText, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "DELETE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && receptionist.id != null) {
      _deleteReceptionist(receptionist.id!);
    }
  }

  Future<void> _deleteReceptionist(String id) async {
    setState(() => _isLoading = true);
    try {
      final success = await _apiService.deleteReceptionist(id);
      if (success) {
        _fetchData();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete")));
        }
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
      backgroundColor: context.scaffoldBg,
      appBar: CommonAppBar(
        title: "Manage Receptionists",
        showBackButton: true,
        onRefresh: _fetchData,
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildSearchBar(),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: 4,
                      itemBuilder: (context, index) => _buildReceptionistCard(ReceptionistProfileModel(
                        id: "dummy",
                        firstName: "Loading",
                        lastName: "Name",
                        email: "loading@loading.com",
                        phoneNumber: "0000000000",
                        doctorId: "dummy",
                        doctorName: "Loading Name",
                        dateOfBirth: "2000-01-01",
                      )),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: _filteredReceptionists.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: context.subText.withValues(alpha: 0.5)),
                                const SizedBox(height: 15),
                                Text("No receptionists found", style: TextStyle(color: context.subText)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: _filteredReceptionists.length,
                            itemBuilder: (context, index) => _buildReceptionistCard(_filteredReceptionists[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applySearch();
          });
        },
        decoration: InputDecoration(
          hintText: "Search by name or doctor...",
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
          fillColor: context.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildReceptionistCard(ReceptionistProfileModel receptionist) {
    String? fullImageUrl;
    if (receptionist.profilePictureUrl != null && receptionist.profilePictureUrl!.isNotEmpty) {
      fullImageUrl = receptionist.profilePictureUrl!.startsWith('http') 
          ? receptionist.profilePictureUrl 
          : "${ApiConstants.serverUrl}${receptionist.profilePictureUrl}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.1), width: 1),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
              child: fullImageUrl == null
                  ? const Icon(Icons.person, size: 30, color: primaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${receptionist.firstName} ${receptionist.lastName}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined, color: context.subText, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Assigned to: Dr. ${receptionist.doctorName ?? 'N/A'}",
                        style: TextStyle(
                          color: context.subText,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, color: primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        receptionist.phoneNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.onSurface,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditReceptionistManagementPage(receptionistId: receptionist.id!),
                    ),
                  );
                  if (result == true) _fetchData();
                },
                icon: const Icon(Icons.edit, color: primaryColor, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmDelete(receptionist),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
