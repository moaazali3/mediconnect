import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/patient/screens/home_content.dart';
import 'package:mediconnect/patient/screens/appointments_page.dart';
import 'package:mediconnect/patient/screens/profile.dart';
import 'package:mediconnect/widgets/common_app_bar.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? userRole;

  const HomeScreen({super.key, this.userId, this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final ApiService _apiService = ApiService();
  String? userName;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    pages = [
      HomeContent(userId: widget.userId),
      AppointmentsPage(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  Future<void> _loadUserName() async {
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      try {
        final profile = await _apiService.getPatientProfile(widget.userId!);
        if (mounted) {
          setState(() {
            userName = "${profile.firstName} ${profile.lastName}";
          });
        }
      } catch (e) {
        if (mounted) setState(() => userName = "User");
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: currentIndex == 2 ? null : CommonAppBar(
        title: currentIndex == 0 ? "Hello," : "My Appointments",
        subtitle: currentIndex == 0 ? (userName ?? "Loading...") : "MediConnect Patient",
        onRefresh: () => setState(() { _loadUserName(); }),
        onLogout: _signOut,
      ),
      body: pages[currentIndex],
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
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded, size: 30),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                activeIcon: Icon(Icons.calendar_month_rounded, size: 30),
                label: "Schedule",
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
