import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';

class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({super.key});

  @override
  State<AddDoctorPage> createState() => _AddDoctorPageState();
}

class _AddDoctorPageState extends State<AddDoctorPage> {
  final _apiService = ApiService();

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _dobController = TextEditingController();
  final _specializationController = TextEditingController();

  String? _gender;
  int? _selectedSpecializationId;
  List<SpecializationModel> _specializations = [];
  bool _isLoadingSpecializations = true;

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _dobController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    try {
      final specs = await _apiService.getAllSpecializations();
      if (mounted) {
        setState(() {
          _specializations = specs;
          _isLoadingSpecializations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSpecializations = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading specializations: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSpecializationSearchSheet() {
    List<SpecializationModel> tempFiltered = List.from(_specializations);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: context.isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Select Specialization", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 15),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search specialization...",
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                      filled: true,
                      fillColor: context.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        tempFiltered = _specializations.where((spec) {
                          return spec.name.toLowerCase().contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: tempFiltered.isEmpty
                        ? const Center(child: Text("No specializations found"))
                        : ListView.separated(
                      itemCount: tempFiltered.length,
                      separatorBuilder: (context, index) => Divider(color: context.dividerCol),
                      itemBuilder: (context, index) {
                        final spec = tempFiltered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.category, color: primaryColor),
                          ),
                          title: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () {
                            setState(() {
                              _selectedSpecializationId = spec.id;
                              _specializationController.text = spec.name;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- الشروط الصارمة (Validators) ---
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return "Please enter a valid email address";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    List<String> errors = [];
    if (value.length < 8) errors.add("• Minimum 8 characters");
    if (!RegExp(r'[A-Z]').hasMatch(value)) errors.add("• One uppercase letter (A-Z)");
    if (!RegExp(r'[a-z]').hasMatch(value)) errors.add("• One lowercase letter (a-z)");
    if (!RegExp(r'[0-9]').hasMatch(value)) errors.add("• One number");

    if (errors.isNotEmpty) {
      return "Password must follow these rules:\n${errors.join('\n')}";
    }
    return null;
  }

  String? _validateName(String? value, String label) {
    if (value == null || value.trim().isEmpty) return "$label is required";
    if (value.trim().length < 3) return "$label must be at least 3 characters";
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";
    if (value.length != 11) return "Phone must be exactly 11 digits";
    if (!value.startsWith("01")) return "Phone must start with 01";
    return null;
  }

  // --- التنقل بين الخطوات ---
  void _nextStep() {
    // التأكد التام من صحة بيانات الصفحة الحالية قبل الانتقال للتالية
    if (_formKeys[_currentStep - 1].currentState!.validate()) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  // --- رفع الداتا (Submit) ---
  Future<void> _submit() async {
    // مراجعة أخيرة للبيانات قبل الرفع
    if (!_formKeys[_currentStep - 1].currentState!.validate()) return;

    if (_selectedSpecializationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a specialization"), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      DateTime dob = DateFormat('yyyy-MM-dd').parse(_dobController.text);

      final doctor = CreateDoctorModel(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        gender: _gender!,
        dateOfBirth: dob,
        address: _addressController.text.trim(),
        biography: "",
        experienceYears: double.tryParse(_experienceController.text) ?? 0,
        consultationFee: double.tryParse(_feeController.text) ?? 0,
        specializationId: _selectedSpecializationId!,
      );

      final doctorId = await _apiService.createDoctor(doctor);

      if (doctorId != null) {
        if (!mounted) return;
        Navigator.pop(context); // غلق اللودينج
        _showSuccessDialog();
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create doctor. No ID returned."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context); // غلق اللودينج

      String errorMessage = e.toString();

      // التعديل السحري: لقط إيرور الإيميل المستخدم من قبل وتحويله لرسالة مفهومة
      if (errorMessage.toLowerCase().contains("already") ||
          errorMessage.toLowerCase().contains("taken") ||
          errorMessage.toLowerCase().contains("exists") ||
          errorMessage.toLowerCase().contains("duplicate")) {
        errorMessage = "This email is already in use. Please use a different email.";
      } else {
        errorMessage = "Error: $e";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: const Text("Doctor registered successfully!", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // قفل الـ Dialog
                Navigator.of(context).pop(); // قفل الشاشة والرجوع للخلف
              },
              child: const Text("Continue"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () {
            if (_currentStep > 1) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark ? [const Color(0xFF0D1B2A), const Color(0xFF1A237E).withOpacity(0.8)] : [primaryColor.withOpacity(0.8), Colors.white],
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(context.isDark ? 0.15 : 0.05)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        decoration: BoxDecoration(
                          color: context.isDark ? Colors.grey.shade900.withOpacity(0.92) : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: context.isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.3)),
                        ),
                        child: Form(
                          key: _formKeys[_currentStep - 1],
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStepHeader(),
                              const SizedBox(height: 25),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _buildCurrentStepFields(),
                              ),
                              const SizedBox(height: 30),
                              _buildNavigationButtons(),
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

  Widget _buildStepHeader() {
    String title = "";
    IconData icon = Icons.person_add_rounded;

    if (_currentStep == 1) {
      title = "Account Credentials";
      icon = Icons.lock_outline_rounded;
    } else if (_currentStep == 2) {
      title = "Personal Information";
      icon = Icons.person_outline;
    } else {
      title = "Professional Information";
      icon = Icons.medical_services_outlined;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepIndicator(1),
            _buildStepLine(1),
            _buildStepIndicator(2),
            _buildStepLine(2),
            _buildStepIndicator(3),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: primaryColor),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : (isActive ? primaryColor : (context.isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
          "$step",
          style: TextStyle(color: isActive ? Colors.white : context.subText, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    bool isPassed = _currentStep > afterStep;
    return Container(width: 40, height: 2, color: isPassed ? Colors.green : (context.isDark ? Colors.grey.shade700 : Colors.grey.shade300));
  }

  Widget _buildCurrentStepFields() {
    if (_currentStep == 1) {
      return Column(
        key: const ValueKey(1),
        children: [
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            icon: Icons.lock_person_rounded,
            isPassword: true,
            isPasswordHidden: _isPasswordHidden,
            onTogglePassword: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
            validator: _validatePassword,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Confirm Password",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isPasswordHidden: _isConfirmPasswordHidden,
            onTogglePassword: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
            validator: (value) {
              if (value == null || value.isEmpty) return "Please confirm your password";
              if (value != _passwordController.text) return "Passwords do not match";
              return null;
            },
          ),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        key: const ValueKey(2),
        children: [
          _buildTextField(
            controller: _firstNameController,
            label: "First Name",
            icon: Icons.person_outline,
            validator: (v) => _validateName(v, "First Name"),
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _lastNameController,
            label: "Last Name",
            icon: Icons.person_outline,
            validator: (v) => _validateName(v, "Last Name"),
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _phoneController,
            label: "Phone Number",
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validatePhone,
          ),
          const SizedBox(height: 5),
          _buildDropdownField<String>(
            label: "Gender",
            icon: Icons.wc_rounded,
            value: _gender,
            items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) => setState(() => _gender = val),
            validator: (val) => val == null ? "Please select gender" : null,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _dobController,
            label: "Birth Date",
            icon: Icons.calendar_month_rounded,
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime(1990),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
              }
            },
            validator: (value) => (value == null || value.isEmpty) ? "Please select birth date" : null,
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey(3),
        children: [
          _isLoadingSpecializations
              ? _buildTextField(
            controller: TextEditingController(text: "Loading specializations..."),
            label: "Specialization",
            icon: Icons.hourglass_empty_rounded,
            readOnly: true,
          )
              : _buildTextField(
            controller: _specializationController,
            label: "Specialization",
            icon: Icons.category_outlined,
            readOnly: true,
            onTap: _showSpecializationSearchSheet,
            validator: (value) => _selectedSpecializationId == null ? "Please select specialization" : null,
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _experienceController,
                  label: "Exp. (Years)",
                  icon: Icons.work_outline,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _feeController,
                  label: "Fee (EGP)",
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _addressController,
            label: "Address",
            icon: Icons.location_on_outlined,
            validator: (value) => (value == null || value.trim().isEmpty) ? "Address is required" : null,
          ),
        ],
      );
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: const BorderSide(color: primaryColor),
              ),
              child: const Text("BACK", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _currentStep < 3 ? _nextStep : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
            ),
            child: Text(
              _currentStep < 3 ? "NEXT STEP" : "SAVE DOCTOR",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ],
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
    int? maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 14, color: context.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.subText, fontSize: 13),
        counterText: maxLength == null ? "" : null,
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
        errorMaxLines: 5,
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor, size: 20),
          onPressed: onTogglePassword,
        )
            : (onTap != null && maxLines == 1)
            ? Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade600)
            : null,
        filled: true,
        fillColor: context.isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
      validator: validator ?? (value) => (value == null || value.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: context.onSurface),
      dropdownColor: context.cardBg,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.subText, fontSize: 13),
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        filled: true,
        fillColor: context.isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
      validator: validator ?? (val) => val == null ? "Required" : null,
    );
  }
}