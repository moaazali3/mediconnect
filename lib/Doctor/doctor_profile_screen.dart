import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/Doctor/edit_doctor_profile.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:image_picker/image_picker.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isUploading = false;
  bool _isLoading = true;
  DoctorModel? _doctor;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await _apiService.getAllDoctors();
      setState(() {
        _doctor = doctors.firstWhere((d) => d.id == widget.doctorId);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  int _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
      return age;
    } catch (_) { return 0; }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final success = await _apiService.uploadDoctorImage(widget.doctorId, image.path);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image updated!"), backgroundColor: Colors.green));
          _fetchProfile();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _manageSchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _ScheduleManagerSheet(
        doctorId: widget.doctorId,
        existingSchedules: _doctor?.doctorSchedules ?? [],
        onSaved: _fetchProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
    if (_doctor == null) return const Scaffold(body: Center(child: Text("Profile not found")));

    final String displayImage = (_doctor!.profilePictureUrl != null && _doctor!.profilePictureUrl!.isNotEmpty)
        ? _doctor!.profilePictureUrl!
        : "https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(displayImage),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(_doctor!),
                  const SizedBox(height: 15),
                  _buildStatusCard(_doctor!.isAppleToAppointment),
                  const SizedBox(height: 25),
                  _buildSectionTitleWithAction("Work Schedule", Icons.edit_calendar_rounded, _manageSchedule),
                  _buildScheduleCard(_doctor!.doctorSchedules),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Professional Details"),
                  _buildInfoCard([
                    _buildInfoRow(Icons.payments_rounded, "Consultation Fee", "${_doctor!.consultationFee} EGP"),
                    _buildDivider(),
                    _buildInfoRow(Icons.work_history_rounded, "Experience", "${_doctor!.experienceYears} Years"),
                    _buildDivider(),
                    _buildInfoRow(Icons.description_rounded, "Biography", _doctor!.biography),
                  ]),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Personal Info"),
                  _buildInfoCard([
                    _buildInfoRow(Icons.cake_rounded, "Age", "${_calculateAge(_doctor!.dateOfBirth)} Years"),
                    _buildDivider(),
                    _buildInfoRow(Icons.wc_rounded, "Gender", _doctor!.gender),
                  ]),
                  const SizedBox(height: 35),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String imageUrl) {
    return SliverAppBar(
      expandedHeight: 200, pinned: true, backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [primaryColor, Color(0xFF00397F)]))),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 65, backgroundColor: Colors.white24, child: CircleAvatar(radius: 60, backgroundImage: NetworkImage(imageUrl))),
                CircleAvatar(radius: 18, backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: primaryColor), onPressed: _pickAndUploadImage)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(DoctorModel doctor) {
    return Center(child: Column(children: [
      Text("Dr. ${doctor.firstName} ${doctor.lastName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Text(doctor.specializationName, style: const TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w500)),
    ]));
  }

  Widget _buildStatusCard(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15), border: Border.all(color: isAvailable ? Colors.green : Colors.red, width: 0.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.circle, size: 12, color: isAvailable ? Colors.green : Colors.red),
        const SizedBox(width: 10),
        Text(isAvailable ? "You are receiving appointments" : "Appointments are currently disabled", style: TextStyle(color: isAvailable ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Widget _buildScheduleCard(List<DoctorScheduleModel> schedules) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: schedules.isEmpty 
        ? const ListTile(title: Text("No work hours set", style: TextStyle(color: Colors.grey)))
        : Column(children: schedules.map((s) => ListTile(
            leading: const Icon(Icons.calendar_today_outlined, size: 18, color: primaryColor),
            title: Text(s.getDayName(), style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text("${s.startTime} - ${s.endTime}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          )).toList()),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 5, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _buildSectionTitleWithAction(String title, IconData icon, VoidCallback onTap) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _buildSectionTitle(title),
      IconButton(icon: Icon(icon, color: primaryColor, size: 20), onPressed: onTap),
    ]);
  }

  Widget _buildInfoCard(List<Widget> children) => Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]), child: Column(children: children));

  Widget _buildInfoRow(IconData icon, String label, String value) => ListTile(leading: Icon(icon, color: primaryColor, size: 20), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _buildDivider() => Divider(height: 1, indent: 50, endIndent: 20, color: Colors.grey.shade100);

  Widget _buildActionButtons() {
    return Column(children: [
      SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Update Professional Info", style: TextStyle(fontWeight: FontWeight.bold)))),
      const SizedBox(height: 15),
      TextButton.icon(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (r) => false), icon: const Icon(Icons.logout, color: Colors.red), label: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
    ]);
  }
}

class _ScheduleManagerSheet extends StatefulWidget {
  final String doctorId;
  final List<DoctorScheduleModel> existingSchedules;
  final VoidCallback onSaved;
  const _ScheduleManagerSheet({required this.doctorId, required this.existingSchedules, required this.onSaved});

  @override
  State<_ScheduleManagerSheet> createState() => _ScheduleManagerSheetState();
}

class _ScheduleManagerSheetState extends State<_ScheduleManagerSheet> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;
  int _selectedDay = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedules.isNotEmpty) {
      final first = widget.existingSchedules.first;
      _selectedDay = first.dayOfWeek;
      _startTime = _parseTime(first.startTime);
      _endTime = _parseTime(first.endTime);
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) { return const TimeOfDay(hour: 9, minute: 0); }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final data = {
      "dayOfWeek": _selectedDay,
      "startTime": "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00",
      "endTime": "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00",
      "isAvailable": true
    };

    final response = widget.existingSchedules.isEmpty 
      ? await _apiService.createDoctorSchedule(widget.doctorId, data)
      : await _apiService.updateDoctorSchedule(widget.doctorId, data);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message), backgroundColor: response.success ? Colors.green : Colors.red));
      if (response.success) { widget.onSaved(); Navigator.pop(context); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.existingSchedules.isEmpty ? "Set Work Schedule" : "Update Schedule", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          value: _selectedDay, decoration: const InputDecoration(labelText: "Day of Week"),
          items: const [DropdownMenuItem(value: 0, child: Text("Sunday")), DropdownMenuItem(value: 1, child: Text("Monday")), DropdownMenuItem(value: 2, child: Text("Tuesday")), DropdownMenuItem(value: 3, child: Text("Wednesday")), DropdownMenuItem(value: 4, child: Text("Thursday")), DropdownMenuItem(value: 5, child: Text("Friday")), DropdownMenuItem(value: 6, child: Text("Saturday"))],
          onChanged: (v) => setState(() => _selectedDay = v!),
        ),
        Row(children: [
          Expanded(child: ListTile(title: const Text("From"), subtitle: Text(_startTime.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: _startTime); if (t != null) setState(() => _startTime = t); })),
          Expanded(child: ListTile(title: const Text("To"), subtitle: Text(_endTime.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: _endTime); if (t != null) setState(() => _endTime = t); })),
        ]),
        const SizedBox(height: 25),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSaving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.existingSchedules.isEmpty ? "CREATE" : "UPDATE"))),
        const SizedBox(height: 20),
      ]),
    );
  }
}
