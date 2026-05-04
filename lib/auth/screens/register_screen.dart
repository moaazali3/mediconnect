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
  final otpController = TextEditingController();
  
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
    otpController.dispose();
    super.dispose();
  }

  // --- Validators ---

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Valid email required";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Required";
    if (value.length < 8) return "Min 8 characters required";
    return null;
  }

  String? _validateName(String? value, String label) {
    if (value == null || value.isEmpty) return "Required";
    if (value.length < 3) return "Min 3 characters";
    return null;
  }

  String? _validatePhone(String? value, String label) {
    if (value == null || value.isEmpty) return "Required";
    if (value.length != 11) return "Exactly 11 digits";
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
        _showOtpDialog(emailController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _showOtpDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Verify Email", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Code sent to: $email", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "000000",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final response = await ApiService().confirmEmail(email, otpController.text);
                if (mounted && response.success) {
                  Navigator.pop(context);
                  _showSuccessDialog(context);
                }
              },
              child: const Text("VERIFY"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    final bool isVeryNarrow = size.width < 360;

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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: isSmallScreen ? 20 : 30),
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
                              Image.asset(
                                "assets/images/img.png",
                                height: isSmallScreen ? 60 : 80,
                                errorBuilder: (c, e, s) => Icon(Icons.person_add_rounded, size: isSmallScreen ? 50 : 60, color: primaryColor),
                              ),
                              const SizedBox(height: 10),
                              Text(_getStepTitle(), style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold, color: primaryColor)),
                              Text("Step ${currentStep + 1} of 3", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 20),

                              if (currentStep == 0) ...[
                                _buildTextField(controller: emailController, label: "Email", icon: Icons.email_outlined, validator: _validateEmail),
                                const SizedBox(height: 15),
                                _buildTextField(controller: passController, label: "Password", icon: Icons.lock_outline, isPassword: true, isPasswordHidden: registerPasswordObscured, onTogglePassword: () => setState(() => registerPasswordObscured = !registerPasswordObscured), validator: _validatePassword),
                                const SizedBox(height: 15),
                                _buildTextField(controller: confirmPassController, label: "Confirm Password", icon: Icons.lock_outline, isPassword: true, isPasswordHidden: confirmPasswordObscured, onTogglePassword: () => setState(() => confirmPasswordObscured = !confirmPasswordObscured), validator: (v) => v != passController.text ? "No match" : null),
                              ],

                              if (currentStep == 1) ...[
                                _buildTextField(controller: fNameController, label: "First Name", icon: Icons.person_outline, validator: (v) => _validateName(v, "First Name")),
                                const SizedBox(height: 15),
                                _buildTextField(controller: lNameController, label: "Last Name", icon: Icons.person_outline, validator: (v) => _validateName(v, "Last Name")),
                                const SizedBox(height: 15),
                                _buildTextField(controller: phoneController, label: "Phone", icon: Icons.phone_android, keyboardType: TextInputType.phone, validator: (v) => _validatePhone(v, "Phone")),
                                const SizedBox(height: 15),
                                // Layout responsive for Gender and Birth Date
                                isVeryNarrow 
                                  ? Column(children: [
                                      _buildDropdownField(label: "Gender", icon: Icons.wc, value: selectedGender, items: ['Male', 'Female'], onChanged: (v) => setState(() => selectedGender = v)),
                                      const SizedBox(height: 15),
                                      _buildDatePickerField(),
                                    ])
                                  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Expanded(child: _buildDropdownField(label: "Gender", icon: Icons.wc, value: selectedGender, items: ['Male', 'Female'], onChanged: (v) => setState(() => selectedGender = v))),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildDatePickerField()),
                                    ]),
                                const SizedBox(height: 15),
                                _buildTextField(controller: addressController, label: "Address", icon: Icons.location_on_outlined),
                              ],

                              if (currentStep == 2) ...[
                                _buildDropdownField(label: "Blood", icon: Icons.bloodtype, value: selectedBloodType, items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], onChanged: (v) => setState(() => selectedBloodType = v)),
                                const SizedBox(height: 15),
                                _buildTextField(controller: weightController, label: "Weight (kg)", icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number),
                                const SizedBox(height: 15),
                                _buildTextField(controller: heightController, label: "Height (cm)", icon: Icons.height, keyboardType: TextInputType.number),
                                const SizedBox(height: 15),
                                _buildTextField(controller: emergencyController, label: "Emergency Phone", icon: Icons.contact_emergency, keyboardType: TextInputType.phone),
                              ],

                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  if (currentStep > 0) 
                                    Expanded(child: OutlinedButton(onPressed: () => setState(() => currentStep--), child: const Text("BACK"))),
                                  if (currentStep > 0) const SizedBox(width: 10),
                                  Expanded(child: ElevatedButton(onPressed: _handleNext, child: Text(currentStep == 2 ? "SIGN UP" : "NEXT"))),
                                ],
                              ),
                              if (currentStep == 0) ...[
                                const SizedBox(height: 15),
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Already have an account? Login", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                              ]
                            ],
                          ),
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

  Widget _buildDatePickerField() {
    return _buildTextField(
      controller: dobController,
      label: "Birth Date",
      icon: Icons.calendar_today,
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
        if (picked != null) setState(() => dobController.text = DateFormat('yyyy-MM-dd').format(picked));
      },
    );
  }

  String _getStepTitle() {
    if (currentStep == 0) return "Account Details";
    if (currentStep == 1) return "Personal Details";
    return "Medical Details";
  }

  void _handleNext() {
    if (formKey.currentState!.validate()) {
      if (currentStep < 2) setState(() => currentStep++);
      else _performRegister();
    }
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, bool isPasswordHidden = false, VoidCallback? onTogglePassword, TextInputType keyboardType = TextInputType.text, bool readOnly = false, VoidCallback? onTap, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: isPassword ? IconButton(icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: primaryColor, size: 20), onPressed: onTogglePassword) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      validator: (v) => v == null ? "Required" : null,
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Success"), content: const Text("Account created!"), actions: [TextButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); }, child: const Text("OK"))]));
  }
}
