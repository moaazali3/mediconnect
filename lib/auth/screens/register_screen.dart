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
  int currentStep = 0;
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
  final String selectedRole = "Patient"; 
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

  // --- Validators ---

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Email must have:\n• Valid format (e.g. name@example.com)";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Required";
    
    List<String> requirements = [];
    if (value.length < 8) requirements.add("• At least 8 characters");
    if (!RegExp(r'[A-Z]').hasMatch(value)) requirements.add("• One uppercase letter");
    if (!RegExp(r'[a-z]').hasMatch(value)) requirements.add("• One lowercase letter");
    if (!RegExp(r'[0-9]').hasMatch(value)) requirements.add("• One number");
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) requirements.add("• One special character");

    if (requirements.isEmpty) return null;
    return "Password must have:\n" + requirements.join("\n");
  }

  String? _validateName(String? value, String label) {
    if (value == null || value.isEmpty) return "Required";
    List<String> requirements = [];
    if (value.length < 3) requirements.add("• At least 3 characters");
    if (RegExp(r'[0-9]').hasMatch(value)) requirements.add("• No numbers allowed");
    
    if (requirements.isEmpty) return null;
    return "$label must have:\n" + requirements.join("\n");
  }

  String? _validatePhone(String? value, String label) {
    if (value == null || value.isEmpty) return "Required";
    List<String> requirements = [];
    if (value.length != 11) requirements.add("• Exactly 11 digits");
    if (!value.startsWith("01")) requirements.add("• Must start with 01");
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) requirements.add("• Only numbers allowed");
    
    if (requirements.isEmpty) return null;
    return "$label must have:\n" + requirements.join("\n");
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) return "Required";
    if (value.length < 5) return "Address must have:\n• Min 5 characters";
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return "Required";
    double? w = double.tryParse(value);
    if (w == null || w < 2 || w > 300) {
      return "Weight must have:\n• Range between 2 and 300 kg";
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return "Required";
    double? h = double.tryParse(value);
    if (h == null || h < 40 || h > 250) {
      return "Height must have:\n• Range between 40 and 250 cm";
    }
    return null;
  }

  Future<void> _performRegister() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      DateTime dob = DateFormat('yyyy-MM-dd').parse(dobController.text);

      final response = await ApiService().registerUser(
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

      if (response.success) {
        _showSuccessDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
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
                colors: [primaryColor.withOpacity(0.8), Colors.white],
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.05)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle
                              ),
                              child: Image.asset(
                                "assets/images/img.png",
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_add_alt_1_rounded, size: 60, color: primaryColor),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(_getStepTitle(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                            const SizedBox(height: 5),
                            Text("Step ${currentStep + 1} of 3", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 25),

                            // STEP 1: Account Details
                            if (currentStep == 0) 
                              Column(
                                key: const ValueKey(0),
                                children: [
                                  _buildTextField(
                                    controller: emailController,
                                    label: "Email Address",
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    controller: passController,
                                    label: "Password",
                                    icon: Icons.lock_person_rounded,
                                    isPassword: true,
                                    isPasswordHidden: registerPasswordObscured,
                                    onTogglePassword: () => setState(() => registerPasswordObscured = !registerPasswordObscured),
                                    validator: _validatePassword,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                    controller: confirmPassController,
                                    label: "Confirm Password",
                                    icon: Icons.lock_person_rounded,
                                    isPassword: true,
                                    isPasswordHidden: confirmPasswordObscured,
                                    onTogglePassword: () => setState(() => confirmPasswordObscured = !confirmPasswordObscured),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return "Required";
                                      if (value != passController.text) return "Passwords do not match";
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                            // STEP 2: Personal Details
                            if (currentStep == 1) 
                              Column(
                                key: const ValueKey(1),
                                children: [
                                  _buildTextField(controller: fNameController, label: "First Name", icon: Icons.person_outline, validator: (v) => _validateName(v, "First Name")),
                                  const SizedBox(height: 15),
                                  _buildTextField(controller: lNameController, label: "Last Name", icon: Icons.person_outline, validator: (v) => _validateName(v, "Last Name")),
                                  const SizedBox(height: 15),
                                  _buildTextField(controller: phoneController, label: "Phone Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone, validator: (v) => _validatePhone(v, "Phone Number")),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(child: _buildDropdownField(
                                        label: "Gender",
                                        icon: Icons.wc_rounded,
                                        value: selectedGender,
                                        items: ['Male', 'Female'],
                                        onChanged: (val) => setState(() => selectedGender = val),
                                      )),
                                      const SizedBox(width: 10),
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
                                  const SizedBox(height: 15),
                                  _buildTextField(controller: addressController, label: "Home Address", icon: Icons.location_on_outlined, validator: _validateAddress),
                                ],
                              ),

                            // STEP 3: Medical Details
                            if (currentStep == 2) 
                              Column(
                                key: const ValueKey(2),
                                children: [
                                  _buildDropdownField(
                                    label: "Blood Type",
                                    icon: Icons.bloodtype_rounded,
                                    value: selectedBloodType,
                                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                                    onChanged: (val) => setState(() => selectedBloodType = val),
                                  ),
                                  const SizedBox(height: 15),
                                  _buildTextField(controller: weightController, label: "Weight (kg)", icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number, validator: _validateWeight),
                                  const SizedBox(height: 15),
                                  _buildTextField(controller: heightController, label: "Height (cm)", icon: Icons.height_rounded, keyboardType: TextInputType.number, validator: _validateHeight),
                                  const SizedBox(height: 15),
                                  _buildTextField(controller: emergencyController, label: "Emergency Contact", icon: Icons.contact_emergency_rounded, keyboardType: TextInputType.phone, validator: (v) => _validatePhone(v, "Emergency Contact")),
                                ],
                              ),

                            const SizedBox(height: 35),

                            Row(
                              children: [
                                if (currentStep > 0) 
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => currentStep--),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        side: const BorderSide(color: primaryColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: const Text("BACK", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                if (currentStep > 0) const SizedBox(width: 15),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _handleNext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 5,
                                    ),
                                    child: Text(currentStep == 2 ? "SIGN UP" : "NEXT", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (currentStep == 0)
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

  String _getStepTitle() {
    switch (currentStep) {
      case 0: return "Account Details";
      case 1: return "Personal Details";
      case 2: return "Medical Details";
      default: return "";
    }
  }

  void _handleNext() {
    if (formKey.currentState!.validate()) {
      if (currentStep < 2) {
        setState(() => currentStep++);
      } else {
        _performRegister();
      }
    }
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
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        errorMaxLines: 10,
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor, size: 20),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
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
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
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
