import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditReceptionistProfile extends StatefulWidget {
  final String? userId;
  const EditReceptionistProfile({super.key, this.userId});

  @override
  State<EditReceptionistProfile> createState() => _EditReceptionistProfileState();
}

class _EditReceptionistProfileState extends State<EditReceptionistProfile> {
  final formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool isLoading = true;

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final doctorController = TextEditingController();

  ReceptionistProfileModel? _originalProfile;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String targetId = widget.userId ?? prefs.getString('user_id') ?? "1";
      final profile = await _apiService.getReceptionistProfile(targetId);

      setState(() {
        _originalProfile = profile;
        fNameController.text = profile.firstName;
        lNameController.text = profile.lastName;
        emailController.text = profile.email;
        phoneController.text = profile.phoneNumber;
        dobController.text = profile.dateOfBirth ?? '';
        doctorController.text = profile.doctorName != null && profile.doctorName!.isNotEmpty ? "Dr. ${profile.doctorName}" : "Not Assigned";
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String targetId = widget.userId ?? prefs.getString('user_id') ?? "1";

      final ReceptionistProfileModel updatedProfile = ReceptionistProfileModel(
        id: targetId,
        firstName: fNameController.text,
        lastName: lNameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
        address: _originalProfile?.address ?? '',
        dateOfBirth: dobController.text, // التعديل في تاريخ الميلاد بيسمع في السن
        gender: _originalProfile?.gender ?? '',
        doctorName: _originalProfile?.doctorName ?? '',
      );

      final success = await _apiService.updateReceptionistProfile(targetId, updatedProfile);

      setState(() => isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // يرجع لشاشة العرض ويديلها إشارة إن التعديل تم
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _changePassword(String oldP, String newP) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String targetId = widget.userId ?? prefs.getString('user_id') ?? "1";
      final success = await _apiService.changePassword(targetId, oldP, newP);
      setState(() => isLoading = false);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to change password. Check old password."), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
        children: [
          _buildFixedHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Personal Information"),
                    _buildEditCard([
                      _buildEditRow(label: "Email (Read Only)", controller: emailController, icon: Icons.email_outlined, isReadOnly: true),
                      _buildDivider(),
                      Row(
                        children: [
                          Expanded(child: _buildEditRow(label: "First Name", controller: fNameController, icon: Icons.person_outline)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildEditRow(label: "Last Name", controller: lNameController, icon: Icons.person_outline)),
                        ],
                      ),
                      _buildDivider(),
                      _buildEditRow(
                        label: "Birth Date",
                        controller: dobController,
                        icon: Icons.calendar_month_rounded,
                        isReadOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(dobController.text) ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => dobController.text = DateFormat('yyyy-MM-dd').format(picked));
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 20),

                    _buildSectionTitle("Work Details"),
                    _buildEditCard([
                      _buildEditRow(label: "Phone", controller: phoneController, icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                      _buildDivider(),
                      _buildEditRow(label: "Assigned Doctor (Read Only)", controller: doctorController, icon: Icons.medical_services_outlined, isReadOnly: true),
                    ]),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _updateProfile,
                        icon: const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                        label: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: TextButton(
                        onPressed: () => _showChangePasswordDialog(context),
                        child: const Text("Change Password", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 20),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.face_3_rounded, size: 40, color: primaryColor),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${fNameController.text} ${lNameController.text}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text("Edit Profile Info", style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildEditCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditRow({required String label, required TextEditingController controller, required IconData icon, bool isReadOnly = false, TextInputType keyboardType = TextInputType.text, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: TextStyle(color: isReadOnly && onTap == null ? Colors.grey : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isReadOnly && onTap == null ? Colors.black54 : Colors.black54, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: isReadOnly && onTap == null ? null : (value) => (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 45, endIndent: 15, color: Colors.grey.shade100);
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final passKey = GlobalKey<FormState>();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          content: Form(
            key: passKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupField(controller: oldPass, label: "Old Password", icon: Icons.lock_outline, isObscured: isObscured),
                const SizedBox(height: 10),
                _buildPopupField(
                  controller: newPass,
                  label: "New Password",
                  icon: Icons.lock_reset_rounded,
                  isObscured: isObscured,
                  suffix: IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                    onPressed: () => setModalState(() => isObscured = !isObscured),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (passKey.currentState!.validate()) {
                  _changePassword(oldPass.text, newPass.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupField({required TextEditingController controller, required String label, required IconData icon, bool isObscured = false, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}
