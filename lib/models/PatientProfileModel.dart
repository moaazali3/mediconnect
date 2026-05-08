class PatientProfileModel {
  final String id;
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
    required this.id,
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
    String fName = (json['firstName'] ?? json['FirstName'] ?? '').toString().trim();
    String lName = (json['lastName'] ?? json['LastName'] ?? '').toString().trim();
    String pName = (json['patientName'] ?? json['PatientName'] ?? json['name'] ?? json['Name'] ?? '').toString().trim();

    if (fName.isEmpty && pName.isNotEmpty) {
      if (pName.contains(' ')) {
        int spaceIndex = pName.indexOf(' ');
        fName = pName.substring(0, spaceIndex);
        lName = pName.substring(spaceIndex + 1);
      } else {
        fName = pName;
      }
    }

    if (fName.isEmpty && lName.isEmpty) fName = "Patient";

    return PatientProfileModel(
      id: (json['id'] ?? json['_id'] ?? json['patientId'] ?? '').toString(),
      firstName: fName,
      lastName: lName,
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      dateOfBirth: (json['dateOfBirth'] ?? json['DateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? json['Gender'] ?? 'Male').toString(), 
      address: (json['address'] ?? json['Address'])?.toString(),
      bloodType: (json['bloodType'] ?? json['BloodType'] ?? 'N/A').toString(),
      height: _toDouble(json['height'] ?? json['Height']),
      weight: _toDouble(json['weight'] ?? json['Weight']),
      emergencyContact: (json['emergencyContact'] ?? json['EmergencyContact'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'] ?? json['phone'] ?? json['Phone'] ?? 'No Phone').toString(),
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
      "id": id,
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
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
