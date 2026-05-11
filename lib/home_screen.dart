import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/services/secure_storage.dart';
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
    await SecureStorage.deleteAllData();
    ApiService.setToken(null);
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
    String pageName = "Patient Portal";
    if (currentIndex == 1) pageName = "My Appointments";
    if (currentIndex == 2) pageName = "Profile";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: currentIndex == 2 ? null : CommonAppBar(
        pageName: pageName,
        userName: userName ?? "Loading...",
        isRoot: true,
        showDarkModeToggle: currentIndex == 0,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.1,
                  ),
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
                unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                showSelectedLabels: true,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).cardColor,
                elevation: 0,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                  if (index == 0 || index == 1) {
                    _loadUserName();
                  }
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
