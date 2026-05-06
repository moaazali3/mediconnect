import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceptionistProfilePage extends StatefulWidget {
  final String? userId;
  const ReceptionistProfilePage({super.key, this.userId});

  @override
  State<ReceptionistProfilePage> createState() => _ReceptionistProfilePageState();
}

class _ReceptionistProfilePageState extends State<ReceptionistProfilePage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isEditMode = false;
  ReceptionistProfileModel? _profile;

  // Controllers for editing
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _dobController = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = widget.userId ?? prefs.getString('user_id') ?? "1";
      final profile = await _apiService.getReceptionistProfile(id);
      
      setState(() {
        _profile = profile;
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber;
        _addressController.text = profile.address ?? '';
        _dobController.text = profile.dateOfBirth ?? '';
        _selectedGender = profile.gender;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = widget.userId ?? prefs.getString('user_id') ?? "1";
      
      final updatedProfile = ReceptionistProfileModel(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        dateOfBirth: _dobController.text,
        gender: _selectedGender ?? '',
        doctorName: _profile?.doctorName,
      );

      final success = await _apiService.updateReceptionistProfile(id, updatedProfile);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
          );
        }
        await _fetchProfile();
        setState(() => _isEditMode = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 25),
              _buildSectionTitle("Personal Information"),
              _buildProfileCard([
                _buildInfoField(Icons.person_outline, "First Name", _firstNameController, isEditable: _isEditMode),
                _buildDivider(),
                _buildInfoField(Icons.person_outline, "Last Name", _lastNameController, isEditable: _isEditMode),
                _buildDivider(),
                _buildInfoField(Icons.email_outlined, "Email", _emailController, isEditable: false),
                _buildDivider(),
                _buildInfoField(Icons.phone_android_rounded, "Phone", _phoneController, isEditable: _isEditMode),
              ]),
              const SizedBox(height: 25),
              _buildSectionTitle("Work Details"),
              _buildProfileCard([
                _buildInfoField(Icons.badge_outlined, "Assigned Doctor", TextEditingController(text: _profile?.doctorName ?? "N/A"), isEditable: false),
                _buildDivider(),
                _buildGenderDropdown(),
                _buildDivider(),
                _buildInfoField(Icons.location_on_outlined, "Address", _addressController, isEditable: _isEditMode),
                _buildDivider(),
                _buildDatePickerField(),
              ]),
              const SizedBox(height: 30),
              _buildActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(
              _selectedGender == "Male" ? Icons.face_rounded : Icons.face_3_rounded, 
              size: 45, 
              color: primaryColor
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_profile?.firstName} ${_profile?.lastName}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Text(
                  "Medical Receptionist",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoField(IconData icon, String label, TextEditingController controller, {required bool isEditable}) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: isEditable 
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                  validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(controller.text, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wc_rounded, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _isEditMode
              ? DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val),
                  decoration: const InputDecoration(
                    labelText: "Gender",
                    labelStyle: TextStyle(color: Colors.black54, fontSize: 13),
                    border: InputBorder.none,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gender", style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(_selectedGender ?? "Not Specified", style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cake_rounded, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _isEditMode
              ? TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    labelStyle: TextStyle(color: Colors.black54, fontSize: 13),
                    border: InputBorder.none,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Date of Birth", style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(_dobController.text, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_isEditMode) {
                _saveProfile();
              } else {
                setState(() => _isEditMode = true);
              }
            },
            icon: Icon(_isEditMode ? Icons.check_circle_rounded : Icons.edit_note_rounded),
            label: Text(_isEditMode ? "SAVE CHANGES" : "EDIT PROFILE", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditMode ? Colors.green : primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
            ),
          ),
        ),
        if (_isEditMode) ...[
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _isEditMode = false),
              icon: const Icon(Icons.close_rounded),
              label: const Text("CANCEL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.shade100);
  }
}
