import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:mediconnect/doctor_profile_screen.dart';

class BookingScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String fee;
  final List<String> availableDays;

  const BookingScreen({
    super.key,
    this.doctorId = "1", // Default ID for testing
    this.doctorName = "Dr. Adam Doma",
    this.specialty = "Senior Dentist",
    this.fee = "1000",
    this.availableDays = const ["Monday", "Wednesday", "Friday"],
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  int? selectedPaymentIndex;

  // Simulation of available dates based on doctor's available days
  List<DateTime> getAvailableDates() {
    List<DateTime> dates = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      DateTime date = now.add(Duration(days: i));
      String dayName = DateFormat('EEEE').format(date);
      if (widget.availableDays.contains(dayName)) {
        dates.add(date);
      }
    }
    return dates;
  }

  @override
  void initState() {
    super.initState();
    List<DateTime> available = getAvailableDates();
    if (available.isNotEmpty) {
      selectedDate = available.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> availableDates = getAvailableDates();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("Book Appointment",
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  _buildDateSelector(availableDates),
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: const Icon(Icons.medical_services_rounded,
                color: primaryColor, size: 35),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.doctorName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(widget.specialty,
                            style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorProfileScreen(doctorId: widget.doctorId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: primaryColor, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: const [
                    Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                    Text(" 4.8", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(" (120 Reviews)",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
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
          bool isSelected = selectedDate?.day == date.day &&
              selectedDate?.month == date.month &&
              selectedDate?.year == date.year;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade200),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date),
                      style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(date.day.toString(),
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text("Estimated Turn",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("#12",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Approx. Time: 07:30 PM",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          const Text(
              "* Please arrive 15 minutes before the estimated time.",
              style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Consultation Fee", "${widget.fee} EGP"),
          const SizedBox(height: 10),
          _buildSummaryRow("Booking Fee", "50 EGP"),
          const Divider(height: 25),
          _buildSummaryRow("Total Amount", "${int.parse(widget.fee) + 50} EGP",
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal ? Colors.black87 : Colors.grey,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: isTotal ? primaryColor : Colors.black87,
                fontSize: isTotal ? 18 : 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: (selectedDate == null) ? null : () => _showPaymentSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text("PAY & BOOK NOW",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Payment Method",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildPaymentOption(
                index: 0,
                icon: Icons.payments_rounded,
                title: "Cash at Clinic",
                subtitle: "Pay when you arrive",
                selected: selectedPaymentIndex == 0,
                onTap: () => setModalState(() => selectedPaymentIndex = 0),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                index: 1,
                icon: Icons.credit_card_rounded,
                title: "Credit / Debit Card",
                subtitle: "Visa, Mastercard, etc.",
                selected: selectedPaymentIndex == 1,
                onTap: () => setModalState(() => selectedPaymentIndex = 1),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                index: 2,
                icon: Icons.account_balance_wallet_rounded,
                title: "Digital Wallet",
                subtitle: "Vodafone Cash, Fawry, etc.",
                selected: selectedPaymentIndex == 2,
                onTap: () => setModalState(() => selectedPaymentIndex = 2),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: selectedPaymentIndex == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showSuccessBooking();
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  child: const Text("CONFIRM BOOKING",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: selected ? primaryColor : Colors.grey.shade200,
              width: selected ? 2 : 1),
          color: selected ? primaryColor.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: selected ? primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessBooking() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: const Center(
                child: Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 80),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Text("Booking Successful!",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildResponseItem("Doctor Name", widget.doctorName),
                  _buildResponseItem("Appointment Date",
                      DateFormat('yyyy-MM-dd').format(selectedDate!)),
                  _buildResponseItem(
                      "Day of Week", DateFormat('EEEE').format(selectedDate!)),
                  _buildResponseItem("Start Time", "07:30:00"),
                  _buildResponseItem("End Time", "08:00:00"),
                  _buildResponseItem("Status", "Pending", isStatus: true),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("DONE",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseItem(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isStatus ? Colors.orange : Colors.black87,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}
