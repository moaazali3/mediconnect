class MedicalRecordModel {
  final String medicalRecordId;
  final String appointmentId;
  final String diagnosis;
  final String prescription;
  final String createdDate;
  
  // Optional fields filled from appointment data
  String doctorId;
  String doctorName;
  String doctorSpecialty;
  String? doctorImageUrl;

  MedicalRecordModel({
    required this.medicalRecordId,
    required this.appointmentId,
    required this.diagnosis,
    required this.prescription,
    required this.createdDate,
    this.doctorId = '',
    this.doctorName = 'Dr. Unknown',
    this.doctorSpecialty = 'General',
    this.doctorImageUrl,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      medicalRecordId: json['medicalRecordId'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      prescription: json['prescription'] ?? '',
      createdDate: json['createdDate'] ?? json['visitDate'] ?? '',
    );
  }
}

class CreateMedicalRecordModel {
  final String appointmentId;
  final String diagnosis;
  final String prescription;

  CreateMedicalRecordModel({
    required this.appointmentId,
    required this.diagnosis,
    required this.prescription,
  });

  Map<String, dynamic> toJson() {
    return {
      "appointmentId": appointmentId,
      "diagnosis": diagnosis,
      "prescription": prescription,
    };
  }
}
