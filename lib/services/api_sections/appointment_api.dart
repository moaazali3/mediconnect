part of '../api_service.dart';

mixin AppointmentApi {
  Future<String?> createAppointment(CreateAppointmentModel appointment) async {
    final ApiService parent = this as ApiService;
    final response = await http.post(
      Uri.parse('${parent.baseUrl}/Appointment'),
      headers: parent._headers,
      body: jsonEncode(appointment.toJson()),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return "SUCCESS";
      try {
        final data = jsonDecode(response.body);
        return (data['id'] ?? data['appointmentId'] ?? data['Id'])?.toString();
      } catch (e) {
        return "SUCCESS";
      }
    }
    return null;
  }

  Future<List<DoctorAppointmentModel>> getDoctorAppointments(String doctorId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(Uri.parse('${parent.baseUrl}/Appointment/doctor/$doctorId'), headers: parent._headers);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorAppointmentModel.fromJson(item)).toList();
    }
    throw "خطأ في جلب مواعيد الطبيب";
  }

  Future<List<PatientAppointmentModel>> getPatientAppointments(String patientId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(Uri.parse('${parent.baseUrl}/Appointment/patient/$patientId'), headers: parent._headers);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<PatientAppointmentModel> appointments = body.map((item) => PatientAppointmentModel.fromJson(item)).toList();
      
      for (var appt in appointments) {
        appt.doctorImageUrl = parent.getCachedDoctorImage(appt.doctorId);
      }
      
      return appointments;
    }
    throw "خطأ في جلب مواعيد المريض";
  }

  Future<bool> completeAppointmentStatus(String appointmentId) async {
    final ApiService parent = this as ApiService;
    final response = await http.put(
      Uri.parse('${parent.baseUrl}/Appointment/complete?appointmentId=$appointmentId'),
      headers: parent._headers,
    );
    
    if (response.statusCode == 200) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      String errorMessage = body['errors']?.toString() ?? "Failed to complete appointment";
      throw "ID: $appointmentId - $errorMessage";
    }
  }

  Future<bool> cancelAppointmentStatus(String appointmentId) async {
    final ApiService parent = this as ApiService;
    final response = await http.put(
      Uri.parse('${parent.baseUrl}/Appointment/cancel?appointmentId=$appointmentId'),
      headers: parent._headers,
    );
    
    if (response.statusCode == 200) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      String errorMessage = body['errors']?.toString() ?? "Failed to cancel appointment";
      throw "ID: $appointmentId - $errorMessage";
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    final ApiService parent = this as ApiService;
    final response = await http.delete(
      Uri.parse('${parent.baseUrl}/Appointment/$appointmentId'),
      headers: parent._headers,
    );
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      String errorMessage = body['errors']?.toString() ?? "Failed to delete appointment";
      throw "ID: $appointmentId - $errorMessage";
    }
  }

  Future<List<MedicalRecordModel>> getPatientMedicalHistory(String patientId) async {
    final ApiService parent = this as ApiService;
    
    final results = await Future.wait([
      http.get(Uri.parse('${parent.baseUrl}/MedicalRecord/patient/$patientId'), headers: parent._headers),
      http.get(Uri.parse('${parent.baseUrl}/Appointment/patient/$patientId'), headers: parent._headers),
      http.get(Uri.parse('${parent.baseUrl}/Doctor'), headers: parent._headers),
    ]);

    final recordRes = results[0];
    final apptRes = results[1];
    final doctorRes = results[2];

    if (recordRes.statusCode == 200 && apptRes.statusCode == 200) {
      List<dynamic> recordBody = jsonDecode(recordRes.body);
      List<dynamic> apptBody = jsonDecode(apptRes.body);
      
      List<MedicalRecordModel> records = recordBody.map((item) => MedicalRecordModel.fromJson(item)).toList();
      List<PatientAppointmentModel> appointments = apptBody.map((item) => PatientAppointmentModel.fromJson(item)).toList();
      
      Map<String, String> doctorSpecialties = {};
      if (doctorRes.statusCode == 200) {
        List<dynamic> doctorBody = jsonDecode(doctorRes.body);
        for (var d in doctorBody) {
          doctorSpecialties[d['id'].toString()] = d['specializationName'] ?? 'General';
        }
      }

      Map<String, PatientAppointmentModel> apptMap = {
        for (var a in appointments) a.appointmentId: a
      };

      for (var record in records) {
        if (apptMap.containsKey(record.appointmentId)) {
          final appt = apptMap[record.appointmentId]!;
          record.doctorName = appt.doctorName;
          record.doctorSpecialty = doctorSpecialties[appt.doctorId] ?? 'General';
        }
      }
      return records;
    }
    throw "Error fetching medical history";
  }

  Future<MedicalRecordModel> getMedicalRecordByAppointment(String appointmentId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/MedicalRecord/$appointmentId'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      return MedicalRecordModel.fromJson(jsonDecode(response.body));
    }
    throw "Error fetching medical record for appointment $appointmentId";
  }

  Future<bool> createMedicalRecord(CreateMedicalRecordModel record) async {
    final ApiService parent = this as ApiService;
    final response = await http.post(
      Uri.parse('${parent.baseUrl}/MedicalRecord'),
      headers: parent._headers,
      body: jsonEncode(record.toJson()),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      String errorMessage = body['errors']?.toString() ?? "Failed to create medical record";
      throw errorMessage;
    }
  }

  Future<bool> updateMedicalRecord(String medicalRecordId, String diagnosis, String prescription) async {
    final ApiService parent = this as ApiService;
    final response = await http.put(
      Uri.parse('${parent.baseUrl}/MedicalRecord/$medicalRecordId'),
      headers: parent._headers,
      body: jsonEncode({
        "diagnosis": diagnosis,
        "prescription": prescription,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      final body = jsonDecode(response.body);
      String errorMessage = body['errors']?.toString() ?? "Failed to update medical record";
      throw errorMessage;
    }
  }
}
