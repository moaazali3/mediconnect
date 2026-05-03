class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String appointmentDate;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int queueNumber;
  final String status;

  AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDate,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.queueNumber,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['patientID'] ?? json['patient_id'] ?? json['patient_Id'] ?? json['userId'] ?? '').toString(),
      patientName: json['patientName'] ?? '',
      doctorId: (json['doctorId'] ?? json['doctorid'] ?? json['doctorID'] ?? '').toString(),
      doctorName: json['doctorName'] ?? '',
      appointmentDate: json['appointmentDate'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      queueNumber: json['queueNumber'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}

class CreateAppointmentModel {
  final String patientId;
  final String doctorId;
  final String dayOfWeek;
  final String appointmentDate;

  CreateAppointmentModel({
    required this.patientId,
    required this.doctorId,
    required this.dayOfWeek,
    required this.appointmentDate,
  });

  CreateAppointmentModel copyWith({
    String? patientId,
    String? doctorId,
    String? dayOfWeek,
    String? appointmentDate,
  }) {
    return CreateAppointmentModel(
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      appointmentDate: appointmentDate ?? this.appointmentDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "patientId": patientId,
      "doctorId": doctorId,
      "dayOfWeek": dayOfWeek,
      "appointmentDate": appointmentDate,
    };
  }
}

class DoctorAppointmentModel {
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String appointmentDate;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String status;
  final int queueNumber;

  DoctorAppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.appointmentDate,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.queueNumber,
  });

  factory DoctorAppointmentModel.fromJson(Map<String, dynamic> json) {
    return DoctorAppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['patientID'] ?? json['patient_id'] ?? json['patient_Id'] ?? json['userId'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['doctorid'] ?? json['doctorID'] ?? '').toString(),
      patientName: json['patientName'] ?? '',
      appointmentDate: json['appointmentDate'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? '',
      queueNumber: json['queueNumber'] ?? 0,
    );
  }
}

class PatientAppointmentModel {
  final String appointmentId;
  final String doctorId; 
  final String doctorName;
  final String appointmentDate;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String status;
  final int queueNumber;
  String? doctorImageUrl;

  PatientAppointmentModel({
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDate,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.queueNumber,
    this.doctorImageUrl,
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['id'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['doctorid'] ?? json['doctorID'] ?? '').toString(),
      doctorName: json['doctorName'] ?? '',
      appointmentDate: json['appointmentDate'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? '',
      queueNumber: json['queueNumber'] ?? 0,
    );
  }
}
