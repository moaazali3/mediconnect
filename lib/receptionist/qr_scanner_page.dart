import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // ضفنا الباكيدج هنا

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // الكنترولر بتاع الكاميرا (بيتحكم في الفلاش وتشغيل الكاميرا)
  MobileScannerController cameraController = MobileScannerController();

  bool isFlashOn = false;
  bool isScanned = false; // عشان أول ما يلقط كود ميقعدش يكرره 100 مرة

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    cameraController.dispose(); // نقفل الكاميرا وإحنا طالعين
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. الكاميرا الحقيقية
          // ---------------------------------------------------------
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!isScanned) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    setState(() => isScanned = true); // نوقف الاسكان عشان ميقراش كتير

                    final String code = barcode.rawValue!;
                    print("✅ QR Code Scanned: $code");

                    // هنا الكاميرا لقطت الكود!
                    // هنعرضه في رسالة سريعة وبعدين نرجع للداشبورد بالنتيجة
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('QR Found: $code', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                    );

                    // نرجع للصفحة اللي فاتت ونبعتلها الكود اللي اتقرا
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) Navigator.pop(context, code);
                    });
                  }
                }
              }
            },
          ),

          // ---------------------------------------------------------
          // 2. تصميم مربع الاسكانر (Viewfinder)
          // ---------------------------------------------------------
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // 3. إطار المربع وخط الليزر
          // ---------------------------------------------------------
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              ),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned(
                    top: _animationController.value * (scanAreaSize - 5),
                    child: Container(
                      width: scanAreaSize,
                      height: 3,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(color: primaryColor.withOpacity(0.8), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 4. النصوص
          // ---------------------------------------------------------
          Positioned(
            bottom: size.height * 0.25,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text("Scan Appointment QR", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text("Align the QR code within the frame", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // 5. زرار الرجوع
          // ---------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 6. زراير التحكم
          // ---------------------------------------------------------
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  onTap: () {
                    // عشان تفتح صورة من الاستوديو وتعملها اسكان
                    // cameraController.analyzeImage(imagePath);
                  },
                ),
                const SizedBox(width: 40),
                _buildControlButton(
                  icon: isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  label: "Flash",
                  isActive: isFlashOn,
                  onTap: () {
                    // تشغيل وقفل فلاش الموبايل الحقيقي
                    cameraController.toggleTorch();
                    setState(() {
                      isFlashOn = !isFlashOn;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isActive ? primaryColor : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? primaryColor : Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}