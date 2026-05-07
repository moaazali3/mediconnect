import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class EditReceptionistManagementPage extends StatefulWidget {
  final String receptionistId;
  const EditReceptionistManagementPage({super.key, required this.receptionistId});

  @override
  State<EditReceptionistManagementPage> createState() => _EditReceptionistManagementPageState();
}

class _EditReceptionistManagementPageState extends State<EditReceptionistManagementPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _gender = 'Male';
  String? _selectedDoctorId;
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getReceptionistProfile(widget.receptionistId),
        _apiService.getDoctorNames(),
      ]);

      final profile = results[0] as ReceptionistProfileModel;
      _doctors = results[1] as List<Map<String, dynamic>>;

      _fNameController.text = profile.firstName;
      _lNameController.text = profile.lastName;
      _phoneController.text = profile.phoneNumber;
      _emailController.text = profile.email ?? '';
      _dobController.text = profile.dateOfBirth?.split('T')[0] ?? '';
      _addressController.text = profile.address ?? '';
      _gender = profile.gender ?? 'Male';
      
      // منطق اختيار الدكتور المبدئي
      String? foundId = profile.doctorId?.toString();
      if (foundId != null && (foundId.isEmpty || foundId == "0")) foundId = null;

      // التأكد من أن الـ ID موجود في القائمة
      bool idInList = _doctors.any((d) => (d['doctorId']?.toString() ?? d['id']?.toString()) == foundId);

      // إذا لم نجد الـ ID، نبحث بالاسم (مثل doma doma)
      if (!idInList && profile.doctorName != null && profile.doctorName!.isNotEmpty) {
        final String pName = profile.doctorName!.toLowerCase().trim();
        final match = _doctors.firstWhere(
          (d) {
            final String dName = (d['doctorName'] ?? d['name'])?.toString().toLowerCase().trim() ?? "";
            return dName == pName || dName == "dr. $pName" || pName == "dr. $dName";
          },
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          foundId = (match['doctorId'] ?? match['id'])?.toString();
        }
      }

      setState(() {
        _selectedDoctorId = foundId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _updateReceptionist() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final updatedProfile = ReceptionistProfileModel(
        id: widget.receptionistId,
        firstName: _fNameController.text,
        lastName: _lNameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        gender: _gender,
        dateOfBirth: _dobController.text,
        address: _addressController.text,
        doctorId: _selectedDoctorId,
      );

      final success = await _apiService.updateReceptionistProfile(widget.receptionistId, updatedProfile);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receptionist profile updated!"), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          throw "Update failed.";
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // حساب القيمة الحالية للـ Dropdown مع التحقق من وجودها في القائمة
    String? currentDropdownValue;
    if (_selectedDoctorId != null) {
      bool exists = _doctors.any((d) => (d['doctorId']?.toString() ?? d['id']?.toString()) == _selectedDoctorId);
      if (exists) currentDropdownValue = _selectedDoctorId;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CommonAppBar(
        title: "Edit Receptionist",
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.8),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline_rounded, size: 50, color: primaryColor),
                              ),
                              const SizedBox(height: 20),
                              const Text("Update Receptionist",
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                              const SizedBox(height: 35),

                              _buildSectionTitle("PERSONAL INFORMATION"),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(controller: _fNameController, label: "First Name", icon: Icons.person_outline)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildTextField(controller: _lNameController, label: "Last Name", icon: Icons.person_outline)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                              const SizedBox(height: 15),
                              _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField<String>(
                                      label: "Gender",
                                      icon: Icons.wc_rounded,
                                      value: _gender,
                                      items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                      onChanged: (val) => setState(() => _gender = val!),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _dobController,
                                      label: "Birth Date",
                                      icon: Icons.calendar_month_rounded,
                                      readOnly: true,
                                      onTap: () async {
                                        DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(1995),
                                          firstDate: DateTime(1950),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(controller: _addressController, label: "Address", icon: Icons.location_on_outlined),

                              const SizedBox(height: 30),
                              _buildSectionTitle("ASSIGNMENT"),
                              const SizedBox(height: 15),
                              _buildDropdownField<String>(
                                label: "Assigned Doctor",
                                icon: Icons.medical_services_outlined,
                                value: currentDropdownValue,
                                items: _doctors.map((d) {
                                  final id = (d['doctorId'] ?? d['id'])?.toString();
                                  final name = (d['doctorName'] ?? d['name'])?.toString() ?? '';
                                  return DropdownMenuItem(
                                    value: id, 
                                    child: Text("Dr. $name", style: const TextStyle(fontSize: 13))
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedDoctorId = val),
                              ),

                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _updateReceptionist,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5,
                                  ),
                                  child: _isSaving 
                                      ? const CircularProgressIndicator(color: Colors.white) 
                                      : const Text("SAVE CHANGES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: primaryColor.withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white70,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white70,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null ? "Required" : null,
    );
  }
}
