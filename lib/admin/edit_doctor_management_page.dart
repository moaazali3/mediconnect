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
        orElse: () => _specializations.first,
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor info updated!"), backgroundColor: Colors.green));
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Dr. ${_currentProfile?.lastName ?? ''}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Personal Info"),
              const SizedBox(height: 12),
              _buildIdentityCard(),
              const SizedBox(height: 25),
              _buildSectionTitle("Professional Settings"),
              const SizedBox(height: 12),
              _buildProfessionalCard(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Work Schedule"),
                  if (_schedules.isNotEmpty)
                    TextButton(onPressed: _clearSchedule, child: const Text("Clear All", style: TextStyle(color: Colors.red))),
                ],
              ),
              const SizedBox(height: 10),
              _buildScheduleList(),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _manageSchedule,
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text("ADD / UPDATE WORK HOURS"),
                  style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: const BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _buildIdentityCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_fNameController, "First Name", Icons.person_outline)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_lNameController, "Last Name", Icons.person_outline)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(_phoneController, "Phone Number", Icons.phone_android_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildTextField(_addressController, "Address", Icons.location_on_outlined),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: "Gender", prefixIcon: Icon(Icons.wc_rounded, color: primaryColor, size: 20), border: OutlineInputBorder()),
                    items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _dobController,
                    "Birth Date",
                    Icons.calendar_month_rounded,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _selectedSpecId,
              decoration: const InputDecoration(labelText: "Specialization", prefixIcon: Icon(Icons.category_rounded, color: primaryColor), border: OutlineInputBorder()),
              items: _specializations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (val) => setState(() => _selectedSpecId = val),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField(_expController, "Experience", Icons.work_outline, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_feeController, "Fee (EGP)", Icons.payments_rounded, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(_biographyController, "Biography", Icons.description_rounded, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateDoctorData,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_schedules.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No schedule set yet.", style: TextStyle(color: Colors.grey))));
    return Column(
      children: _schedules.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.calendar_today, color: primaryColor, size: 20),
          title: Text(s.getDayName(), style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text("${s.startTime} - ${s.endTime}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        ),
      )).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: primaryColor, size: 20), border: const OutlineInputBorder()),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Work Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _selectedDay,
            decoration: const InputDecoration(labelText: "Select Day"),
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
          Row(
            children: [
              Expanded(child: ListTile(title: const Text("From"), subtitle: Text(_startTime.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: _startTime); if (t != null) setState(() => _startTime = t); })),
              Expanded(child: ListTile(title: const Text("To"), subtitle: Text(_endTime.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: _endTime); if (t != null) setState(() => _endTime = t); })),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSaving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE SCHEDULE"))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
