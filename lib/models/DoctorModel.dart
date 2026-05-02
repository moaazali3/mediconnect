import 'package:mediconnect/models/DoctorScheduleModel.dart';

class DoctorModel {
  final String id;
  final String? profilePictureUrl;
  final String firstName;
  final String lastName;
  final String specializationName;
  final double experienceYears;
  final String biography;
  final double consultationFee;
  final String dateOfBirth;
  final String gender;
  final bool isAppleToAppointment;
  final List<DoctorScheduleModel> doctorSchedules;

  DoctorModel({
    required this.id,
    this.profilePictureUrl,
    required this.firstName,
    required this.lastName,
    required this.specializationName,
    required this.experienceYears,
    required this.biography,
    required this.consultationFee,
    required this.dateOfBirth,
    required this.gender,
    required this.isAppleToAppointment,
    this.doctorSchedules = const [],
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    // التحقق من قائمة الجداول سواء كانت تبدأ بحرف كبير أو صغير
    var scheduleList = json['doctorSchedules'] ?? json['DoctorSchedules'];
    
    return DoctorModel(
      id: json['id'] ?? json['Id'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? json['ProfilePictureUrl'],
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      specializationName: json['specializationName'] ?? json['SpecializationName'] ?? '',
      experienceYears: (json['experienceYears'] ?? json['ExperienceYears'] as num?)?.toDouble() ?? 0.0,
      biography: json['biography'] ?? json['Biography'] ?? '',
      consultationFee: (json['consultationFee'] ?? json['ConsultationFee'] as num?)?.toDouble() ?? 0.0,
      dateOfBirth: json['dateOfBirth'] ?? json['DateOfBirth'] ?? '',
      gender: json['gender'] ?? json['Gender'] ?? '',
      isAppleToAppointment: json['isAppleToAppointment'] ?? json['IsAppleToAppointment'] ?? false,
      doctorSchedules: scheduleList != null
          ? (scheduleList as List)
              .map((i) => DoctorScheduleModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profilePictureUrl': profilePictureUrl,
      'firstName': firstName,
      'lastName': lastName,
      'specializationName': specializationName,
      'experienceYears': experienceYears,
      'biography': biography,
      'consultationFee': consultationFee,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'isAppleToAppointment': isAppleToAppointment,
      'doctorSchedules': doctorSchedules.map((s) => s.toJson()).toList(),
    };
  }
}
