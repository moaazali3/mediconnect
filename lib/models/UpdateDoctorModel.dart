import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';

class UpdateDoctorModel {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String gender;
  final String dateOfBirth;
  final double experienceYears;
  final double consultationFee;
  final int specializationId;
  final String? biography; // أعدناه هنا كحقل اختياري

  UpdateDoctorModel({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.gender,
    required this.dateOfBirth,
    required this.experienceYears,
    required this.consultationFee,
    required this.specializationId,
    this.biography,
  });

  factory UpdateDoctorModel.fromProfile(DoctorProfileModel profile, int specId) {
    return UpdateDoctorModel(
      firstName: profile.firstName,
      lastName: profile.lastName,
      phoneNumber: profile.phoneNumber,
      gender: profile.gender,
      dateOfBirth: profile.dateOfBirth,
      experienceYears: profile.experienceYears,
      consultationFee: profile.consultationFee,
      specializationId: specId,
      biography: profile.biography,
    );
  }

  factory UpdateDoctorModel.fromFullModel(DoctorFullModel doctor, int specId) {
    return UpdateDoctorModel(
      firstName: doctor.firstName,
      lastName: doctor.lastName,
      phoneNumber: doctor.phoneNumber,
      gender: doctor.gender,
      dateOfBirth: doctor.dateOfBirth,
      experienceYears: doctor.experienceYears,
      consultationFee: doctor.consultationFee,
      specializationId: specId,
      biography: doctor.biography,
    );
  }

  UpdateDoctorModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? gender,
    String? dateOfBirth,
    double? experienceYears,
    double? consultationFee,
    int? specializationId,
    String? biography,
  }) {
    return UpdateDoctorModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      experienceYears: experienceYears ?? this.experienceYears,
      consultationFee: consultationFee ?? this.consultationFee,
      specializationId: specializationId ?? this.specializationId,
      biography: biography ?? this.biography,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "firstName": firstName,
      "lastName": lastName,
      "phoneNumber": phoneNumber,
      "gender": gender,
      "dateOfBirth": dateOfBirth,
      "experienceYears": experienceYears,
      "consultationFee": consultationFee,
      "specializationId": specializationId,
    };
    
    // إرسال الـ biography فقط إذا لم يكن null (سيستخدمه الدكتور ولا يستخدمه الأدمن)
    if (biography != null) {
      data["biography"] = biography;
    }
    
    return data;
  }
}
