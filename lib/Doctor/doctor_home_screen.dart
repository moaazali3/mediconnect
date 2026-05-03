import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_appointments_page.dart';
import 'doctor_profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final String? userId;

  const DoctorHomeScreen({super.key, this.userId});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int currentIndex = 0;
  final ApiService _apiService = ApiService();
  String? doctorName;

  // مفاتيح للتحكم في تحديث الصفحات الداخلية
  final GlobalKey<DoctorAppointmentsPageState> _appointmentsKey = GlobalKey();

  Future<void> _loadDoctorName() async {
    if (widget.userId != null) {
      try {
        final profile = await _apiService.getDoctorProfile(widget.userId!);
        if (mounted) {
          setState(() {
            doctorName = "Dr. ${profile.firstName} ${profile.lastName}";
          });
        }
      } catch (e) {
        debugPrint("Error loading doctor name: $e");
        if (mounted) {
          setState(() {
            doctorName = "Doctor";
          });
        }
      }
    }
  }

  void _handleRefresh() {
    _loadDoctorName(); // تحديث الاسم في الـ AppBar
    
    // إذا كنا في صفحة المواعيد، نطلب منها التحديث
    if (currentIndex == 0 && _appointmentsKey.currentState != null) {
      _appointmentsKey.currentState!.refreshAppointments();
    } else {
      // إعادة بناء الواجهة للصفحات الأخرى
      setState(() {});
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
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: currentIndex == 1 ? null : CommonAppBar(
        title: "Hello,",
        subtitle: doctorName ?? "Loading...",
        onRefresh: _handleRefresh,
        onLogout: _signOut,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          DoctorAppointmentsPage(key: _appointmentsKey, doctorId: widget.userId),
          DoctorProfileScreen(doctorId: widget.userId ?? ""),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
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
            currentIndex: currentIndex,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                activeIcon: Icon(Icons.list_alt_rounded, size: 30),
                label: "Appointments",
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
