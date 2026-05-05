import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialEmail;
  final bool showOtpDialog;
  const RegisterScreen({super.key, this.initialEmail, this.showOtpDialog = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int currentStep = 0;
  bool registerPasswordObscured = true;
  bool confirmPasswordObscured = true;
  bool _isJustRegistered = false; 

  // Use separate keys for each step to avoid validation state bleeding between steps
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

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
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      emailController.text = widget.initialEmail!;
    }
    if (widget.showOtpDialog && widget.initialEmail != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOtpDialog(widget.initialEmail!);
      });
    }
  }

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
    if (value == null || value.isEmpty) return "Email address is required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";

    final hasMinLength = value.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasMinLength || !hasUppercase || !hasLowercase || !hasNumber || !hasSpecialChar) {
      return "Password must follow these rules:\n• Minimum 8 characters\n• One uppercase letter (A-Z)\n• One lowercase letter (a-z)\n• One number\n• One special character (@, #, \$, etc.)";
    }
    return null;
  }

  String? _validateName(String? value, String label) {
    if (value == null || value.isEmpty) return "$label is required";
    if (value.length < 3) return "$label must be at least 3 characters";
    return null;
  }

  String? _validatePhone(String? value, String label) {
    if (value == null || value.isEmpty) return "$label is required";
    if (value.length != 11) return "$label must be exactly 11 digits";
    if (!value.startsWith('01')) return "$label must start with 01";
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return "Height is required";
    final h = double.tryParse(value);
    if (h == null || h < 50 || h > 250) return "Height must be between 50 and 250 cm";
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return "Weight is required";
    final w = double.tryParse(value);
    if (w == null || w < 20 || w > 300) return "Weight must be between 20 and 300 kg";
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) return "Address is required";
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
        setState(() => _isJustRegistered = true);
        _showOtpDialog(emailController.text);
      } else {
        String errorMessage = response.message;
        if (errorMessage.contains("already taken")) {
          errorMessage = "This email is already in use.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _showOtpDialog(String email) {
    otpController.clear();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 50, color: primaryColor),
                    const SizedBox(height: 15),
                    const Text("Verify Email",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(height: 10),
                    Text("We have sent a 6-digit verification code to\n$email",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                    const SizedBox(height: 30),

                    SizedBox(
                      height: 55,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: List.generate(6, (index) {
                              bool isFocused = otpController.text.length == index;
                              bool isFilled = otpController.text.length > index;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isFocused ? primaryColor : (isFilled ? primaryColor.withOpacity(0.5) : Colors.grey.shade300),
                                      width: isFocused ? 2 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isFilled ? otpController.text[index] : "",
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.01,
                              child: TextField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                maxLength: 6,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (val) {
                                  setDialogState(() {
                                    errorText = null;
                                  });
                                },
                                decoration: const InputDecoration(
                                  counterText: "",
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (otpController.text.length < 6) {
                            setDialogState(() => errorText = "Please enter the full 6-digit code");
                            return;
                          }
                          setDialogState(() => isLoading = true);
                          try {
                            final response = await ApiService().confirmEmail(email, otpController.text);
                            if (mounted) {
                              if (response.success) {
                                Navigator.pop(dialogContext);
                                _showSuccessDialog();
                              } else {
                                setDialogState(() {
                                  isLoading = false;
                                  errorText = response.message;
                                });
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorText = "Something went wrong, please try again";
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          Container(color: Colors.black.withOpacity(0.05)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: isSmallScreen ? 20 : 35),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Form(
                                key: _formKeys[currentStep],
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                                      child: Image.asset(
                                        "assets/images/img.png",
                                        height: isSmallScreen ? 70 : 100,
                                        width: isSmallScreen ? 70 : 100,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Icon(Icons.person_add_rounded, size: isSmallScreen ? 50 : 80, color: primaryColor),
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 10 : 20),
                                    Text(_getStepTitle(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: isSmallScreen ? 20 : 26, fontWeight: FontWeight.bold, color: primaryColor)),
                                    Text("Step ${currentStep + 1} of 3",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                    SizedBox(height: isSmallScreen ? 20 : 35),

                                    if (currentStep == 0) ...[
                                      _buildTextField(controller: emailController, label: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: _validateEmail),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: passController, label: "Password", icon: Icons.lock_outline, isPassword: true, isPasswordHidden: registerPasswordObscured, onTogglePassword: () => setState(() => registerPasswordObscured = !registerPasswordObscured), validator: _validatePassword),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: confirmPassController, label: "Confirm Password", icon: Icons.lock_outline, isPassword: true, isPasswordHidden: confirmPasswordObscured, onTogglePassword: () => setState(() => confirmPasswordObscured = !confirmPasswordObscured), validator: (v) => v != passController.text ? "Passwords do not match" : null),
                                    ],

                                    if (currentStep == 1) ...[
                                      _buildTextField(controller: fNameController, label: "First Name", icon: Icons.person_outline, validator: (v) => _validateName(v, "First Name")),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: lNameController, label: "Last Name", icon: Icons.person_outline, validator: (v) => _validateName(v, "Last Name")),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: phoneController, label: "Phone", icon: Icons.phone_android, keyboardType: TextInputType.phone, validator: (v) => _validatePhone(v, "Phone")),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      isVeryNarrow
                                          ? Column(children: [
                                        _buildDropdownField(label: "Gender", icon: Icons.wc, value: selectedGender, items: ['Male', 'Female'], onChanged: (v) => setState(() => selectedGender = v)),
                                        SizedBox(height: isSmallScreen ? 15 : 20),
                                        _buildDatePickerField(),
                                      ])
                                          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Expanded(child: _buildDropdownField(label: "Gender", icon: Icons.wc, value: selectedGender, items: ['Male', 'Female'], onChanged: (v) => setState(() => selectedGender = v))),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildDatePickerField()),
                                      ]),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: addressController, label: "Address", icon: Icons.location_on_outlined, validator: _validateAddress),
                                    ],

                                    if (currentStep == 2) ...[
                                      _buildDropdownField(label: "Blood Type", icon: Icons.bloodtype, value: selectedBloodType, items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], onChanged: (v) => setState(() => selectedBloodType = v)),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: weightController, label: "Weight (kg)", icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number, validator: _validateWeight),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: heightController, label: "Height (cm)", icon: Icons.height, keyboardType: TextInputType.number, validator: _validateHeight),
                                      SizedBox(height: isSmallScreen ? 15 : 20),
                                      _buildTextField(controller: emergencyController, label: "Emergency Phone", icon: Icons.contact_emergency, keyboardType: TextInputType.phone, validator: (v) => _validatePhone(v, "Emergency Phone")),
                                    ],

                                    SizedBox(height: isSmallScreen ? 20 : 35),
                                    Row(
                                      children: [
                                        if (currentStep > 0)
                                          Expanded(
                                            child: SizedBox(
                                              height: 50,
                                              child: OutlinedButton(
                                                onPressed: () => setState(() => currentStep--),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: primaryColor),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                ),
                                                child: const Text("BACK", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                        if (currentStep > 0) const SizedBox(width: 10),
                                        Expanded(
                                          child: SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed: _handleNext,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                elevation: 5,
                                              ),
                                              child: Text(currentStep == 2 ? "SIGN UP" : "NEXT", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (currentStep == 0) ...[
                                      SizedBox(height: isSmallScreen ? 10 : 25),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        children: [
                                          const Text("Already have an account?", style: TextStyle(fontSize: 14)),
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: const Padding(
                                              padding: EdgeInsets.only(left: 8.0),
                                              child: Text("Login", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                          ),
                                        ],
                                      ),
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
                );
              },
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
    // Validate only the current step's form
    if (_formKeys[currentStep].currentState!.validate()) {
      if (currentStep < 2) setState(() => currentStep++);
      else _performRegister();
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
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
        errorMaxLines: 5,
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor, size: 20),
          onPressed: onTogglePassword,
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5))
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5)
        ),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)
        ),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)
        ),
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
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5))
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5)
        ),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)
        ),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)
        ),
      ),
      validator: (v) => v == null ? "Required" : null,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Your account has been created successfully. Please login to continue.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Return to Login screen and clear the navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
