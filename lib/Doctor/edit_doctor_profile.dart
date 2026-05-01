import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/UpdateDoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:intl/intl.dart';

class EditDoctorProfile extends StatefulWidget {
  final String? doctorId;
  const EditDoctorProfile({super.key, this.doctorId});

  @override
  State<EditDoctorProfile> createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  final formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool isLoading = true;

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedGender;
  
  // حقول إضافية للحفاظ على البيانات القديمة
  int? _currentSpecializationId;
  double _currentExperienceYears = 0;
  double _currentConsultationFee = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final String targetId = widget.doctorId ?? "1";
      
      // جلب البيانات والتخصصات معاً
      final specs = await _apiService.getAllSpecializations();
      final doctor = await _apiService.getDoctorProfile(targetId);
      
      final spec = specs.where((s) => s.name == doctor.specializationName).firstOrNull;

      setState(() {
        fNameController.text = doctor.firstName;
        lNameController.text = doctor.lastName;
        emailController.text = doctor.email;
        phoneController.text = doctor.phoneNumber;
        addressController.text = doctor.address ?? "";
        bioController.text = doctor.biography;
        dobController.text = doctor.dateOfBirth;
        selectedGender = doctor.gender;
        
        _currentSpecializationId = spec?.id;
        _currentExperienceYears = doctor.experienceYears;
        _currentConsultationFee = doctor.consultationFee;
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final String targetId = widget.doctorId ?? "1";

    try {
      // 1. جلب أحدث البيانات من السيرفر قبل التعديل لضمان عدم فقدان أي حقل (مثل الخبرة أو السعر)
      final latestProfile = await _apiService.getDoctorProfile(targetId);
      final specs = await _apiService.getAllSpecializations();
      final spec = specs.firstWhere((s) => s.name == latestProfile.specializationName);

      // 2. بناء كائن التحديث بناءً على البيانات القديمة ودمج التغييرات الجديدة من النموذج
      final updateModel = UpdateDoctorModel.fromProfile(latestProfile, spec.id).copyWith(
        firstName: fNameController.text,
        lastName: lNameController.text,
        phoneNumber: phoneController.text,
        gender: selectedGender,
        dateOfBirth: dobController.text,
        biography: bioController.text,
        // الحفاظ على التخصص والسعر والخبرة كما هي إذا لم يتم تغييرها في هذه الشاشة
        specializationId: _currentSpecializationId ?? spec.id,
        consultationFee: _currentConsultationFee,
        experienceYears: _currentExperienceYears,
      );

      // 3. إرسال طلب التحديث
      final success = await _apiService.updateDoctor(targetId, updateModel);
      
      if (mounted) {
        setState(() => isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          throw "Update failed. Please verify your information.";
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                    _buildSectionTitle("Personal Information"),
                    _buildEditCard([
                      _buildEditRow(label: "First Name", controller: fNameController, icon: Icons.person_outline),
                      _buildDivider(),
                      _buildEditRow(label: "Last Name", controller: lNameController, icon: Icons.person_outline),
                      _buildDivider(),
                      _buildEditRow(label: "Phone", controller: phoneController, icon: Icons.phone_android_rounded),
                      _buildDivider(),
                      _buildDropdownField(
                        label: "Gender",
                        icon: Icons.wc_rounded,
                        value: selectedGender,
                        items: ['Male', 'Female'],
                        onChanged: (val) => setState(() => selectedGender = val),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle("Professional Biography"),
                    _buildEditCard([
                      _buildEditRow(
                        label: "Biography", 
                        controller: bioController, 
                        icon: Icons.description_rounded, 
                        maxLines: 5
                      ),
                    ]),

                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
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

  Widget _buildEditRow({required String label, required TextEditingController controller, required IconData icon, bool isReadOnly = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 45, endIndent: 15, color: Colors.grey.shade100);
}
