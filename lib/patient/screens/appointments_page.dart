import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/PaymentModel.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/constants/api_constants.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppointmentsPage extends StatefulWidget {
  final String? userId;
  const AppointmentsPage({super.key, this.userId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final ApiService _apiService = ApiService();
  late Future<List<PatientAppointmentModel>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    String idToFetch = widget.userId ?? "1";
    _appointmentsFuture = _apiService.getPatientAppointments(idToFetch);
  }

  Future<void> _refreshAppointments() async {
    setState(() {
      _loadAppointments();
    });
    try {
      await _appointmentsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: _refreshAppointments,
          child: FutureBuilder<List<PatientAppointmentModel>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }
              if (snapshot.hasError) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Error: ${snapshot.error}\n\nSwipe down to retry", textAlign: TextAlign.center),
                  ),
                );
              }

              final appointments = (snapshot.data ?? [])
                  .where((a) => a.status.toLowerCase() == 'pending')
                  .toList();

              // Sort appointments by date
              appointments.sort((a, b) {
                try {
                  DateTime dateA = DateTime.parse(a.appointmentDate);
                  DateTime dateB = DateTime.parse(b.appointmentDate);
                  return dateA.compareTo(dateB);
                } catch (e) {
                  return 0;
                }
              });

              if (appointments.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: const Text("No pending appointments found\n\nSwipe down to refresh", textAlign: TextAlign.center),
                  ),
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return AppointmentCard(
                    appointmentId: appointment.appointmentId,
                    name: "Dr. ${appointment.doctorName}",
                    spec: appointment.dayOfWeek,
                    date: appointment.appointmentDate,
                    time: "${appointment.startTime} - ${appointment.endTime}",
                    status: appointment.status,
                    queue: appointment.queueNumber,
                    imageUrl: appointment.doctorImageUrl,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class AppointmentCard extends StatefulWidget {
  final String appointmentId;
  final String name;
  final String spec;
  final String date;
  final String time;
  final String status;
  final int queue;
  final String? imageUrl;

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.name,
    required this.spec,
    required this.date,
    required this.time,
    required this.status,
    required this.queue,
    this.imageUrl,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  final ApiService _apiService = ApiService();
  PaymentModel? _payment;
  bool _isPaymentLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayment();
  }

  Future<void> _fetchPayment() async {
    try {
      final payment = await _apiService.getPaymentByAppointment(widget.appointmentId);
      if (mounted) {
        setState(() {
          _payment = payment;
          _isPaymentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _payment = null;
          _isPaymentLoading = false;
        });
      }
    }
  }

  void _showQRCode(BuildContext context) {
    final String qrData = jsonEncode({
      "appointmentId": widget.appointmentId,
      "doctor": widget.name,
      "date": widget.date,
      "queue": widget.queue,
      if (_payment != null) "paymentMethod": _payment!.paymentMethod,
      if (_payment != null) "paymentStatus": _payment!.paymentStatus,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Appointment QR Code", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Present this code at the hospital reception.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (_payment != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _payment!.paymentStatus.toLowerCase() == 'completed'
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    size: 14,
                    color: _payment!.paymentStatus.toLowerCase() == 'completed'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${_payment!.paymentStatus} · ${_payment!.paymentMethod}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _payment!.paymentStatus.toLowerCase() == 'completed'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // التعديل الأول: دالة لقص الثواني من الوقت
  String _formatTimeRange(String timeString) {
    try {
      final parts = timeString.split('-');
      if (parts.length == 2) {
        final start = parts[0].trim().substring(0, 5); // بياخد الـ HH:MM بس
        final end = parts[1].trim().substring(0, 5);
        return "$start - $end";
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget profileImage;
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      String fullImageUrl = widget.imageUrl!.startsWith('http') ? widget.imageUrl! : "${ApiConstants.serverUrl}${widget.imageUrl}";
      profileImage = ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          fullImageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: primaryColor, size: 30),
        ),
      );
    } else {
      profileImage = const Icon(Icons.person, color: primaryColor, size: 30);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: profileImage,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.spec,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showQRCode(context),
                icon: const Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 28),
                tooltip: "Show QR Code",
              ),
            ],
          ),
          const Divider(height: 30),

          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildInfoItem(context, Icons.calendar_today_rounded, widget.date),
                _buildInfoItem(context, Icons.access_time_rounded, _formatTimeRange(widget.time)),
                _buildInfoItem(context, Icons.format_list_numbered_rounded, "Queue #${widget.queue}"),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // Payment Status Badge
          _buildPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_isPaymentLoading) {
      return const SizedBox(
        height: 24,
        child: Row(
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
            SizedBox(width: 8),
            Text("Checking payment...", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_payment == null) {
      return _buildPaymentBadge(
        icon: Icons.money_off_rounded,
        label: "Not Paid",
        color: Colors.red.shade600,
      );
    }

    final isPaid = _payment!.paymentStatus.toLowerCase() == 'completed';
    return _buildPaymentBadge(
      icon: isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
      label: isPaid
          ? "Paid · ${_payment!.paymentMethod}"
          : "Pending · ${_payment!.paymentMethod}",
      color: isPaid ? Colors.green.shade600 : Colors.orange.shade700,
    );
  }

  Widget _buildPaymentBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // التعديل التالت: شيلنا الـ Expanded من هنا عشان الـ Wrap يشتغل صح والعناصر تاخد مساحتها الطبيعية
  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
        ),
      ],
    );
  }
}