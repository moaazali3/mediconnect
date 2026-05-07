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
    // Helper to extract nested doctor info
    String extractDoctorName(Map<String, dynamic> json) {
      if (json['doctorName'] != null) return json['doctorName'].toString();
      if (json['DoctorName'] != null) return json['DoctorName'].toString();
      if (json['doctor'] is Map) {
        final doc = json['doctor'];
        return (doc['name'] ?? doc['fullName'] ?? doc['firstName'] ?? '').toString();
      }
      return '';
    }

    String extractDoctorId(Map<String, dynamic> json) {
      if (json['doctorId'] != null) return json['doctorId'].toString();
      if (json['DoctorId'] != null) return json['DoctorId'].toString();
      if (json['doctor'] is Map) {
        final doc = json['doctor'];
        return (doc['id'] ?? doc['doctorId'] ?? doc['Id'] ?? '').toString();
      }
      return '';
    }

    return AppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['AppointmentId'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['PatientId'] ?? json['patientID'] ?? json['patient_id'] ?? json['patient_Id'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      patientName: (json['patientName'] ?? json['PatientName'] ?? json['patient']?['name'] ?? json['patient']?['fullName'] ?? '').toString(),
      doctorId: extractDoctorId(json),
      doctorName: extractDoctorName(json),
      appointmentDate: (json['appointmentDate'] ?? json['AppointmentDate'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['StartTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? '').toString(),
      queueNumber: json['queueNumber'] ?? json['QueueNumber'] ?? 0,
      status: (json['status'] ?? json['Status'] ?? '').toString(),
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
      appointmentId: (json['appointmentId'] ?? json['AppointmentId'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['PatientId'] ?? json['patientID'] ?? json['patient_id'] ?? json['patient_Id'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['DoctorId'] ?? json['doctorid'] ?? json['doctorID'] ?? '').toString(),
      patientName: (json['patientName'] ?? json['PatientName'] ?? '').toString(),
      appointmentDate: (json['appointmentDate'] ?? json['AppointmentDate'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['StartTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      queueNumber: json['queueNumber'] ?? json['QueueNumber'] ?? 0,
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
      appointmentId: (json['appointmentId'] ?? json['AppointmentId'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['DoctorId'] ?? json['doctorid'] ?? json['doctorID'] ?? '').toString(),
      doctorName: (json['doctorName'] ?? json['DoctorName'] ?? '').toString(),
      appointmentDate: (json['appointmentDate'] ?? json['AppointmentDate'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['StartTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      queueNumber: json['queueNumber'] ?? json['QueueNumber'] ?? 0,
    );
  }
}
