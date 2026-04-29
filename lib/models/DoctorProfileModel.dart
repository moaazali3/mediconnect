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
  final String? imageUrl;

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
    this.imageUrl,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'],
      phoneNumber: json['phoneNumber'] ?? '',
      specializationName: json['specializationName'] ?? '',
      experienceYears: (json['experienceYears'] as num?)?.toDouble() ?? 0.0,
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0.0,
      biography: json['biography'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
      "address": address,
      "phoneNumber": phoneNumber,
      "biography": biography,
      "imageUrl": imageUrl,
    };
  }
}
