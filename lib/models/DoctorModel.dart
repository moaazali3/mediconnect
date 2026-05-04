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
    String? imgUrl = json['profilePictureUrl'] ?? json['ProfilePictureUrl'];
    if (imgUrl != null && imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
      imgUrl = "https://wisdom-frisk-exciting.ngrok-free.dev${imgUrl.startsWith('/') ? '' : '/'}${imgUrl.replaceAll('\\', '/')}";
    }

    // دالة آمنة لتحويل القيم المنطقية (Booleans)
    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return defaultValue;
    }

    // البحث عن قائمة الجداول في عدة مفاتيح محتملة
    var schedulesJson = json['doctorSchedules'] ?? 
                        json['DoctorSchedules'] ?? 
                        json['schedules'] ?? 
                        json['Schedules'];

    return DoctorModel(
      // قراءة المعرف بكافة أشكاله المحتملة لضمان نجاح جلب المواعيد وحساب الإحصائيات
      id: (json['id'] ?? json['Id'] ?? json['doctorId'] ?? json['DoctorId'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      profilePictureUrl: imgUrl,
      firstName: (json['firstName'] ?? json['FirstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? json['LastName'] ?? '').toString(),
      specializationName: (json['specializationName'] ?? json['SpecializationName'] ?? '').toString(),
      experienceYears: _toDouble(json['experienceYears'] ?? json['ExperienceYears']),
      biography: (json['biography'] ?? json['Biography'] ?? '').toString(),
      consultationFee: _toDouble(json['consultationFee'] ?? json['ConsultationFee']),
      dateOfBirth: (json['dateOfBirth'] ?? json['DateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? json['Gender'] ?? '').toString(),
      isAppleToAppointment: parseBool(json['isAppleToAppointment'] ?? json['IsAppleToAppointment']),
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
      'doctorSchedules': doctorSchedules.map((s) => s.toJson()).toList(),
    };
  }
}
