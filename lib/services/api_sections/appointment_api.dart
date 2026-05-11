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
    } else {
      try {
        final body = jsonDecode(response.body);
        String errorMessage = body['errors']?.toString() ?? body['message']?.toString() ?? "Failed to create appointment";
        throw errorMessage;
      } catch (e) {
        if (e is String) rethrow;
        throw "Failed to create appointment";
      }
    }
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

  Future<List<AppointmentModel>> getReceptionistAppointments(String receptionistId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Appointment/receptionist/$receptionistId'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => AppointmentModel.fromJson(item)).toList();
    }
    throw "Error fetching receptionist appointments";
  }

  Future<Map<String, dynamic>> getExpectedNumber(String doctorId, String appointmentDate) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Appointment/expected-number?doctorId=$doctorId&appointmentDate=$appointmentDate'),
      headers: parent._headers,
    );

    debugPrint("EXPECTED NUMBER SERVER RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
    
    debugPrint("[completeAppointmentStatus] Server Response: ${response.body}");

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
    
    debugPrint("[cancelAppointmentStatus] Server Response: ${response.body}");

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
      // Fetch records and appointments in parallel; getAllDoctors is used for enrichment
      final recordResFuture = http.get(Uri.parse('${parent.baseUrl}/MedicalRecord/patient/$patientId'), headers: parent._headers);
      final apptResFuture = http.get(Uri.parse('${parent.baseUrl}/Appointment/patient/$patientId'), headers: parent._headers);
      final allDoctorsFuture = parent.getAllDoctors().catchError((_) => <DoctorModel>[]);

      final recordRes = await recordResFuture;

      // If medical records can't be fetched at all, throw
      if (recordRes.statusCode != 200) {
        throw "Error fetching medical records (${recordRes.statusCode})";
      }

      List<dynamic> recordBody = jsonDecode(recordRes.body);
      List<MedicalRecordModel> records = recordBody.map((item) => MedicalRecordModel.fromJson(item)).toList();

      if (records.isEmpty) return records;

      // Try to enrich with appointments
      try {
        final apptRes = await apptResFuture;
        final allDoctorsList = await allDoctorsFuture;

        if (apptRes.statusCode == 200) {
          List<dynamic> apptBody = jsonDecode(apptRes.body);
          List<PatientAppointmentModel> appointments = apptBody.map((item) => PatientAppointmentModel.fromJson(item)).toList();

          Map<String, PatientAppointmentModel> apptMap = {
            for (var a in appointments) a.appointmentId: a
          };

          // Name to ID lookup for fallback
          Map<String, String> nameToIdMap = {};
          for (var doc in allDoctorsList) {

            String cleanFirstName = doc.firstName.toLowerCase().trim();
            String cleanLastName = doc.lastName.toLowerCase().trim();
            String fullName = "$cleanFirstName $cleanLastName";
            if (doc.id.isNotEmpty) {
              nameToIdMap[fullName] = doc.id;
              // Also map individual names as fallback

              if (cleanFirstName.isNotEmpty) nameToIdMap[cleanFirstName] = doc.id;
              print(nameToIdMap);
            }
          }

          // 1. Resolve Doctor IDs for each record
          Set<String> resolvedDoctorIds = {};
          for (var record in records) {
            if (apptMap.containsKey(record.appointmentId)) {
              final appt = apptMap[record.appointmentId]!;
              String? docId;
              if (appt.doctorId.isNotEmpty && appt.doctorId.toLowerCase() != "null") {
                docId = appt.doctorId;
              } else {
                String cleanName = appt.doctorName.toLowerCase().replaceAll(RegExp(r'^dr\.?\s*', caseSensitive: false), '').trim();
                docId = nameToIdMap[cleanName];
              }
              if (docId != null && docId.isNotEmpty) {
                record.doctorId = docId;
                resolvedDoctorIds.add(docId);
              }
            }
          }

          // 2. Fetch detailed doctor profiles in parallel (ignore individual failures)
          Map<String, DoctorFullModel> doctorCache = {};
          await Future.wait(resolvedDoctorIds.map((id) async {
            try {
              final details = await parent.getDoctorDetails(id, null);

              doctorCache[id] = details;
            } catch (_) {}
          }));

          // 3. Map details back to records
          for (var record in records) {
            print(record.doctorName.toString());
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
        }
      } catch (enrichmentError) {
        debugPrint("[getPatientMedicalHistory] Enrichment failed: $enrichmentError");
      }

      return records;

    } catch (e) {
      debugPrint("[getPatientMedicalHistory] Error: $e");
      throw "Error fetching medical history";
    }
  }

  Future<MedicalRecordModel?> getMedicalRecordByAppointment(String appointmentId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/MedicalRecord/$appointmentId'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      return MedicalRecordModel.fromJson(jsonDecode(response.body));
    }
    
    try {
      final body = jsonDecode(response.body);
      if (body['errors'] == "Medical record not found") {
        return null; // نعيد null بدلاً من الخطأ لفتح واجهة الإضافة
      }
    } catch (_) {}
    
    throw "Error fetching medical record: ${response.body}";
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
