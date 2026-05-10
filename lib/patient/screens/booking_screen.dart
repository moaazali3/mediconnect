import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';

import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mediconnect/patient/screens/doctor_profile_view_screen.dart';

class BookingScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String fee;
  final String? doctorImageUrl;
  final String? patientId;

  const BookingScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    this.fee = "500",
    this.doctorImageUrl,
    this.patientId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _apiService = ApiService();
  DateTime? selectedDate;
  int? selectedPaymentIndex;
  bool isLoading = false;

  List<DoctorScheduleModel> _doctorSchedule = [];
  double? _fetchedFee;
  String? _doctorImageUrl;
  bool _isFetchingSchedule = true;
  int? _expectedTurn;
  bool _isFetchingTurn = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    try {
      final profile = await _apiService.getDoctorDetails(widget.doctorId, widget.patientId);

      if (mounted) {
        setState(() {
          _doctorSchedule = profile.doctorSchedules;
          _fetchedFee = profile.consultationFee;
          _doctorImageUrl = profile.profilePictureUrl;
          _isFetchingSchedule = false;

          List<DateTime> available = getAvailableDates();
          if (available.isNotEmpty) {
            selectedDate = available.first;
            _fetchExpectedTurn(selectedDate!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingSchedule = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: $e")),
        );
      }
    }
  }

  Future<void> _fetchExpectedTurn(DateTime date) async {
    setState(() => _isFetchingTurn = true);
    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final turn = await _apiService.getExpectedNumber(widget.doctorId, formattedDate);
      if (mounted) {
        setState(() {
          _expectedTurn = turn;
          _isFetchingTurn = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expectedTurn = null;
          _isFetchingTurn = false;
        });
      }
    }
  }

  List<DateTime> getAvailableDates() {
    if (_doctorSchedule.isEmpty) return [];
    List<String> availableDays = _doctorSchedule.map((s) => s.getDayName()).toList();
    List<DateTime> dates = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date = now.add(Duration(days: i));
      String dayName = DateFormat('EEEE').format(date);
      if (availableDays.contains(dayName)) {
        dates.add(date);
      }
    }
    return dates;
  }

  Future<void> _performBooking() async {
    if (selectedDate == null || selectedPaymentIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date and payment method")),
      );
      return;
    }

    final String patientId = (widget.patientId != null && widget.patientId != "") ? widget.patientId! : "1";

    setState(() => isLoading = true);
    Navigator.pop(context); // Close payment sheet

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final String dayName = DateFormat('EEEE').format(selectedDate!);
      final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      final appointmentRequest = CreateAppointmentModel(
        patientId: patientId,
        doctorId: widget.doctorId,
        dayOfWeek: dayName,
        appointmentDate: formattedDate,
      );

      String? appointmentId = await _apiService.createAppointment(appointmentRequest);

      if (appointmentId != null) {
        debugPrint("Booking successful. Appointment ID: $appointmentId");

        final paymentMethods = ["Cash", "Card", "Wallet"];

        await _apiService.createPaymentByAppointment(
          appointmentId: appointmentId,
          paymentMethod: paymentMethods[selectedPaymentIndex!],
        );

        if (mounted) {
          Navigator.pop(context);
          _showSuccessBooking(appointmentId);
        }
      } else {
        throw "Failed to create appointment";
      }
    } catch (e) {
      debugPrint("Booking error: $e");
      String errorMessage = e.toString();

      // Handle duplicate booking error from backend
      if (errorMessage.toLowerCase().contains("already") ||
          errorMessage.toLowerCase().contains("appointment exists")) {
        errorMessage = "You already have an appointment with this doctor on this day.";
      }

      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccessBooking(String appointmentId) {
    final String qrData = jsonEncode({
      "appointmentId": appointmentId,
      "doctor": widget.doctorName,
      "date": DateFormat('yMMMd').format(selectedDate!),
      "queue": _expectedTurn?.toString() ?? "N/A"
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
              const SizedBox(height: 15),
              const Text("Booking Successful!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Show this QR code at the reception.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                height: 180,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180.0,
                  foregroundColor: primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              Text(widget.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> availableDates = getAvailableDates();
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const CommonAppBar(title: "Book Appointment", showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorBrief(),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Select Date"),
                  const SizedBox(height: 12),
                  _isFetchingSchedule
                      ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: primaryColor)))
                      : (availableDates.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No available dates found.")))
                      : _buildDateSelector(availableDates)),
                  const SizedBox(height: 25),
                  if (selectedDate != null) ...[
                    _buildSectionTitle("Appointment Info"),
                    const SizedBox(height: 12),
                    _buildAppointmentInfoCard(),
                    const SizedBox(height: 25),
                  ],
                  _buildSectionTitle("Payment Details"),
                  const SizedBox(height: 12),
                  _buildPaymentSummary(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildDoctorBrief() {
    final String? imageUrl = _doctorImageUrl ?? widget.doctorImageUrl;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            // التعديل هنا: استخدام الأيقونة الموحدة وتكبير حجمها ليتناسب مع الـ Avatar
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.person_rounded, color: primaryColor, size: 40)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.doctorName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.onSurface)),
                Text(widget.specialty, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: primaryColor, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorProfileViewScreen(
                    doctorId: widget.doctorId,
                    patientId: widget.patientId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: context.onSurface,
      ),
    );
  }

  Widget _buildDateSelector(List<DateTime> availableDates) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          DateTime date = availableDates[index];
          bool isSelected = selectedDate?.day == date.day && selectedDate?.month == date.month && selectedDate?.year == date.year;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
                _expectedTurn = null;
              });
              _fetchExpectedTurn(date);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : context.cardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? primaryColor : context.dividerCol,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : context.subText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : context.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentInfoCard() {
    String estimatedTime = "TBD";

    if (_expectedTurn != null && selectedDate != null && _doctorSchedule.isNotEmpty) {
      String dayName = DateFormat('EEEE').format(selectedDate!);
      try {
        var schedule = _doctorSchedule.firstWhere(
              (s) => s.getDayName().toLowerCase() == dayName.toLowerCase(),
          orElse: () => _doctorSchedule.first,
        );

        List<String> parts = schedule.startTime.split(':');
        DateTime baseTime = DateTime(
            selectedDate!.year, selectedDate!.month, selectedDate!.day,
            int.parse(parts[0]), int.parse(parts[1])
        );

        DateTime myTime = baseTime.add(Duration(minutes: (_expectedTurn! - 1) * 30));
        estimatedTime = DateFormat('hh:mm a').format(myTime);
      } catch (e) {
        estimatedTime = "Check at Hospital";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
          ),
          borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                          child: Text("Estimated Turn", style: TextStyle(color: Colors.white70, fontSize: 14), overflow: TextOverflow.ellipsis)
                      )
                    ]
                ),
              ),
              const SizedBox(width: 10),
              if (_expectedTurn != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                      Text(estimatedTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _isFetchingTurn
              ? const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : (_expectedTurn != null
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text("Queue No. ", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
              Text("$_expectedTurn", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          )
              : const Text("TBD", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          const Text("* Please arrive 15 mins before the estimated time.", style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final double currentFee = _fetchedFee ?? double.tryParse(widget.fee) ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dividerCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow("Consultation Fee", "${currentFee.toStringAsFixed(0)} EGP"),
          const SizedBox(height: 10),
          _buildSummaryRow("Booking Fee", "50 EGP"),
          const Divider(height: 25),
          _buildSummaryRow("Total Amount", "${(currentFee + 50).toStringAsFixed(0)} EGP", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? context.onSurface : context.subText,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? primaryColor : context.onSurface,
            fontSize: isTotal ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: (selectedDate == null) ? null : () => _showPaymentSheet(),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
            child: const Text("PAY & BOOK NOW", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Payment Method",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildPaymentOption(index: 0, icon: Icons.domain_rounded, title: "Pay at Hospital", subtitle: "Pay at the reception", selected: selectedPaymentIndex == 0, onTap: () => setModalState(() => selectedPaymentIndex = 0)),
              const SizedBox(height: 12),
              _buildPaymentOption(index: 1, icon: Icons.credit_card_rounded, title: "Credit / Debit Card", subtitle: "Visa, Mastercard, etc.", selected: selectedPaymentIndex == 1, onTap: () => setModalState(() => selectedPaymentIndex = 1)),
              const SizedBox(height: 12),
              _buildPaymentOption(index: 2, icon: Icons.account_balance_wallet_rounded, title: "Digital Wallet", subtitle: "Vodafone Cash, Fawry, etc.", selected: selectedPaymentIndex == 2, onTap: () => setModalState(() => selectedPaymentIndex = 2)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: selectedPaymentIndex == null ? null : _performBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("CONFIRM BOOKING", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({required int index, required IconData icon, required String title, required String subtitle, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withOpacity(0.08) : context.cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? primaryColor : context.dividerCol,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? primaryColor : context.onSurface.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : context.subText,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected ? primaryColor : context.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.subText),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: primaryColor),
          ],
        ),
      ),
    );
  }
}