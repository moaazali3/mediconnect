import 'package:mediconnect/models/DoctorScheduleModel.dart';

class DoctorFullModel {
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
  final String phoneNumber;

  DoctorFullModel({
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
    this.phoneNumber = '',
  });

  factory DoctorFullModel.fromJson(Map<String, dynamic> json) {
    String? imgUrl = json['profilePictureUrl'] ?? json['ProfilePictureUrl'];
    if (imgUrl != null && imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
      // Prepend host and fix slashes
      imgUrl = "https://wisdom-frisk-exciting.ngrok-free.dev${imgUrl.startsWith('/') ? '' : '/'}${imgUrl.replaceAll('\\', '/')}";
    }

    var schedulesJson = json['doctorSchedules'] ?? json['DoctorSchedules'];

    return DoctorFullModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      profilePictureUrl: imgUrl,
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString(),
      specializationName: (json['specializationName'] ?? json['SpecializationName'] ?? '').toString(),
      experienceYears: _toDouble(json['experienceYears'] ?? json['ExperienceYears']),
      biography: (json['biography'] ?? json['Biography'] ?? '').toString(),
      consultationFee: _toDouble(json['consultationFee'] ?? json['ConsultationFee']),
      dateOfBirth: (json['dateOfBirth'] ?? json['DateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? json['Gender'] ?? '').toString(),
      isAppleToAppointment: json['isAppleToAppointment'] ?? json['IsAppleToAppointment'] ?? false,
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'] ?? '').toString(),
      doctorSchedules: (schedulesJson is List)
          ? schedulesJson.map((i) => DoctorScheduleModel.fromJson(i)).toList()
          : [],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      'phoneNumber': phoneNumber,
      'doctorSchedules': doctorSchedules.map((s) => s.toJson()).toList(),
    };
  }
}
