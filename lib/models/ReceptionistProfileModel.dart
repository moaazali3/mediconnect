class ReceptionistProfileModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? shift;
  final String? profilePictureUrl;
  final String? doctorId;
  final String? doctorName;

  ReceptionistProfileModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.shift,
    this.profilePictureUrl,
    this.doctorId,
    this.doctorName,
  });

  factory ReceptionistProfileModel.fromJson(Map<String, dynamic> json) {
    return ReceptionistProfileModel(
      id: json['id']?.toString(),
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      gender: json['gender'] ?? json['Gender'],
      dateOfBirth: json['dateOfBirth'] ?? json['DateOfBirth'],
      address: json['address'] ?? json['Address'],
      shift: json['shift'] ?? json['Shift'],
      profilePictureUrl: json['profilePictureUrl'] ?? json['ProfilePictureUrl'],
      doctorId: json['doctorId'] ?? json['DoctorId'],
      doctorName: json['doctorName'] ?? json['DoctorName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
      "gender": gender,
      "dateOfBirth": dateOfBirth,
      "address": address,
      "shift": shift,
      "profilePictureUrl": profilePictureUrl,
      "doctorId": doctorId,
      "doctorName": doctorName,
    };
  }
}
