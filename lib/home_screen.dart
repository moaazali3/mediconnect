import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/patient/screens/home_content.dart';
import 'package:mediconnect/patient/screens/appointments_page.dart';
import 'package:mediconnect/patient/screens/profile.dart';

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
    if (widget.userId != null) {
      try {
        final profile = await _apiService.getPatientProfile(widget.userId!);
        setState(() {
          userName = "${profile.firstName} ${profile.lastName}";
        });
      } catch (e) {
        debugPrint("Error loading user name: $e");
        setState(() {
          userName = "User";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: currentIndex == 2 ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello,",
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w400),
              ),
              Text(
                userName ?? "Loading...",
                style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image.asset(
                "assets/images/img.png",
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.medical_services_rounded, color: primaryColor, size: 35),
              ),
            ),
          )
        ],
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
