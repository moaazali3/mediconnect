import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';

class AddDoctorPage extends StatefulWidget {
  const AddDoctorPage({super.key});

  @override
  State<AddDoctorPage> createState() => _AddDoctorPageState();
}

class _AddDoctorPageState extends State<AddDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _dobController = TextEditingController();

  String _gender = 'Male';
  int? _selectedSpecializationId;
  List<SpecializationModel> _specializations = [];
  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
    _dobController.text = DateFormat('yyyy-MM-dd').format(DateTime(1990, 1, 1));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    try {
      final specs = await _apiService.getAllSpecializations();
      setState(() {
        _specializations = specs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading specializations: $e")),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSpecializationId == null) {
      if (_selectedSpecializationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a specialization"), backgroundColor: Colors.red),
        );
      }
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
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        gender: _gender,
        dateOfBirth: dob,
        address: _addressController.text,
        experienceYears: double.tryParse(_experienceController.text) ?? 0,
        consultationFee: double.tryParse(_feeController.text) ?? 0,
        specializationId: _selectedSpecializationId!,
      );

      final success = await _apiService.createDoctor(doctor);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add doctor. Check logs."), backgroundColor: Colors.red),
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: const Text("Doctor added successfully!", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.8),
                  Colors.white,
                ],
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.05)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600), // لمنع التمدد في الشاشات الكبيرة
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
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_add_rounded, size: 45, color: primaryColor),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Add New Doctor",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                              const SizedBox(height: 25),

                              // استخدام LayoutBuilder لجعل الصفوف متجاوبة
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  bool isSmall = constraints.maxWidth < 400;
                                  return Column(
                                    children: [
                                      if (isSmall) ...[
                                        _buildTextField(controller: _firstNameController, label: "First Name", icon: Icons.person_outline),
                                        const SizedBox(height: 12),
                                        _buildTextField(controller: _lastNameController, label: "Last Name", icon: Icons.person_outline),
                                      ] else ...[
                                        Row(
                                          children: [
                                            Expanded(child: _buildTextField(controller: _firstNameController, label: "First Name", icon: Icons.person_outline)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildTextField(controller: _lastNameController, label: "Last Name", icon: Icons.person_outline)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _emailController,
                                label: "Email Address",
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _passwordController,
                                label: "Password",
                                icon: Icons.lock_person_rounded,
                                isPassword: true,
                                isPasswordHidden: _isPasswordHidden,
                                onTogglePassword: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _phoneController,
                                label: "Phone Number",
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _addressController,
                                label: "Address",
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(height: 12),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 400) {
                                    return Column(
                                      children: [
                                        _buildTextField(controller: _experienceController, label: "Exp. (Years)", icon: Icons.work_outline, keyboardType: TextInputType.number),
                                        const SizedBox(height: 12),
                                        _buildTextField(controller: _feeController, label: "Fee (\$)", icon: Icons.attach_money_rounded, keyboardType: TextInputType.number),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: _buildTextField(controller: _experienceController, label: "Exp. (Years)", icon: Icons.work_outline, keyboardType: TextInputType.number)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildTextField(controller: _feeController, label: "Fee (\$)", icon: Icons.attach_money_rounded, keyboardType: TextInputType.number)),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildDropdownField<int>(
                                label: "Specialization",
                                icon: Icons.category_outlined,
                                initialValue: _selectedSpecializationId,
                                items: _specializations.map((spec) => DropdownMenuItem(value: spec.id, child: Text(spec.name, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setState(() => _selectedSpecializationId = val),
                              ),
                              const SizedBox(height: 12),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 400) {
                                    return Column(
                                      children: [
                                        _buildDropdownField<String>(
                                          label: "Gender",
                                          icon: Icons.wc_rounded,
                                          initialValue: _gender,
                                          items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() => _gender = val!),
                                        ),
                                        const SizedBox(height: 12),
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
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdownField<String>(
                                          label: "Gender",
                                          icon: Icons.wc_rounded,
                                          initialValue: _gender,
                                          items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() => _gender = val!),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildTextField(
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
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5,
                                  ),
                                  child: const Text("SAVE DOCTOR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
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
            color: primaryColor.withOpacity(0.1),
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
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
      validator: validator ?? (value) => (value == null || value.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? initialValue,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: initialValue,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 11),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
      validator: (val) => val == null ? "Required" : null,
    );
  }
}
