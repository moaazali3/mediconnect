import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/UpdateDoctorModel.dart';
import 'package:mediconnect/services/api_service.dart';

class EditDoctorManagementPage extends StatefulWidget {
  final String doctorId;
  const EditDoctorManagementPage({super.key, required this.doctorId});

  @override
  State<EditDoctorManagementPage> createState() => _EditDoctorManagementPageState();
}

class _EditDoctorManagementPageState extends State<EditDoctorManagementPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _feeController = TextEditingController();
  final _biographyController = TextEditingController();
  final _addressController = TextEditingController();
  final _expController = TextEditingController();
  final _dobController = TextEditingController();
  
  String _gender = 'Male';
  DoctorProfileModel? _currentProfile;
  List<SpecializationModel> _specializations = [];
  List<DoctorScheduleModel> _schedules = [];
  int? _selectedSpecId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phoneController.dispose();
    _feeController.dispose();
    _biographyController.dispose();
    _addressController.dispose();
    _expController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      _specializations = await _apiService.getAllSpecializations();
      _currentProfile = await _apiService.getDoctorProfile(widget.doctorId);
      _schedules = await _apiService.getDoctorSchedule(widget.doctorId);
      
      _fNameController.text = _currentProfile!.firstName;
      _lNameController.text = _currentProfile!.lastName;
      _phoneController.text = _currentProfile!.phoneNumber;
      _feeController.text = _currentProfile!.consultationFee.toStringAsFixed(0);
      _biographyController.text = _currentProfile!.biography;
      _addressController.text = _currentProfile!.address ?? '';
      _expController.text = _currentProfile!.experienceYears.toStringAsFixed(0);
      _dobController.text = _currentProfile!.dateOfBirth.split('T')[0];
      _gender = _currentProfile!.gender;
      
      final spec = _specializations.firstWhere(
        (s) => s.name == _currentProfile!.specializationName,
        orElse: () => _specializations.isNotEmpty 
            ? _specializations.first 
            : SpecializationModel(id: 0, name: '', description: ''),
      );
      _selectedSpecId = spec.id;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _updateDoctorData() async {
    if (!_formKey.currentState!.validate() || _selectedSpecId == null) return;
    
    setState(() => _isSaving = true);
    try {
      final updateModel = UpdateDoctorModel(
        firstName: _fNameController.text,
        lastName: _lNameController.text,
        phoneNumber: _phoneController.text,
        gender: _gender,
        dateOfBirth: _dobController.text,
        experienceYears: double.tryParse(_expController.text) ?? 0,
        consultationFee: double.tryParse(_feeController.text) ?? 0,
        specializationId: _selectedSpecId!,
        biography: _biographyController.text,
      );

      final success = await _apiService.updateDoctor(widget.doctorId, updateModel);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor profile updated!"), backgroundColor: Colors.green));
          _fetchInitialData(); 
        } else {
          throw "Update failed.";
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _manageSchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleManagerSheet(
        doctorId: widget.doctorId,
        onSaved: _fetchInitialData,
      ),
    );
  }

  Future<void> _clearSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear Schedule?"),
        content: const Text("This will delete all work hours for this doctor."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE ALL", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _apiService.deleteDoctorSchedule(widget.doctorId);
      _fetchInitialData();
    }
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient matching Login
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
          
          _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                              // Header Icon / Image like Login
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_note_rounded, size: 50, color: primaryColor),
                              ),
                              const SizedBox(height: 20),
                              const Text("Update Profile",
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)),
                              Text("Dr. ${_currentProfile?.firstName} ${_currentProfile?.lastName}",
                                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
                              const SizedBox(height: 35),

                              // --- Sections ---
                              _buildSectionTitle("PERSONAL INFORMATION"),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(child: _buildLoginField(controller: _fNameController, label: "First Name", icon: Icons.person_outline)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildLoginField(controller: _lNameController, label: "Last Name", icon: Icons.person_outline)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildLoginField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildLoginField(
                                      controller: _dobController,
                                      label: "Birth Date",
                                      icon: Icons.calendar_month_rounded,
                                      readOnly: true,
                                      onTap: () async {
                                        DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(1990),
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
                              const SizedBox(height: 15),
                              _buildLoginField(controller: _addressController, label: "Address", icon: Icons.location_on_outlined),

                              const SizedBox(height: 30),
                              _buildSectionTitle("PROFESSIONAL DETAILS"),
                              const SizedBox(height: 15),
                              _buildDropdownField<int>(
                                label: "Specialization",
                                icon: Icons.category_outlined,
                                initialValue: _selectedSpecId,
                                items: _specializations.map((spec) => DropdownMenuItem(value: spec.id, child: Text(spec.name, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setState(() => _selectedSpecId = val),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(child: _buildLoginField(controller: _expController, label: "Experience", icon: Icons.work_outline, keyboardType: TextInputType.number)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildLoginField(controller: _feeController, label: "Fee (EGP)", icon: Icons.payments_outlined, keyboardType: TextInputType.number)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildLoginField(controller: _biographyController, label: "Biography", icon: Icons.description_outlined, maxLines: 3),

                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle("WORK SCHEDULE"),
                                  if (_schedules.isNotEmpty)
                                    TextButton(
                                      onPressed: _clearSchedule,
                                      child: const Text("Clear All", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildScheduleList(),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _manageSchedule,
                                  icon: const Icon(Icons.add_alarm_rounded, size: 18),
                                  label: const Text("ADD / UPDATE HOURS"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: const BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                              // Save Button like LOGIN
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _updateDoctorData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5,
                                  ),
                                  child: _isSaving 
                                      ? const CircularProgressIndicator(color: Colors.white) 
                                      : const Text("SAVE CHANGES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: primaryColor.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("No schedule set yet.", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
      );
    }
    return Column(
      children: _schedules.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: primaryColor, size: 16),
            const SizedBox(width: 10),
            Text(s.getDayName(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text("${s.startTime} - ${s.endTime}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLoginField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5)
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
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
      ),
    );
  }
}

class _ScheduleManagerSheet extends StatefulWidget {
  final String doctorId;
  final VoidCallback onSaved;
  const _ScheduleManagerSheet({required this.doctorId, required this.onSaved});

  @override
  State<_ScheduleManagerSheet> createState() => _ScheduleManagerSheetState();
}

class _ScheduleManagerSheetState extends State<_ScheduleManagerSheet> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;
  int _selectedDay = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final data = {
      "dayOfWeek": _selectedDay,
      "startTime": "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00",
      "endTime": "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00",
      "isAvailable": true
    };

    final response = await _apiService.createDoctorSchedule(widget.doctorId, data);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message), backgroundColor: response.success ? Colors.green : Colors.red));
      if (response.success) {
        widget.onSaved();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Schedule Setting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 20),
              _buildDropdownField<int>(
                label: "Select Day",
                icon: Icons.calendar_view_day_rounded,
                initialValue: _selectedDay,
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Sunday")),
                  DropdownMenuItem(value: 1, child: Text("Monday")),
                  DropdownMenuItem(value: 2, child: Text("Tuesday")),
                  DropdownMenuItem(value: 3, child: Text("Wednesday")),
                  DropdownMenuItem(value: 4, child: Text("Thursday")),
                  DropdownMenuItem(value: 5, child: Text("Friday")),
                  DropdownMenuItem(value: 6, child: Text("Saturday")),
                ],
                onChanged: (v) => setState(() => _selectedDay = v!),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerField(
                      label: "From",
                      time: _startTime,
                      onTap: () async { 
                        final t = await showTimePicker(context: context, initialTime: _startTime); 
                        if (t != null) setState(() => _startTime = t); 
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTimePickerField(
                      label: "To",
                      time: _endTime,
                      onTap: () async { 
                        final t = await showTimePicker(context: context, initialTime: _endTime); 
                        if (t != null) setState(() => _endTime = t); 
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, 
                height: 55, 
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save, 
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), 
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE SCHEDULE", style: TextStyle(fontWeight: FontWeight.bold))
                )
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerField({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(time.format(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
          ],
        ),
      ),
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
      ),
    );
  }
}
