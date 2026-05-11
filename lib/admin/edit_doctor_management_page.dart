import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
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

  // الخطوة الحالية
  int _currentStep = 1;

  // Controllers
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _feeController = TextEditingController();
  final _expController = TextEditingController();
  final _dobController = TextEditingController();
  final _specializationController = TextEditingController();

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
    _expController.dispose();
    _dobController.dispose();
    _specializationController.dispose();
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
      _specializationController.text = spec.name;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
                    decoration: BoxDecoration(color: context.dividerCol, borderRadius: BorderRadius.circular(10)),
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
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.category, color: primaryColor),
                          ),
                          title: Text(spec.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () {
                            setState(() {
                              _selectedSpecId = spec.id;
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
      );

      final success = await _apiService.updateDoctor(widget.doctorId, updateModel);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor profile updated!"), backgroundColor: Colors.green));

          // التعديل هنا: الخروج من الصفحة مباشرة بعد الحفظ بنجاح
          Navigator.pop(context, true);

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

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    setState(() => _currentStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (_currentStep == 2) {
              _previousStep();
            } else {
              Navigator.pop(context, true);
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

          _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        color: context.cardBg.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: context.dividerCol),
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
                              child: _currentStep == 1
                                  ? _buildStep1()
                                  : _buildStep2(),
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
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    String title = _currentStep == 1 ? "Personal Info" : "Professional Details";
    IconData icon = _currentStep == 1 ? Icons.person_outline : Icons.medical_services_outlined;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepIndicator(1),
            Container(width: 50, height: 2, color: _currentStep == 2 ? Colors.green : context.dividerCol),
            _buildStepIndicator(2),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: primaryColor),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
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
        color: isCompleted ? Colors.green : (isActive ? primaryColor : context.dividerCol),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text("$step", style: TextStyle(color: isActive ? Colors.white : context.subText, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildStep1() {
    return StatefulBuilder(
      key: const ValueKey(1),
      builder: (context, setLocalState) {
        return Column(
          children: [
            _buildLoginField(controller: _fNameController, label: "First Name", icon: Icons.person_outline),
            const SizedBox(height: 15),
            _buildLoginField(controller: _lNameController, label: "Last Name", icon: Icons.person_outline),
            const SizedBox(height: 15),
            _buildLoginField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildDropdownField<String>(
              label: "Gender",
              icon: Icons.wc_rounded,
              initialValue: _gender,
              items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) => setState(() => _gender = val!),
            ),
            const SizedBox(height: 15),
            _buildLoginField(
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
          ],
        );
      },
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      children: [
        _buildLoginField(
          controller: _specializationController,
          label: "Specialization",
          icon: Icons.category_outlined,
          readOnly: true,
          onTap: _showSpecializationSearchSheet,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildLoginField(controller: _expController, label: "Experience", icon: Icons.work_outline, keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _buildLoginField(controller: _feeController, label: "Fee (EGP)", icon: Icons.payments_outlined, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("WORK SCHEDULE", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.2)),
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
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep == 2)
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
        if (_currentStep == 2) const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _currentStep == 1 ? _nextStep : (_isSaving ? null : _updateDoctorData),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
              _currentStep == 1 ? "NEXT STEP" : "SAVE CHANGES",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    if (_schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text("No schedule set yet.", style: TextStyle(color: context.subText, fontSize: 13), textAlign: TextAlign.center),
      );
    }
    return Column(
      children: _schedules.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerCol),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: primaryColor, size: 16),
            const SizedBox(width: 10),
            Text(s.getDayName(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text("${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
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
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggle,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: isPassword && isObscured,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: context.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.subText, fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor, size: 20),
                onPressed: onToggle,
              )
            : (onTap != null)
                ? Icon(Icons.arrow_drop_down_rounded, color: context.subText)
                : null,
        filled: true,
        fillColor: context.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.dividerCol)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5)
        ),
      ),
      validator: (v) {
        if (isPassword) return null;
        return (v == null || v.isEmpty) ? "Required" : null;
      },
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
      style: TextStyle(fontSize: 14, color: context.onSurface),
      dropdownColor: context.cardBg,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.subText, fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        filled: true,
        fillColor: context.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.dividerCol)
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
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.dividerCol, borderRadius: BorderRadius.circular(2))),
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
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: context.subText)),
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
      style: TextStyle(fontSize: 14, color: context.onSurface),
      dropdownColor: context.cardBg,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.subText, fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        filled: true,
        fillColor: context.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.dividerCol)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5)
        ),
      ),
    );
  }
}