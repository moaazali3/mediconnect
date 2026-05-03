import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/CreateReceptionistModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';

class AddReceptionistPage extends StatefulWidget {
  const AddReceptionistPage({super.key});

  @override
  State<AddReceptionistPage> createState() => _AddReceptionistPageState();
}

class _AddReceptionistPageState extends State<AddReceptionistPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();

  String _gender = 'Male';
  String? _selectedDoctorId;
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoadingDoctors = true;
  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _dobController.text = DateFormat('yyyy-MM-dd').format(DateTime(1995, 1, 1));
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _apiService.getDoctorNames();
      setState(() {
        _doctors = doctors;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading doctors: $e")));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a doctor")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final receptionist = CreateReceptionistModel(
        doctorId: _selectedDoctorId!,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        gender: _gender,
        dateOfBirth: _dobController.text,
        address: _addressController.text,
      );

      final success = await _apiService.createReceptionist(receptionist);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
        content: const Text("Receptionist added successfully!", textAlign: TextAlign.center),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CommonAppBar(title: "Add Receptionist", showBackButton: true),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, size: 50, color: primaryColor),
                          const SizedBox(height: 20),
                          _isLoadingDoctors
                            ? const CircularProgressIndicator()
                            : _buildDropdownField<String>(
                                label: "Assign to Doctor",
                                icon: Icons.medical_services_outlined,
                                value: _selectedDoctorId,
                                items: _doctors.map((d) => DropdownMenuItem(
                                  value: d['doctorId']?.toString(), 
                                  child: Text("Dr. ${d['doctorName'] ?? ''}", style: const TextStyle(fontSize: 13))
                                )).toList(),
                                onChanged: (val) => setState(() => _selectedDoctorId = val),
                              ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(controller: _firstNameController, label: "First Name", icon: Icons.person_outline)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField(controller: _lastNameController, label: "Last Name", icon: Icons.person_outline)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(controller: _emailController, label: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isPasswordHidden: _isPasswordHidden,
                            onTogglePassword: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(controller: _phoneController, label: "Phone", icon: Icons.phone_android, keyboardType: TextInputType.phone),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField<String>(
                                  label: "Gender",
                                  icon: Icons.wc,
                                  value: _gender,
                                  items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (val) => setState(() => _gender = val!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  controller: _dobController,
                                  label: "DOB",
                                  icon: Icons.calendar_today,
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(1995), firstDate: DateTime(1950), lastDate: DateTime.now());
                                    if (picked != null) setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
                                  }
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(controller: _addressController, label: "Address", icon: Icons.location_on_outlined),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: const Text("SAVE RECEPTIONIST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, bool isPasswordHidden = false, VoidCallback? onTogglePassword, TextInputType keyboardType = TextInputType.text, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: isPassword ? IconButton(icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: primaryColor), onPressed: onTogglePassword) : null,
        filled: true,
        fillColor: Colors.white70,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildDropdownField<T>({required String label, required IconData icon, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white70,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v == null ? "Required" : null,
    );
  }
}
