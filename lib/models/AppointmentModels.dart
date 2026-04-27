class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String appointmentDate;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int queueNumber;
  final String status;

  AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.queueNumber,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
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

  CreateAppointmentModel({
    required this.patientId,
    required this.doctorId,
    required this.dayOfWeek,
  });

  Map<String, dynamic> toJson() {
    return {
      "patientId": patientId,
      "doctorId": doctorId,
      "dayOfWeek": dayOfWeek,
    };
  }
}

class DoctorAppointmentModel {
  final String patientName;
  final String appointmentDate;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String status;
  final int queueNumber;

  DoctorAppointmentModel({
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
  final String doctorName;
  final String appointmentDate;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String status;
  final int queueNumber;

  PatientAppointmentModel({
    required this.doctorName,
    required this.appointmentDate,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.queueNumber,
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
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
