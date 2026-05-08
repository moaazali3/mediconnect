import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضرورية عشان نمنع الحروف في التليفون
import 'package:image_picker/image_picker.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/UpdateDoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/constants/api_constants.dart';

class EditDoctorProfile extends StatefulWidget {
  final String? doctorId;
  const EditDoctorProfile({super.key, this.doctorId});

  @override
  State<EditDoctorProfile> createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  final formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool isUploadingImage = false;

  final fNameController = TextEditingController();
  final lNameController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedGender;
  String? currentImageUrl;

  int? _currentSpecializationId;
  double _currentExperienceYears = 0;
  double _currentConsultationFee = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    fNameController.dispose();
    lNameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    dobController.dispose();
    super.dispose();
  }

  // --- الشروط الصارمة (Validators) ---
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

  Future<void> _loadProfileData() async {
    try {
      final String targetId = widget.doctorId ?? "1";
      final specs = await _apiService.getAllSpecializations();
      final doctor = await _apiService.getDoctorProfile(targetId);

      final spec = specs.where((s) => s.name == doctor.specializationName).firstOrNull;

      setState(() {
        fNameController.text = doctor.firstName;
        lNameController.text = doctor.lastName;
        phoneController.text = doctor.phoneNumber;
        bioController.text = doctor.biography;
        dobController.text = doctor.dateOfBirth;
        selectedGender = doctor.gender;
        currentImageUrl = doctor.profilePictureUrl;

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

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final int fileSize = await image.length();
    if (fileSize > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image size is too large (Maximum 2MB)"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final bytes = await image.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image decodedImage = fi.image;

      if (decodedImage.width > 1024 || decodedImage.height > 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image dimensions are too large (Maximum 1024x1024)"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint("Error checking image dimensions: $e");
    }

    setState(() => isUploadingImage = true);
    final String targetId = widget.doctorId ?? "1";

    try {
      final success = await _apiService.uploadProfilePicture(targetId, image.path);
      if (success) {
        final doctor = await _apiService.getDoctorProfile(targetId);
        setState(() {
          currentImageUrl = doctor.profilePictureUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw "Upload failed";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isUploadingImage = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final String targetId = widget.doctorId ?? "1";

    try {
      final latestProfile = await _apiService.getDoctorProfile(targetId);
      final specs = await _apiService.getAllSpecializations();
      final spec = specs.firstWhere((s) => s.name == latestProfile.specializationName);

      final updateModel = UpdateDoctorModel.fromProfile(latestProfile, spec.id).copyWith(
        firstName: fNameController.text.trim(),
        lastName: lNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        gender: selectedGender,
        dateOfBirth: dobController.text,
        biography: bioController.text.trim(),
        specializationId: _currentSpecializationId ?? spec.id,
        consultationFee: _currentConsultationFee,
        experienceYears: _currentExperienceYears,
      );

      final success = await _apiService.updateDoctor(targetId, updateModel);

      if (mounted) {
        setState(() => isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          throw "Update failed.";
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);

        String errorMessage = e.toString();
        // معالجة ذكية لو التليفون مكرر
        if (errorMessage.toLowerCase().contains("already") || errorMessage.toLowerCase().contains("taken")) {
          errorMessage = "Phone number is already in use. Please check.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      backgroundImage: currentImageUrl != null && currentImageUrl!.isNotEmpty
                          ? NetworkImage(currentImageUrl!.startsWith('http') ? currentImageUrl! : "${ApiConstants.serverUrl}$currentImageUrl")
                          : null,
                      child: currentImageUrl == null || currentImageUrl!.isEmpty
                          ? const Icon(Icons.person, size: 60, color: primaryColor)
                          : null,
                    ),
                    if (isUploadingImage)
                      const Positioned.fill(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isUploadingImage ? null : _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSectionTitle("Personal Information"),
                ),
                _buildEditCard([
                  _buildEditRow(label: "First Name", controller: fNameController, icon: Icons.person_outline, validator: (v) => _validateName(v, "First Name")),
                  _buildDivider(),
                  _buildEditRow(label: "Last Name", controller: lNameController, icon: Icons.person_outline, validator: (v) => _validateName(v, "Last Name")),
                  _buildDivider(),
                  _buildEditRow(
                    label: "Phone",
                    controller: phoneController,
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validatePhone,
                  ),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSectionTitle("Professional Biography"),
                ),
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

  Widget _buildEditRow({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 11),
          counterText: maxLength == null ? "" : null,
          errorStyle: const TextStyle(fontSize: 11, height: 1.2),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: validator ?? (value) => (value == null || value.trim().isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // <--- السر كله هنا، دي اللي بتمنع الأوفر فلو
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 11),
          errorStyle: const TextStyle(fontSize: 11, height: 1.2),
          prefixIcon: Icon(icon, color: primaryColor, size: 18),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: (val) => val == null ? "Required" : null,
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 45, endIndent: 15, color: Colors.grey.shade100);
}