import 'package:flutter/material.dart';
import 'package:mediconnect/patient/widgets/search_bar.dart';
import 'package:mediconnect/patient/widgets/home_banner.dart';
import 'package:mediconnect/patient/widgets/specialization_item.dart';
import 'package:mediconnect/patient/widgets/doctor_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String selected = "All";

  final List<Map<String, String>> doctors = [
    {"name": "Dr. Ahmed", "spec": "Cardiology"},
    {"name": "Dr. Sara", "spec": "Dentist"},
    {"name": "Dr. Ali", "spec": "Dermatology"},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = selected == "All"
        ? doctors
        : doctors.where((d) => d["spec"] == selected).toList();

    return ListView(
      children: [
        const SizedBox(height: 20),
        const SearchBarWidget(),
        const SizedBox(height: 20),
        const HomeBanner(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Specializations",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SpecializationItem(
                title: "All",
                isSelected: selected == "All",
                onTap: () => setState(() => selected = "All"),
              ),
              const SizedBox(width: 10),
              SpecializationItem(
                title: "Dentist",
                isSelected: selected == "Dentist",
                onTap: () => setState(() => selected = "Dentist"),
              ),
              const SizedBox(width: 10),
              SpecializationItem(
                title: "Cardiology",
                isSelected: selected == "Cardiology",
                onTap: () => setState(() => selected = "Cardiology"),
              ),
              const SizedBox(width: 10),
              SpecializationItem(
                title: "Dermatology",
                isSelected: selected == "Dermatology",
                onTap: () => setState(() => selected = "Dermatology"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Top Doctors",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        ...filtered.map((d) => DoctorCard(d["name"]!, d["spec"]!)),
        const SizedBox(height: 20),
      ],
    );
  }
}
