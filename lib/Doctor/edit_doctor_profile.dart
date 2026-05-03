import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/UpdateDoctorModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';

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

    // 1. Check File Size (Max 2MB)
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

    // 2. Check Dimensions (Max 1024x1024)
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
        // Refresh profile to get the new image URL
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
        firstName: fNameController.text,
        lastName: lNameController.text,
        phoneNumber: phoneController.text,
        gender: selectedGender,
        dateOfBirth: dobController.text,
        biography: bioController.text,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String imageBaseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev";
    
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
                    // Profile Picture Section
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          backgroundImage: currentImageUrl != null && currentImageUrl!.isNotEmpty
                              ? NetworkImage(currentImageUrl!.startsWith('http') ? currentImageUrl! : "$imageBaseUrl$currentImageUrl")
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
