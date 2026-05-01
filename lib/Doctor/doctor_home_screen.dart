import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/services/api_service.dart';
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

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    pages = [
      DoctorAppointmentsPage(doctorId: widget.userId),
      DoctorProfileScreen(doctorId: widget.userId ?? ""),
    ];
  }

  Future<void> _loadDoctorName() async {
    if (widget.userId != null) {
      try {
        final profile = await _apiService.getDoctorProfile(widget.userId!);
        setState(() {
          doctorName = "Dr. ${profile.firstName} ${profile.lastName}";
        });
      } catch (e) {
        debugPrint("Error loading doctor name: $e");
        setState(() {
          doctorName = "Doctor";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: currentIndex == 1 ? null : AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, // يمنع تغيير اللون في Material 3
        scrolledUnderElevation: 0, // يمنع الظل واللون المتغير عند السكرول
        elevation: 0,
        toolbarHeight: 70,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // تثبيت لون منطقة الـ Safe Area (Status Bar)
          statusBarIconBrightness: Brightness.dark, // جعل الأيقونات (الساعة والبطارية) سوداء
        ),
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
                doctorName ?? "Loading...",
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
