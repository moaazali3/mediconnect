import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:intl/intl.dart';

class EditPatientProfile extends StatefulWidget {
  final String? userId;
  const EditPatientProfile({super.key, this.userId});

  @override
  State<EditPatientProfile> createState() => _EditPatientProfileState();
}

class _EditPatientProfileState extends State<EditPatientProfile> {
  final formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool isLoading = true;

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final emergencyController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedBloodType;
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final String targetId = widget.userId ?? "1";
      print("Loading Profile for Patient ID: $targetId");
      final profile = await _apiService.getPatientProfile(targetId);
      setState(() {
        fNameController.text = profile.firstName;
        lNameController.text = profile.lastName;
        emailController.text = profile.email;
        phoneController.text = profile.phoneNumber;
        addressController.text = profile.address ?? "";
        weightController.text = profile.weight.toString();
        heightController.text = profile.height.toString();
        emergencyController.text = profile.emergencyContact;
        dobController.text = profile.dateOfBirth;
        selectedBloodType = profile.bloodType;
        selectedGender = profile.gender;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final String targetId = widget.userId ?? "1";
    print("Updating Profile for Patient ID: $targetId");

    final PatientProfileModel updatedProfile = PatientProfileModel(
      firstName: fNameController.text,
      lastName: lNameController.text,
      email: emailController.text,
      dateOfBirth: dobController.text,
      gender: selectedGender ?? '',
      address: addressController.text,
      bloodType: selectedBloodType ?? '',
      height: double.tryParse(heightController.text) ?? 0,
      weight: double.tryParse(weightController.text) ?? 0,
      emergencyContact: emergencyController.text,
      phoneNumber: phoneController.text,
    );

    try {
      final success = await _apiService.updatePatientProfile(targetId, updatedProfile);
      setState(() => isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changePassword(String oldP, String newP) async {
    setState(() => isLoading = true);
    final String targetId = widget.userId ?? "1";
    try {
      final success = await _apiService.changePassword(targetId, oldP, newP);
      setState(() => isLoading = false);
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
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
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
                          child: Icon(Icons.person_rounded, size: 55, color: primaryColor),
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: "Gender",
                              icon: Icons.wc_rounded,
                              value: selectedGender,
                              items: ['Male', 'Female'],
                              onChanged: (val) => setState(() => selectedGender = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildEditRow(
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
                          ),
                        ],
                      ),
                      _buildDivider(),
                      _buildEditRow(label: "Address", controller: addressController, icon: Icons.location_on_outlined),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle("Medical Background"),
                    _buildEditCard([
                      Row(
                        children: [
                          Expanded(child: _buildEditRow(label: "Height (cm)", controller: heightController, icon: Icons.height_rounded, keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildEditRow(label: "Weight (kg)", controller: weightController, icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                        ],
                      ),
                      _buildDivider(),
                      _buildDropdownField(
                        label: "Blood Type",
                        icon: Icons.bloodtype_outlined,
                        value: selectedBloodType,
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                        onChanged: (val) => setState(() => selectedBloodType = val),
                      ),
                      _buildDivider(),
                      _buildEditRow(label: "Emergency Contact", controller: emergencyController, icon: Icons.contact_emergency_rounded),
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
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: isReadOnly && onTap == null ? null : (value) => (value == null || value.isEmpty) ? "Required" : null,
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
