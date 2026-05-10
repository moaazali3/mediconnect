import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:mediconnect/services/api_service.dart';

class EditReceptionistManagementPage extends StatefulWidget {
  final String receptionistId;
  const EditReceptionistManagementPage({super.key, required this.receptionistId});

  @override
  State<EditReceptionistManagementPage> createState() => _EditReceptionistManagementPageState();
}

class _EditReceptionistManagementPageState extends State<EditReceptionistManagementPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // الخطوة الحالية
  int _currentStep = 1;

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _doctorController = TextEditingController();

  String _gender = 'Male';
  String? _selectedDoctorId;
  String? _initialDoctorId;
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _changeDoctor = false;

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
    _dobController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getReceptionistProfile(widget.receptionistId),
        _apiService.getDoctorNames(),
      ]);

      final profile = results[0] as ReceptionistProfileModel;
      _doctors = results[1] as List<Map<String, dynamic>>;

      _fNameController.text = profile.firstName;
      _lNameController.text = profile.lastName;
      _phoneController.text = profile.phoneNumber;
      _emailController.text = profile.email ?? '';
      _dobController.text = profile.dateOfBirth?.split('T')[0] ?? '';
      _addressController.text = profile.address ?? '';
      _gender = profile.gender ?? 'Male';

      String? foundId = profile.doctorId?.toString();
      String doctorNameDisplay = "Not Assigned";

      if (foundId != null && (foundId.isEmpty || foundId == "0")) foundId = null;

      bool idInList = _doctors.any((d) => (d['doctorId']?.toString() ?? d['id']?.toString()) == foundId);

      if (!idInList && profile.doctorName != null && profile.doctorName!.isNotEmpty) {
        final String pName = profile.doctorName!.toLowerCase().trim();
        final match = _doctors.firstWhere(
              (d) {
            final String dName = (d['doctorName'] ?? d['name'])?.toString().toLowerCase().trim() ?? "";
            return dName == pName || dName == "dr. $pName" || pName == "dr. $dName";
          },
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          foundId = (match['doctorId'] ?? match['id'])?.toString();
          doctorNameDisplay = "Dr. ${(match['doctorName'] ?? match['name'])}";
        }
      } else if (idInList) {
        final match = _doctors.firstWhere((d) => (d['doctorId']?.toString() ?? d['id']?.toString()) == foundId);
        doctorNameDisplay = "Dr. ${(match['doctorName'] ?? match['name'])}";
      }

      setState(() {
        _selectedDoctorId = foundId;
        _initialDoctorId = foundId;
        if (foundId != null) {
          _doctorController.text = doctorNameDisplay;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showDoctorSearchSheet() {
    List<Map<String, dynamic>> tempFiltered = List.from(_doctors);

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
                  const Text("Select Assigned Doctor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 15),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search doctor name...",
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                      filled: true,
                      fillColor: context.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        tempFiltered = _doctors.where((doc) {
                          final name = (doc['doctorName'] ?? doc['name'])?.toString().toLowerCase() ?? '';
                          return name.contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: tempFiltered.isEmpty
                        ? const Center(child: Text("No doctors found"))
                        : ListView.separated(
                      itemCount: tempFiltered.length,
                      separatorBuilder: (context, index) => Divider(color: context.dividerCol),
                      itemBuilder: (context, index) {
                        final doc = tempFiltered[index];
                        final id = (doc['doctorId'] ?? doc['id'])?.toString();
                        final name = (doc['doctorName'] ?? doc['name'])?.toString() ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.medical_services, color: primaryColor),
                          ),
                          title: Text("Dr. $name", style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () {
                            setState(() {
                              _selectedDoctorId = id;
                              _doctorController.text = "Dr. $name";
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

  Future<void> _updateReceptionist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final success = await _apiService.updateReceptionistAsAdmin(
        widget.receptionistId,
        firstName: _fNameController.text,
        lastName: _lNameController.text,
        phoneNumber: _phoneController.text,
        gender: _gender,
        dateOfBirth: _dobController.text,
        address: _addressController.text,
      );

      if (mounted) {
        if (success) {
          if (_changeDoctor && _selectedDoctorId != null && _selectedDoctorId != _initialDoctorId) {
            await _apiService.changeReceptionistDoctor(widget.receptionistId, _selectedDoctorId!);
          }
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receptionist profile updated!"), backgroundColor: Colors.green));
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
    String title = _currentStep == 1 ? "Personal Info" : "Additional Info";
    IconData icon = _currentStep == 1 ? Icons.person_outline : Icons.assignment_ind_outlined;

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

  // --- الخطوة الأولى: 4 خانات أساسية ---
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
          ],
        );
      },
    );
  }

  // --- الخطوة التانية: 4 خانات إضافية والتخصيص ---
  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      children: [
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
              initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(1995),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
            }
          },
        ),
        const SizedBox(height: 15),
        _buildLoginField(controller: _addressController, label: "Address", icon: Icons.location_on_outlined),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: context.inputFill,
            borderRadius: BorderRadius.circular(15),
          ),
          child: SwitchListTile(
            title: const Text("Change Assigned Doctor?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            value: _changeDoctor,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() {
                _changeDoctor = val;
                if (!val) {
                  _selectedDoctorId = _initialDoctorId;
                }
              });
            },
          ),
        ),
        if (_changeDoctor) ...[
          const SizedBox(height: 15),
          _buildLoginField(
            controller: _doctorController,
            label: "Select New Doctor",
            icon: Icons.medical_services_outlined,
            readOnly: true,
            onTap: _showDoctorSearchSheet,
          ),
        ],
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
            onPressed: _currentStep == 1 ? _nextStep : (_isSaving ? null : _updateReceptionist),
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
        if (isPassword) return null; // password is optional
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