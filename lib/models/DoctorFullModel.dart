class DoctorFullModel {
  final String id;
  final String firstName;
  final String lastName;
  final String specializationName;
  final double experienceYears;
  final String biography;
  final double consultationFee;
  final String dateOfBirth; // بنستقبله كـ String ونحوله لو احتجنا
  final String gender;

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
  });

  factory DoctorFullModel.fromJson(Map<String, dynamic> json) {
    return DoctorFullModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      specializationName: json['specializationName'] ?? 'General',
      experienceYears: (json['experienceYears'] as num).toDouble(),
      biography: json['biography'] ?? '',
      consultationFee: (json['consultationFee'] as num).toDouble(),
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
    );
  }
}