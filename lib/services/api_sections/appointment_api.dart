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
      String bodyStr = response.body.trim();
      
      if (bodyStr.isEmpty) {
        // Try to get ID from Location header if body is empty
        final location = response.headers['location'];
        if (location != null) {
          final id = location.split('/').last;
          if (id.length > 20) return id;
        }
        return null;
      }

      try {
        final data = jsonDecode(bodyStr);
        if (data is Map) {
          final id = data['id'] ?? data['appointmentId'] ?? data['Id'] ?? 
                     (data['data'] is Map ? (data['data']['id'] ?? data['data']['appointmentId']) : null);
          if (id != null) return id.toString();
        } else if (data is String && data.length > 20) {
          return data;
        }
      } catch (e) {
        // If not JSON, but looks like a GUID, return it
        if (bodyStr.length > 20) return bodyStr;
      }
      
      // If we got here, we couldn't find a valid GUID/ID
      return null;
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

  Future<int> getExpectedNumber(String doctorId, String day) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Appointment/expected-number?doctorId=$doctorId&day=$day'),
      headers: parent._headers,
    );

    if (response.statusCode == 200) {
      return int.tryParse(response.body) ?? 0;
    } else {
      final body = jsonDecode(response.body);
      String errorMessage = body['errors']?.toString() ?? "Failed to fetch expected number";
      throw errorMessage;
    }
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
      throw errorMessage;
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
      throw errorMessage;
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
      throw errorMessage;
    }
  }

  Future<List<MedicalRecordModel>> getPatientMedicalHistory(String patientId) async {
    final ApiService parent = this as ApiService;
    
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${parent.baseUrl}/MedicalRecord/patient/$patientId'), headers: parent._headers),
        http.get(Uri.parse('${parent.baseUrl}/Appointment/patient/$patientId'), headers: parent._headers),
        parent.getDoctorNames(),
      ]);

      final recordRes = results[0] as http.Response;
      final apptRes = results[1] as http.Response;
      final doctorNamesList = results[2] as List<Map<String, dynamic>>;

      if (recordRes.statusCode == 200 && apptRes.statusCode == 200) {
        List<dynamic> recordBody = jsonDecode(recordRes.body);
        List<dynamic> apptBody = jsonDecode(apptRes.body);
        
        List<MedicalRecordModel> records = recordBody.map((item) => MedicalRecordModel.fromJson(item)).toList();
        List<PatientAppointmentModel> appointments = apptBody.map((item) => PatientAppointmentModel.fromJson(item)).toList();
        
        Map<String, PatientAppointmentModel> apptMap = {
          for (var a in appointments) a.appointmentId: a
        };

        // Name to ID lookup for fallback
        Map<String, String> nameToIdMap = {};
        for (var doc in doctorNamesList) {
          String rawName = (doc['name'] ?? doc['fullName'] ?? doc['firstName'] ?? '').toString().toLowerCase();
          String cleanName = rawName.replaceAll(RegExp(r'^dr\.?\s*', caseSensitive: false), '').trim();
          String id = (doc['id'] ?? doc['doctorId'] ?? '').toString();
          if (cleanName.isNotEmpty && id.isNotEmpty) {
            nameToIdMap[cleanName] = id;
          }
        }

        // 1. Resolve Doctor IDs for each record
        Set<String> resolvedDoctorIds = {};
        for (var record in records) {
          if (apptMap.containsKey(record.appointmentId)) {
            final appt = apptMap[record.appointmentId]!;
            
            String? docId;
            // Prefer doctorId from appointment if it exists and is not 'null'
            if (appt.doctorId.isNotEmpty && appt.doctorId.toLowerCase() != "null") {
              docId = appt.doctorId;
            } else {
              // Fallback to name lookup
              String cleanName = appt.doctorName.toLowerCase().replaceAll(RegExp(r'^dr\.?\s*', caseSensitive: false), '').trim();
              docId = nameToIdMap[cleanName];
            }

            if (docId != null && docId.isNotEmpty) {
              record.doctorId = docId;
              resolvedDoctorIds.add(docId);
            }
          }
        }

        // 2. Fetch detailed doctor profiles in parallel
        Map<String, DoctorFullModel> doctorCache = {};
        await Future.wait(resolvedDoctorIds.map((id) async {
          try {
            final details = await parent.getDoctorDetails(id, patientId);
            doctorCache[id] = details;
          } catch (_) {}
        }));

        // 3. Map details back to records
        for (var record in records) {
          if (record.doctorId.isNotEmpty && doctorCache.containsKey(record.doctorId)) {
            final doc = doctorCache[record.doctorId]!;
            record.doctorName = "Dr. ${doc.firstName} ${doc.lastName}";
            record.doctorSpecialty = doc.specializationName;
            record.doctorImageUrl = doc.profilePictureUrl;
          } else if (apptMap.containsKey(record.appointmentId)) {
            final appt = apptMap[record.appointmentId]!;
            record.doctorName = appt.doctorName;
            record.doctorSpecialty = 'Medical Specialist';
          }
        }
        return records;
      }
    } catch (e) {
      // Error handling
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
