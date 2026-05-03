import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

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
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _biographyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _dobController = TextEditingController();
  
  // Schedule Controllers
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  String? _selectedDay;
  final List<String> _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  String _gender = 'Male';
  int? _selectedSpecializationId;
  List<SpecializationModel> _specializations = [];
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
    _dobController.text = DateFormat('yyyy-MM-dd').format(DateTime(1990, 1, 1));
    _startTimeController.text = "09:00";
    _endTimeController.text = "17:00";
    _selectedDay = _days[DateFormat('EEEE').format(DateTime.now()) == "Friday" ? 0 : _days.indexOf(DateFormat('EEEE').format(DateTime.now()))];
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
    _biographyController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _dobController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
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

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep == 1) {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
          );
          return;
        }
      }
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
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
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        gender: _gender,
        dateOfBirth: dob,
        address: _addressController.text,
        biography: _biographyController.text,
        experienceYears: double.tryParse(_experienceController.text) ?? 0,
        consultationFee: double.tryParse(_feeController.text) ?? 0,
        specializationId: _selectedSpecializationId!,
      );

      // هذا الطلب سيرمي استثناء في حال فشل السيرفر
      final doctorId = await _apiService.createDoctor(doctor);

      // التحقق من المعرف (ID) بشكل صحيح لضمان التوافق مع ApiService
      if (doctorId != null && doctorId != "SUCCESS_NO_ID" && doctorId.length > 10) {
        // إنشاء جدول المواعيد
        final scheduleRes = await _apiService.createDoctorSchedule(doctorId, {
          "dayOfWeek": _selectedDay,
          "startTime": _startTimeController.text,
          "endTime": _endTimeController.text,
          "isAvailable": true,
        });

        if (!mounted) return;
        Navigator.pop(context); // إغلاق نافذة التحميل
        
        if (scheduleRes.success) {
          _showSuccessDialog();
        } else {
          // تم إنشاء الحساب ولكن فشل إنشاء الجدول
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Doctor added, but schedule failed: ${scheduleRes.message}"), 
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          _showSuccessDialog(); 
        }
      } else {
        // نجاح العملية بدون ID حقيقي (ربما نص نجاح بديل)
        if (!mounted) return;
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      print("ADD_DOCTOR_ERROR: $e");
      
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: "Close", textColor: Colors.white, onPressed: () {}),
        ),
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
        content: const Text("Doctor added successfully!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true); // العودة وتحديث القائمة
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Continue", style: TextStyle(color: Colors.white)),
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
      appBar: const CommonAppBar(
        title: "Add New Doctor",
        showBackButton: true,
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
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
      title = "Professional & Schedule";
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
        color: isCompleted ? Colors.green : (isActive ? primaryColor : Colors.grey.shade300),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                "$step",
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    bool isPassed = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      color: isPassed ? Colors.green : Colors.grey.shade300,
    );
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
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            icon: Icons.lock_person_rounded,
            isPassword: true,
            isPasswordHidden: _isPasswordHidden,
            onTogglePassword: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
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
              if (value == null || value.isEmpty) return "Required";
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
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _firstNameController, label: "First Name", icon: Icons.person_outline)),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(controller: _lastNameController, label: "Last Name", icon: Icons.person_outline)),
            ],
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _phoneController,
            label: "Phone Number",
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 15),
          Row(
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
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey(3),
        children: [
          _buildDropdownField<int>(
            label: "Specialization",
            icon: Icons.category_outlined,
            initialValue: _selectedSpecializationId,
            items: _specializations.map((spec) => DropdownMenuItem(value: spec.id, child: Text(spec.name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) => setState(() => _selectedSpecializationId = val),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _experienceController, label: "Exp. (Years)", icon: Icons.work_outline, keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(controller: _feeController, label: "Fee (EGP)", icon: Icons.payments_outlined, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 15),
          // --- WORK SCHEDULE SECTION ---
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: primaryColor),
                    SizedBox(width: 8),
                    Text("WORK SCHEDULE", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: "Day of Week",
                  icon: Icons.calendar_view_day_rounded,
                  initialValue: _selectedDay,
                  items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _selectedDay = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _startTimeController,
                        label: "Start Time",
                        icon: Icons.access_time_rounded,
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _startTimeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _endTimeController,
                        label: "End Time",
                        icon: Icons.access_time_filled_rounded,
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _endTimeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // --- END WORK SCHEDULE SECTION ---
          const SizedBox(height: 15),
          _buildTextField(
            controller: _addressController,
            label: "Address",
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _biographyController,
            label: "Biography",
            icon: Icons.description_outlined,
            maxLines: 4,
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
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
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
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
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      ),
      validator: (val) => val == null ? "Required" : null,
    );
  }
}
