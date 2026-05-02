class MedicalRecordModel {
  final String medicalRecordId;
  final String appointmentId;
  final String diagnosis;
  final String prescription;
  final String createdDate;
  
  // حقول اختيارية سنملاها من بيانات الموعد
  String doctorName;
  String doctorSpecialty;

  MedicalRecordModel({
    required this.medicalRecordId,
    required this.appointmentId,
    required this.diagnosis,
    required this.prescription,
    required this.createdDate,
    this.doctorName = 'Dr. Unknown',
    this.doctorSpecialty = 'General',
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
