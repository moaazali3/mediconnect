import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool registerPasswordObscured = true;
  bool confirmPasswordObscured = true;
  final formKey = GlobalKey<FormState>();

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  
  String? selectedGender;
  final String selectedRole = "Patient"; // Role is always Patient now
  String? selectedBloodType;

  @override
  void dispose() {
    fNameController.dispose();
    lNameController.dispose();
    phoneController.dispose();
    emergencyController.dispose();
    weightController.dispose();
    heightController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    dobController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _performRegister() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      DateTime dob;
      try {
        dob = DateFormat('yyyy-MM-dd').parse(dobController.text);
      } catch (e) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final success = await ApiService().registerUser(
        firstName: fNameController.text,
        lastName: lNameController.text,
        email: emailController.text,
        password: passController.text,
        phone: phoneController.text,
        gender: selectedGender!,
        height: double.tryParse(heightController.text) ?? 0.0,
        weight: double.tryParse(weightController.text) ?? 0.0,
        dateOfBirth: dob,
        bloodType: selectedBloodType!,
        address: addressController.text,
        emergencyContact: emergencyController.text,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        _showSuccessDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Container(color: Colors.black.withValues(alpha: 0.05)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, size: 45, color: primaryColor),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Create Account",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                            const SizedBox(height: 25),

                            Row(
                              children: [
                                Expanded(child: _buildTextField(controller: fNameController, label: "First Name", icon: Icons.person_outline)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildTextField(controller: lNameController, label: "Last Name", icon: Icons.person_outline)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: _buildTextField(controller: phoneController, label: "Phone", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildTextField(controller: emergencyController, label: "Emergency", icon: Icons.contact_emergency_rounded, keyboardType: TextInputType.phone)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: _buildTextField(controller: weightController, label: "Weight", icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildTextField(controller: heightController, label: "Height", icon: Icons.height_rounded, keyboardType: TextInputType.number)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: _buildDropdownField(
                                  label: "Blood",
                                  icon: Icons.bloodtype_rounded,
                                  value: selectedBloodType,
                                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                                  onChanged: (val) => setState(() => selectedBloodType = val),
                                )),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                    controller: dobController,
                                    label: "Birth Date",
                                    icon: Icons.calendar_month_rounded,
                                    readOnly: true,
                                    onTap: () async {
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
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
                            const SizedBox(height: 12),

                            // Gender dropdown only
                            _buildDropdownField(
                              label: "Gender",
                              icon: Icons.wc_rounded,
                              value: selectedGender,
                              items: ['Male', 'Female'],
                              onChanged: (val) => setState(() => selectedGender = val),
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: addressController,
                              label: "Home Address",
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: emailController,
                              label: "Email Address",
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: passController,
                              label: "Password",
                              icon: Icons.lock_person_rounded,
                              isPassword: true,
                              isPasswordHidden: registerPasswordObscured,
                              onTogglePassword: () => setState(() => registerPasswordObscured = !registerPasswordObscured),
                            ),
                            const SizedBox(height: 12),
                            
                            _buildTextField(
                              controller: confirmPassController,
                              label: "Confirm Password",
                              icon: Icons.lock_person_rounded,
                              isPassword: true,
                              isPasswordHidden: confirmPasswordObscured,
                              onTogglePassword: () => setState(() => confirmPasswordObscured = !confirmPasswordObscured),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Required";
                                if (value != passController.text) return "No match";
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    _performRegister();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                                ),
                                child: const Text("SIGN UP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ),
                            ),
                            const SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account?"),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Login", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordHidden = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 11),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        suffixIcon: isPassword
            ? IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor, size: 18),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
      validator: validator ?? (value) => (value == null || value.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 11),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
      validator: (val) => val == null ? "Required" : null,
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: const Text("Account created successfully!", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text("Continue"),
            ),
          )
        ],
      ),
    );
  }
}
