import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/MedicalRecordModel.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/patient/screens/profile.dart'; 
import 'package:intl/intl.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final String? doctorId;
  const DoctorAppointmentsPage({super.key, this.doctorId});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final ApiService _apiService = ApiService();
  
  // State Management
  List<DoctorAppointmentModel> _allAppointments = [];
  List<DoctorScheduleModel> _schedule = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;
  
  String _selectedDay = "All";
  String _searchQuery = ""; 
  final TextEditingController _searchController = TextEditingController();

  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();

  final List<String> _weekDaysOrder = [
    "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String idToFetch = widget.doctorId ?? "1";
      final results = await Future.wait([
        _apiService.getDoctorAppointments(idToFetch),
        _apiService.getDoctorSchedule(idToFetch),
      ]);

      if (mounted) {
        setState(() {
          _allAppointments = results[0] as List<DoctorAppointmentModel>;
          _schedule = results[1] as List<DoctorScheduleModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Local Filtering Logic
  List<DoctorAppointmentModel> get _filteredAppointments {
    return _allAppointments.where((a) {
      bool matchesDay = _selectedDay == "All" || a.dayOfWeek == _selectedDay;
      bool matchesSearch = a.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDay && matchesSearch;
    }).toList()
      ..sort((a, b) {
        int dateCompare = a.appointmentDate.compareTo(b.appointmentDate);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
  }

  Future<void> _updateStatus(String id, bool isAccept, {DoctorAppointmentModel? appointment}) async {
    setState(() => _isProcessing = true);
    try {
      // تنفيذ القبول أو الإلغاء في السيرفر أولاً
      bool success = isAccept 
          ? await _apiService.completeAppointmentStatus(id)
          : await _apiService.cancelAppointmentStatus(id);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccept ? "Appointment Completed!" : "Appointment Cancelled!"),
            backgroundColor: isAccept ? Colors.green : Colors.red,
          ),
        );
        
        await _fetchData(); // تحديث القائمة

        // بعد نجاح القبول (Accept)، نفتح نافذة السجل الطبي
        if (isAccept && appointment != null) {
          _showMedicalRecordDialog(appointment);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _navigateToProfile(DoctorAppointmentModel app) {
    if (app.patientId.isNotEmpty && app.patientId != "0") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: app.patientId, readOnly: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("بيانات المريض غير مكتملة (ID Missing)"), backgroundColor: Colors.orange),
      );
    }
  }

  void _showMedicalRecordDialog(DoctorAppointmentModel appointment, {MedicalRecordModel? existingRecord}) {
    _diagnosisController.text = existingRecord?.diagnosis ?? "";
    _prescriptionController.text = existingRecord?.prescription ?? "";
    bool isEdit = existingRecord != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? "Edit Medical Record" : "Medical Record - ${appointment.patientName}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: "Diagnosis", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _prescriptionController,
                decoration: const InputDecoration(labelText: "Prescription", border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (_diagnosisController.text.isEmpty || _prescriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                return;
              }
              Navigator.pop(context);
              setState(() => _isProcessing = true);
              try {
                bool success;
                if (isEdit) {
                  // تحديث سجل موجود
                  success = await _apiService.updateMedicalRecord(
                    existingRecord!.medicalRecordId, 
                    _diagnosisController.text, 
                    _prescriptionController.text
                  );
                } else {
                  // إضافة سجل جديد - الموعد تم إكماله بالفعل قبل فتح هذا الحوار
                  success = await _apiService.createMedicalRecord(
                    CreateMedicalRecordModel(
                      appointmentId: appointment.appointmentId,
                      diagnosis: _diagnosisController.text,
                      prescription: _prescriptionController.text,
                    ),
                  );
                }
                
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? "Record updated!" : "Medical history added!"), backgroundColor: Colors.green)
                  );
                  _fetchData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: Text(isEdit ? "UPDATE" : "SAVE RECORD"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = _filteredAppointments;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchField(), 
                  const SizedBox(height: 20),
                  _buildDayFilterSection(),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Appointments List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: primaryColor),
                    ))
                  else if (_errorMessage != null)
                    Center(child: Column(
                      children: [
                        Text("Error: $_errorMessage"),
                        ElevatedButton(onPressed: _fetchData, child: const Text("Retry"))
                      ],
                    ))
                  else if (apps.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("No appointments found"),
                    ))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: apps.map((app) => _buildAppointmentCard(app)).toList(),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_isProcessing)
              Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: primaryColor))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Appointments", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text("${_filteredAppointments.length} Appts", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search patient...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              }) 
            : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDayFilterSection() {
    List<String> workDays = _schedule.map((s) => s.getDayName()).toSet().toList();
    workDays.sort((a, b) => _weekDaysOrder.indexOf(a).compareTo(_weekDaysOrder.indexOf(b)));
    List<String> options = ["All", ...workDays];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Filter by Day", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: options.map((day) => _buildFilterItem(day)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterItem(String title) {
    bool isSelected = _selectedDay == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
        ),
        child: Text(
          title, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700, 
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(DoctorAppointmentModel app) {
    final bool isFinalized = app.status == "Completed" || app.status == "Cancelled";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(22), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToProfile(app),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Text(app.patientName.isNotEmpty ? app.patientName[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                const SizedBox(width: 5),
                                const Icon(Icons.contact_page_outlined, size: 16, color: Colors.grey),
                              ],
                            ),
                            Text("${app.dayOfWeek}, ${app.appointmentDate}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            Text(app.status, style: TextStyle(color: _getStatusColor(app.status), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text("${app.startTime} - ${app.endTime}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("Q No: ${app.queueNumber}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (!isFinalized) ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Cancel"))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton(onPressed: _isProcessing ? null : () => _updateStatus(app.appointmentId, true, appointment: app), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Accept"))),
                      ],
                    ),
                  ],
                  if (app.status == "Completed") ...[
                    const SizedBox(height: 10),
                    TextButton.icon(onPressed: () => _fetchAndEditRecord(app), icon: const Icon(Icons.edit_note, color: primaryColor), label: const Text("Edit Medical Record", style: TextStyle(color: primaryColor))),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Future<void> _fetchAndEditRecord(DoctorAppointmentModel appointment) async {
    setState(() => _isProcessing = true);
    try {
      final record = await _apiService.getMedicalRecordByAppointment(appointment.appointmentId);
      if (mounted) _showMedicalRecordDialog(appointment, existingRecord: record);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
