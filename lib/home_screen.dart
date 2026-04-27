import 'package:flutter/material.dart';
import 'patient/screens/home_content.dart';
import 'patient/screens/appointments_page.dart';
import 'patient/screens/profile.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? userRole;

  const HomeScreen({super.key, this.userId, this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const HomeContent(),
      const AppointmentsPage(),
      ProfileScreen(userId: widget.userId), // تمرير الـ userId لصفحة البروفايل
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
