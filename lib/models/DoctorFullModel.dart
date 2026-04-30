import 'package:mediconnect/models/DoctorScheduleModel.dart';

class DoctorFullModel {
  final String id;
  final String firstName;
  final String lastName;
  final String specializationName;
  final double experienceYears;
  final String biography;
  final double consultationFee;
  final String dateOfBirth;
  final String gender;
  final String? profilePictureUrl;
  final bool isAppleToAppointment;
  final List<DoctorScheduleModel> doctorSchedules;
  final String phoneNumber; // أضفنا رقم الهاتف هنا

  DoctorFullModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specializationName,
    required this.experienceYears,
    required this.biography,
    required this.consultationFee,
    required this.dateOfBirth,
    required this.gender,
    this.profilePictureUrl,
    required this.isAppleToAppointment,
    this.doctorSchedules = const [],
    this.phoneNumber = '', // قيمة افتراضية
  });

  factory DoctorFullModel.fromJson(Map<String, dynamic> json) {
    var scheduleList = json['doctorSchedules'] ?? json['DoctorSchedules'];
    
    return DoctorFullModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString(),
      specializationName: (json['specializationName'] ?? json['SpecializationName'] ?? 'General').toString(),
      experienceYears: _toDouble(json['experienceYears'] ?? json['ExperienceYears']),
      biography: (json['biography'] ?? json['Biography'] ?? '').toString(),
      consultationFee: _toDouble(json['consultationFee'] ?? json['ConsultationFee']),
      dateOfBirth: (json['dateOfBirth'] ?? json['DateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? json['Gender'] ?? '').toString(),
      profilePictureUrl: (json['profilePictureUrl'] ?? json['ProfilePictureUrl'])?.toString(),
      isAppleToAppointment: json['isAppleToAppointment'] ?? json['IsAppleToAppointment'] ?? false,
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'] ?? '').toString(),
      doctorSchedules: (scheduleList is List)
          ? scheduleList.map((i) => DoctorScheduleModel.fromJson(i)).toList()
          : [],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
