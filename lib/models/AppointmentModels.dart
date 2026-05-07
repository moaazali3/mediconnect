class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String? specializationName;
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
    this.specializationName,
    required this.appointmentDate,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.queueNumber,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    String extractDoctorName(Map<String, dynamic> json) {
      final name = json['doctorName'] ?? json['DoctorName'] ?? json['doctor_name'] ?? json['Doctor_Name'] ?? json['doctorFullName'] ?? json['doctor_full_name'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
      
      if (json['doctor'] is Map) {
        final doc = json['doctor'];
        return (doc['name'] ?? doc['fullName'] ?? doc['fullNameEn'] ?? doc['firstName'] ?? doc['FirstName'] ?? '').toString();
      }
      return '';
    }

    String extractDoctorId(Map<String, dynamic> json) {
      final id = json['doctorId'] ?? json['DoctorId'] ?? json['doctor_id'] ?? json['Doctor_Id'] ?? json['doctorID'] ?? json['doctorid'] ?? json['idDoctor'] ?? json['id_doctor'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
      
      if (json['doctor'] is Map) {
        final doc = json['doctor'];
        return (doc['id'] ?? doc['doctorId'] ?? doc['Id'] ?? doc['DoctorId'] ?? doc['userId'] ?? doc['UserId'] ?? '').toString();
      }
      return '';
    }

    String extractPatientName(Map<String, dynamic> json) {
      final name = json['patientName'] ?? json['PatientName'] ?? json['patient_name'] ?? json['Patient_Name'] ?? json['patientFullName'] ?? json['patient_full_name'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
      
      if (json['patient'] is Map) {
        final p = json['patient'];
        return (p['name'] ?? p['fullName'] ?? p['fullNameEn'] ?? p['firstName'] ?? p['FirstName'] ?? '').toString();
      }
      return '';
    }

    return AppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['AppointmentId'] ?? json['id'] ?? json['Id'] ?? json['appointmentID'] ?? json['appointment_id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['PatientId'] ?? json['patientID'] ?? json['patient_id'] ?? json['patient_Id'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      patientName: extractPatientName(json),
      doctorId: extractDoctorId(json),
      doctorName: extractDoctorName(json),
      specializationName: (json['specializationName'] ?? json['SpecializationName'] ?? json['speciality'] ?? json['Speciality'])?.toString(),
      appointmentDate: (json['appointmentDate'] ?? json['AppointmentDate'] ?? json['date'] ?? json['appointment_date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'] ?? json['day_of_week'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['StartTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? json['end_time'] ?? '').toString(),
      queueNumber: json['queueNumber'] ?? json['QueueNumber'] ?? json['queue_number'] ?? 0,
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
    String extractName(Map<String, dynamic> json, List<String> keys, String nestedObj) {
      for (var key in keys) {
        if (json[key] != null && json[key].toString().isNotEmpty) return json[key].toString();
      }
      if (json[nestedObj] is Map) {
        final obj = json[nestedObj];
        final nestedKeys = ['name', 'fullName', 'fullNameEn', 'firstName', 'FirstName'];
        for (var k in nestedKeys) {
          if (obj[k] != null && obj[k].toString().isNotEmpty) return obj[k].toString();
        }
      }
      return '';
    }

    String extractId(Map<String, dynamic> json, List<String> keys, String nestedObj) {
      for (var key in keys) {
        if (json[key] != null && json[key].toString().isNotEmpty) return json[key].toString();
      }
      if (json[nestedObj] is Map) {
        final obj = json[nestedObj];
        final nestedKeys = ['id', 'doctorId', 'Id', 'DoctorId', 'userId', 'UserId', 'patientId', 'PatientId'];
        for (var k in nestedKeys) {
          if (obj[k] != null && obj[k].toString().isNotEmpty) return obj[k].toString();
        }
      }
      return '';
    }

    return DoctorAppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['AppointmentId'] ?? json['id'] ?? json['Id'] ?? json['appointmentID'] ?? '').toString(),
      patientId: extractId(json, ['patientId', 'PatientId', 'patientID', 'patient_id', 'userId', 'UserId'], 'patient'),
      doctorId: extractId(json, ['doctorId', 'DoctorId', 'doctorid', 'doctorID', 'idDoctor'], 'doctor'),
      patientName: extractName(json, ['patientName', 'PatientName', 'patient_name', 'patientFullName'], 'patient'),
      appointmentDate: (json['appointmentDate'] ?? json['AppointmentDate'] ?? json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'] ?? json['day_of_week'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['StartTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? json['end_time'] ?? '').toString(),
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
    String extractDoctorName(Map<String, dynamic> json) {
      final name = json['doctorName'] ?? json['DoctorName'] ?? json['doctor_name'] ?? json['doctorFullName'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
      if (json['doctor'] is Map) {
        final doc = json['doctor'];
        return (doc['name'] ?? doc['fullName'] ?? doc['firstName'] ?? '').toString();
      }
      return '';
    }

    String extractDoctorId(Map<String, dynamic> json) {
      final id = json['doctorId'] ?? json['DoctorId'] ?? json['doctorid'] ?? json['idDoctor'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
      if (json['doctor'] is Map) {
        final doc = json['doctor'];
        return (doc['id'] ?? doc['doctorId'] ?? doc['userId'] ?? '').toString();
      }
      return '';
    }

    return PatientAppointmentModel(
      appointmentId: (json['appointmentId'] ?? json['AppointmentId'] ?? json['id'] ?? json['Id'] ?? json['appointmentID'] ?? '').toString(),
      doctorId: extractDoctorId(json),
      doctorName: extractDoctorName(json),
      appointmentDate: (json['appointmentDate'] ?? json['AppointmentDate'] ?? json['date'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'] ?? '').toString(),
      startTime: (json['startTime'] ?? json['StartTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      queueNumber: json['queueNumber'] ?? json['QueueNumber'] ?? 0,
    );
  }
}
