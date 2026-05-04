import 'package:mediconnect/models/DoctorScheduleModel.dart';

class DoctorProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String dateOfBirth;
  final String gender;
  final String? address;
  final String phoneNumber;
  final String specializationName;
  final double experienceYears;
  final double consultationFee;
  final String biography;
  final String? profilePictureUrl;
  final List<DoctorScheduleModel> doctorSchedules;

  // Getter لضمان التوافق مع الأجزاء التي تستخدم imageUrl
  String? get imageUrl => profilePictureUrl;

  DoctorProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    this.address,
    required this.phoneNumber,
    required this.specializationName,
    required this.experienceYears,
    required this.consultationFee,
    required this.biography,
    this.profilePictureUrl,
    this.doctorSchedules = const [],
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    var schedulesJson = json['doctorSchedules'] ?? json['DoctorSchedules'];
    
    return DoctorProfileModel(
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? json['DateOfBirth'] ?? '',
      gender: json['gender'] ?? json['Gender'] ?? '',
      address: json['address'] ?? json['Address'],
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      specializationName: json['specializationName'] ?? json['SpecializationName'] ?? '',
      experienceYears: (json['experienceYears'] ?? json['ExperienceYears'] as num?)?.toDouble() ?? 0.0,
      consultationFee: (json['consultationFee'] ?? json['ConsultationFee'] as num?)?.toDouble() ?? 0.0,
      biography: json['biography'] ?? json['Biography'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? json['ProfilePictureUrl'] ?? json['imageUrl'] ?? json['ImageUrl'],
      doctorSchedules: (schedulesJson is List)
          ? schedulesJson.map((i) => DoctorScheduleModel.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
      "address": address,
      "phoneNumber": phoneNumber,
      "biography": biography,
      "profilePictureUrl": profilePictureUrl,
      "doctorSchedules": doctorSchedules.map((s) => s.toJson()).toList(),
    };
  }
}
