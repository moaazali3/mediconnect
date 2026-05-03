class CreateReceptionistModel {
  final String doctorId;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String gender;
  final String dateOfBirth;
  final String address;

  CreateReceptionistModel({
    required this.doctorId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      "doctorId": doctorId,
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "password": password,
      "phoneNumber": phoneNumber,
      "gender": gender,
      "dateOfBirth": dateOfBirth,
      "address": address,
    };
  }
}
