import 'package:flutter/material.dart';
import 'package:mediconnect/admin/qr_scanner_page.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconnect/receptionist/receptionist_pending_appointments_page.dart';
import 'package:mediconnect/receptionist/receptionist_profile_page.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  int _currentIndex = 0;
  String _receptionistName = "Receptionist"; // القيمة الافتراضية

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ReceptionistPendingAppointmentsPage(),
      const SizedBox.shrink(), // مكان فاضي للاسكان عشان هنفتحه في شاشة منفصلة
      const ReceptionistProfilePage(),
    ];
    // استدعاء دالة جلب الاسم أول ما الصفحة تفتح
    _fetchAndSetUserName();
  }

  // الدالة دي بتجيب الاسم سواء من الكاش أو من السيرفر
  Future<void> _fetchAndSetUserName() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. نجرب نجيب الاسم من الكاش الأول
    String? cachedName = prefs.getString('user_name');
    String? userId = prefs.getString('user_id');

    if (cachedName != null && cachedName.isNotEmpty && cachedName != "null") {
      if (mounted) {
        setState(() {
          _receptionistName = cachedName;
        });
      }
    } else if (userId != null) {
      // 2. لو مفيش اسم في الكاش بس فيه ID، نجيبه من السيرفر
      try {
        final profile = await ApiService().getReceptionistProfile(userId);
        final fullName = "${profile.firstName} ${profile.lastName}";

        if (mounted) {
          setState(() {
            _receptionistName = fullName;
          });
        }
        // نحفظه في الكاش عشان منجبوش من السيرفر تاني
        await prefs.setString('user_name', fullName);
      } catch (e) {
        // لو حصل مشكلة، نسيب القيمة الافتراضية
        print("Error fetching user name: $e");
      }
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = "Pending Appointments";
    if (_currentIndex == 2) pageTitle = "My Profile";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      // الـ AppBar الأساسي بتاع الشاشة كلها
      appBar: _currentIndex == 2
          ? null // بنخفيه في صفحة البروفايل بس
          : CommonAppBar(
        pageName: pageTitle,
        userName: _receptionistName,
        onRefresh: _fetchAndSetUserName, // بنعمل ريفريش للاسم لو داس على السهم المدور
        onLogout: _signOut,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            onTap: (index) {
              if (index == 1) {
                // لما يدوس على الاسكان، نفتحله الصفحة الكبيرة اللي عملناها
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScannerPage()),
                );
              } else {
                // لما يدوس على المواعيد أو البروفايل يقلب عادي
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                activeIcon: Icon(Icons.calendar_month_rounded, size: 30),
                label: "Appointments",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_rounded),
                activeIcon: Icon(Icons.qr_code_scanner_rounded, size: 30),
                label: "Scan QR",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                activeIcon: Icon(Icons.person_rounded, size: 30),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}