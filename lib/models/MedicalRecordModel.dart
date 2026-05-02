class MedicalRecordModel {
  final String medicalRecordId;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String diagnosis;
  final String prescription;
  final String visitDate;

  MedicalRecordModel({
    required this.medicalRecordId,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.diagnosis,
    required this.prescription,
    required this.visitDate,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      medicalRecordId: json['medicalRecordId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? 'Dr. Unknown',
      doctorSpecialty: json['doctorSpecialty'] ?? 'General',
      diagnosis: json['diagnosis'] ?? '',
      prescription: json['prescription'] ?? '',
      visitDate: json['visitDate'] ?? '',
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
