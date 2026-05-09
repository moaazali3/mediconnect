import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/widgets/password_strength_checker.dart';

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

    final PatientProfileModel updatedProfile = PatientProfileModel(
      id: targetId,
      firstName: fNameController.text,
      lastName: lNameController.text,
      email: emailController.text,
      dateOfBirth: dobController.text,
      gender: selectedGender ?? 'Male',
      address: addressController.text,
      bloodType: selectedBloodType ?? 'N/A',
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
      backgroundColor: context.scaffoldBg,
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : primaryColor.withOpacity(0.15),
                child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : primaryColor
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
                    "${fNameController.text} ${lNameController.text}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text("Edit Patient Profile", style: TextStyle(fontSize: 13, color: Colors.white70)),
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditRow({required String label, required TextEditingController controller, required IconData icon, bool isReadOnly = false, TextInputType keyboardType = TextInputType.text, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: TextStyle(color: isReadOnly && onTap == null ? context.subText : context.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.subText, fontSize: 11),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          isDense: true,
        ),
        validator: isReadOnly && onTap == null ? null : (value) => (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.subText, fontSize: 11),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 35, endIndent: 15, color: context.dividerCol);
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final passKey = GlobalKey<FormState>();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: context.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            content: Form(
              key: passKey,
              child: SingleChildScrollView(
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
                      onChanged: (val) {
                        setModalState(() {});
                      },
                      suffix: IconButton(
                        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: context.subText, size: 20),
                        onPressed: () => setModalState(() => isObscured = !isObscured),
                      ),
                    ),
                    const SizedBox(height: 15),
                    PasswordStrengthChecker(password: newPass.text),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final password = newPass.text;
                  final hasMinLength = password.length >= 8;
                  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
                  final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
                  final hasNumber = RegExp(r'[0-9]').hasMatch(password);
                  final hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
                  
                  if (!hasMinLength || !hasUppercase || !hasLowercase || !hasNumber || !hasSpecialChar) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please meet all password requirements"), backgroundColor: Colors.red));
                    return;
                  }
                  if (passKey.currentState!.validate()) {
                    _changePassword(oldPass.text, newPass.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPopupField({required TextEditingController controller, required String label, required IconData icon, bool isObscured = false, Widget? suffix, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}