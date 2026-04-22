class CreateDoctorModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String gender;
  final DateTime dateOfBirth;
  final String address;
  final double experienceYears;
  final double consultationFee;
  final int specializationId;

  CreateDoctorModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.experienceYears,
    required this.consultationFee,
    required this.specializationId,
  });

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "password": password,
      "phoneNumber": phoneNumber,
      "gender": gender,
      "dateOfBirth": dateOfBirth.toIso8601String().split('T')[0], // Format: YYYY-MM-DD for DateOnly
      "address": address,
      "experienceYears": experienceYears,
      "consultationFee": consultationFee,
      "specializationId": specializationId,
    };
  }
}
