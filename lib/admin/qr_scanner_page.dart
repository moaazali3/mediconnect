import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';
import 'package:mediconnect/services/api_service.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final ApiService _apiService = ApiService();
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back, // استخدام الكاميرا الخلفية بشكل صريح ومثبت
    torchEnabled: false,
  );
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    // تثبيت اتجاه الشاشة طوليًا لمنع الكاميرا من الانعكاس أو الانقلاب عند تدوير الهاتف
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() => _isScanning = false);

    final String? code = barcodes.first.rawValue;
    if (code == null) {
      _showError("Invalid QR Code: Raw value is null");
      return;
    }

    _processQRCode(code);
  }

  void _processQRCode(String code) {
    debugPrint("Scanned QR raw value: $code");
    try {
      // Expecting JSON data from the QR generated in BookingScreen/AppointmentsPage
      final Map<String, dynamic> data = jsonDecode(code);
      final String? appointmentId = data['appointmentId'];

      if (appointmentId != null) {
        debugPrint("Extracted Appointment ID: $appointmentId");
        _showAppointmentDetails(data);
      } else {
        _showError("QR code does not contain appointment ID");
      }
    } catch (e) {
      debugPrint("QR Code parsing error: $e");
      // Fallback: check if the string itself is a UUID (length > 20 as heuristic)
      if (code.length > 20) {
        debugPrint("Using fallback: Raw code as Appointment ID");
        _showAppointmentDetails({"appointmentId": code});
      } else {
        _showError("Could not parse QR code data: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final BarcodeCapture? capture = await controller.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final String? code = capture.barcodes.first.rawValue;
          if (code != null) {
            setState(() => _isScanning = false);
            _processQRCode(code);
          } else {
            _showError("No valid QR code found in the selected image");
          }
        } else {
          _showError("No QR code detected in the selected image");
        }
      } catch (e) {
        debugPrint("Error analyzing image: $e");
        _showError("Error analyzing image: $e");
      }
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> data) {
    final String appointmentId = data['appointmentId'] ?? "N/A";
    final bool alreadyPaid =
        (data['paymentStatus'] ?? '').toString().toLowerCase() == 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Track selected payment method inside the sheet
          String? selectedMethod;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Appointment Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow("Doctor", data['doctor'] ?? "N/A"),
                  _buildDetailRow("Date", data['date'] ?? "N/A"),
                  _buildDetailRow("Queue", "#${data['queue'] ?? 'N/A'}"),

                  // ── Payment section ──────────────────────────────
                  const Divider(height: 25),
                  if (alreadyPaid)
                    _buildPaymentRow(
                      method: data['paymentMethod'] ?? "N/A",
                      status: data['paymentStatus'] ?? "N/A",
                    )
                  else
                    StatefulBuilder(
                      builder: (context, setInner) {
                        selectedMethod ??= 'Cash';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Collect Payment",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: ['Cash', 'Card', 'Wallet'].map((method) {
                                final isSelected = selectedMethod == method;
                                return GestureDetector(
                                  onTap: () => setInner(() => selectedMethod = method),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor
                                          : context.filterChipBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : context.filterChipBorder,
                                      ),
                                    ),
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : context.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 25),

                  if (!alreadyPaid)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text(
                          "COLLECT PAYMENT & CONFIRM",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _collectPayment(
                            appointmentId: appointmentId,
                            paymentMethod: selectedMethod ?? 'Cash',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  if (alreadyPaid)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          "CONFIRM ATTENDANCE",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          _confirmAttendance(appointmentId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isScanning = true);
                      },
                      child: const Text("CANCEL",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      if (!_isScanning) setState(() => _isScanning = true);
    });
  }

  void _confirmAttendance(String appointmentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      bool success = await _apiService.completeAppointmentStatus(appointmentId);
      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        _showSuccess("Appointment confirmed successfully!");
      } else {
        _showError("Failed to confirm appointment");
      }
    } catch (e) {
      debugPrint("Attendance confirmation error for ID $appointmentId: $e");
      if (!mounted) return;
      Navigator.pop(context);
      _showError("Error confirming attendance");
    }
  }

  Future<void> _collectPayment({
    required String appointmentId,
    required String paymentMethod,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );

    try {
      // 1. Create payment  POST /api/Payment/{appointmentId}
      final paymentOk = await _apiService.createPaymentByAppointment(
        appointmentId: appointmentId,
        paymentMethod: paymentMethod,
      );

      // 2. Mark appointment as completed
      final attendanceOk =
          await _apiService.completeAppointmentStatus(appointmentId);

      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (paymentOk && attendanceOk) {
        _showSuccess(
            "Payment collected ($paymentMethod) & appointment confirmed!");
      } else if (paymentOk) {
        _showSuccess("Payment collected. Attendance confirmation failed.");
      } else {
        _showError("Payment failed. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError("Error: $e");
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({required String method, required String status}) {
    final isPaid = status.toLowerCase() == 'completed';
    final color = isPaid ? Colors.green.shade600 : Colors.orange.shade700;
    final icon = isPaid ? Icons.check_circle_rounded : Icons.pending_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Payment", style: TextStyle(color: Colors.grey, fontSize: 16)),
        Container(
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
                "$status · $method",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    debugPrint("Scanner Page Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isScanning = true);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
    Navigator.pop(context); // Go back to dashboard
  }

  @override
  void dispose() {
    controller.dispose();
    // إعادة تفعيل التدوير الطبيعي عند الخروج من صفحة الكاميرا
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan Appointment QR", 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 14,
          ),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search_rounded),
            onPressed: _pickImage,
            tooltip: "Pick from Gallery",
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
            tooltip: "Toggle Flash",
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover, // ملء الشاشة بنسب أبعاد صحيحة لمنع التمدد والانعكاس
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              "Align QR Code within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10)]),
            ),
          ),
        ],
      ),
    );
  }
}
