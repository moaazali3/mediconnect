part of '../api_service.dart';

mixin DoctorApi {
  Future<List<DoctorModel>> getAllDoctors({String? specializationName, int pageNumber = 1}) async {
    final ApiService parent = this as ApiService;
    final Map<String, String> queryParameters = {
      'pageNumber': pageNumber.toString(),
    };

    if (specializationName != null && specializationName != "All") {
      queryParameters['specializationName'] = specializationName;
    }

    final uri = Uri.parse('${parent.baseUrl}/Doctor').replace(queryParameters: queryParameters);
    final response = await http.get(uri, headers: parent._headers);

    print("Get All Doctors Status Code: ${response.statusCode}");
    print("Get All Doctors Response Body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorModel.fromJson(item)).toList();
    } else {
      throw "Server error!";
    }
  }

  Future<DoctorFullModel> getDoctorDetails(String doctorId, String? patientId) async {
    final ApiService parent = this as ApiService;
    // التأكد من وجود قيمة للـ patientId لتجنب خطأ 404 في المسار
    final String pId = (patientId == null || patientId.isEmpty) ? "00000000-0000-0000-0000-000000000000" : patientId;

    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Doctor/$doctorId/$pId'), 
      headers: parent._headers
    );
    
    print("Get Doctor Details Status Code: ${response.statusCode}");
    print("Get Doctor Details Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return DoctorFullModel.fromJson(jsonDecode(response.body));
    }
    throw "خطأ في تحميل بيانات الدكتور: ${response.statusCode}";
  }

  Future<String?> createDoctor(CreateDoctorModel doctor) async {
    final ApiService parent = this as ApiService;
    final response = await http.post(
      Uri.parse('${parent.baseUrl}/Doctor'),
      headers: parent._headers,
      body: jsonEncode(doctor.toJson()),
    );

    print("Create Doctor Status Code: ${response.statusCode}");
    print("Create Doctor Response Body: ${response.body}");

    final bodyText = response.body.trim();

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 1. محاولة فك التشفير كـ JSON إذا كان يبدأ بـ { أو [
      if (bodyText.startsWith('{') || bodyText.startsWith('[')) {
        try {
          final data = jsonDecode(bodyText);
          if (data is Map) {
            return data['doctorId']?.toString() ?? 
                   data['DoctorId']?.toString() ?? 
                   data['id']?.toString() ?? 
                   data['Id']?.toString();
          }
        } catch (e) {
          print("Error parsing success JSON: $e");
        }
      }

      // 2. التحقق إذا كان النص عبارة عن GUID (معرف) مباشرة
      final guidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (guidRegex.hasMatch(bodyText)) {
        return bodyText;
      }

      // 3. إذا كان الرد رسالة نجاح نصية
      if (bodyText.toLowerCase().contains("successfully") || bodyText.toLowerCase().contains("created")) {
        return "SUCCESS_WITHOUT_ID";
      }

      return bodyText.isNotEmpty ? bodyText : "SUCCESS";
    } else {
      // استخراج رسالة الخطأ من السيرفر بشكل احترافي
      String errorMessage = "Failed to add doctor";
      try {
        if (bodyText.startsWith('{') || bodyText.startsWith('[')) {
          final data = jsonDecode(bodyText);
          if (data['errors'] != null) {
            if (data['errors'] is Map) {
              errorMessage = (data['errors'] as Map).values.first.toString();
            } else {
              errorMessage = data['errors'].toString();
            }
          } else if (data['message'] != null) {
            errorMessage = data['message'].toString();
          }
        } else if (response.statusCode == 409 || bodyText.contains("already exists")) {
          errorMessage = "هذا البريد الإلكتروني مسجل مسبقاً لمستخدم آخر";
        } else {
          errorMessage = bodyText;
        }
      } catch (_) {
        errorMessage = bodyText;
      }
      throw errorMessage;
    }
  }

  Future<bool> updateDoctor(String id, UpdateDoctorModel doctor) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Doctor/$id'),
        headers: parent._headers,
        body: jsonEncode(doctor.toJson()),
      );

      print("Update Doctor Status Code: ${response.statusCode}");
      print("Update Doctor Response Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error in updateDoctor: $e");
      return false;
    }
  }

  Future<bool> uploadDoctorImage(String doctorId, String filePath) async {
    final ApiService parent = this as ApiService;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${parent.baseUrl}/Doctor/$doctorId/upload-image'),
      );
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });
      request.files.add(await http.MultipartFile.fromPath('File', filePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Upload Doctor Image Status Code: ${response.statusCode}");
      print("Upload Doctor Image Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error in uploadDoctorImage: $e");
      return false;
    }
  }

  Future<List<SpecializationModel>> getAllSpecializations() async {
    final ApiService parent = this as ApiService;
    final response = await http.get(Uri.parse('${parent.baseUrl}/Specialization'), headers: parent._headers);

    print("Get All Specializations Status Code: ${response.statusCode}");
    print("Get All Specializations Response Body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => SpecializationModel.fromJson(item)).toList();
    } else {
      throw "Error fetching specializations";
    }
  }

  Future<bool> updateSpecialization(int id, CreateSpecializationModel specialization) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Specialization/$id'),
        headers: parent._headers,
        body: jsonEncode(specialization.toJson()),
      );

      print("Update Specialization Status Code: ${response.statusCode}");
      print("Update Specialization Response Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error in updateSpecialization: $e");
      return false;
    }
  }

  Future<bool> createSpecialization(CreateSpecializationModel specialization) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Specialization'),
        headers: parent._headers,
        body: jsonEncode(specialization.toJson()),
      );

      print("Create Specialization Status Code: ${response.statusCode}");
      print("Create Specialization Response Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error in createSpecialization: $e");
      return false;
    }
  }
}
