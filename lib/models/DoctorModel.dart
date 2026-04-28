class DoctorModel {
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final double experienceYears;
  final String specializationName;

  DoctorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.experienceYears,
    required this.specializationName,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      experienceYears: (json['experienceYears'] as num?)?.toDouble() ?? 0.0,
      specializationName: json['specializationName'] ?? 'General',
    );
  }
}
