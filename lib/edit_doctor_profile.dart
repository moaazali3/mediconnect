import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';

class EditDoctorProfile extends StatefulWidget {
  final String? doctorId;
  const EditDoctorProfile({super.key, this.doctorId});

  @override
  State<EditDoctorProfile> createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  final formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool isLoading = true;

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final String targetId = widget.doctorId ?? "1";
      final doctor = await _apiService.getDoctorProfile(targetId);
      setState(() {
        fNameController.text = doctor.firstName;
        lNameController.text = doctor.lastName;
        emailController.text = doctor.email;
        phoneController.text = doctor.phoneNumber;
        addressController.text = doctor.address ?? "";
        bioController.text = doctor.biography;
        dobController.text = doctor.dateOfBirth;
        selectedGender = doctor.gender;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading doctor profile: $e")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final String targetId = widget.doctorId ?? "1";

    // Matching the 7 fields shown in the Swagger image for Doctor PUT
    final Map<String, dynamic> updateData = {
      "firstName": fNameController.text,
      "lastName": lNameController.text,
      "dateOfBirth": dobController.text,
      "gender": selectedGender,
      "address": addressController.text,
      "phoneNumber": phoneController.text,
      "biography": bioController.text,
    };

    final success = await _apiService.updateDoctorProfile(targetId, updateData);

    setState(() => isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor Profile Updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changePassword(String oldP, String newP) async {
    final String targetId = widget.doctorId ?? "1";
    final success = await _apiService.changePassword(targetId, oldP, newP);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to change password. Check old password."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("Edit Doctor Profile", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor,
                        child: CircleAvatar(
                          radius: 47,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.medical_services_rounded, size: 50, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

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
                      _buildEditRow(label: "Phone", controller: phoneController, icon: Icons.phone_android_rounded),
                      _buildDivider(),
                      _buildDropdownField(
                        label: "Gender",
                        icon: Icons.wc_rounded,
                        value: selectedGender,
                        items: ['Male', 'Female'],
                        onChanged: (val) => setState(() => selectedGender = val),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle("Profile Details"),
                    _buildEditCard([
                      _buildEditRow(label: "Clinic Address", controller: addressController, icon: Icons.location_on_outlined),
                      _buildDivider(),
                      _buildEditRow(label: "Biography", controller: bioController, icon: Icons.description_rounded, maxLines: 4),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditRow({required String label, required TextEditingController controller, required IconData icon, bool isReadOnly = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: isReadOnly ? Colors.grey : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: isReadOnly ? null : (value) => (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
        ),
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
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
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
