class PatientProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String dateOfBirth;
  final String gender;
  final String? address;
  final String bloodType;
  final double height;
  final double weight;
  final String emergencyContact;
  final String phoneNumber;

  PatientProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    this.address,
    required this.bloodType,
    required this.height,
    required this.weight,
    required this.emergencyContact,
    required this.phoneNumber,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'],
      bloodType: json['bloodType'] ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      emergencyContact: json['emergencyContact'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
      "address": address,
      "bloodType": bloodType,
      "height": height,
      "weight": weight,
      "emergencyContact": emergencyContact,
      "phoneNumber": phoneNumber,
    };
  }
}
