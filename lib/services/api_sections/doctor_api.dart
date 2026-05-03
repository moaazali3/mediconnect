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

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorModel.fromJson(item)).toList();
    } else {
      throw "Server error!";
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorNames() async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Doctor/names'),
      headers: parent._headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw "Error fetching doctor names: ${response.statusCode}";
    }
  }

  Future<DoctorFullModel> getDoctorDetails(String doctorId, String? patientId) async {
    final ApiService parent = this as ApiService;
    final String pId = (patientId == null || patientId.isEmpty) ? "00000000-0000-0000-0000-000000000000" : patientId;

    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Doctor/$doctorId/$pId'), 
      headers: parent._headers
    );
    
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      String? bodyStr = response.body.trim();
      
      if (bodyStr.isEmpty) {
        final location = response.headers['location'];
        if (location != null) {
          final id = location.split('/').last;
          if (id.length > 10) return id;
        }
        return "SUCCESS_NO_ID"; // Return a placeholder to indicate success
      }
      
      try {
        final data = jsonDecode(bodyStr);
        if (data is Map) {
          final id = data['id'] ?? data['Id'] ?? 
                     data['doctorId'] ?? data['DoctorId'] ?? 
                     data['userId'] ?? data['UserId'] ??
                     (data['data'] is Map ? (data['data']['id'] ?? data['data']['Id']) : data['data']);
          return id?.toString();
        } else if (data is String) {
          return data;
        }
        return "SUCCESS_NO_ID";
      } catch (e) {
        if (bodyStr.length > 10) return bodyStr; 
        return "SUCCESS_NO_ID";
      }
    } else {
      String errorMessage = "Failed to add doctor";
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map) {
          if (errorBody['errors'] != null) {
            final errors = errorBody['errors'];
            if (errors is Map) {
              errorMessage = errors.values
                  .expand((e) => e is List ? e : [e])
                  .map((e) => e.toString())
                  .join("\n");
            } else {
              errorMessage = errors.toString();
            }
          } else {
            errorMessage = errorBody['message'] ?? errorBody['title'] ?? errorMessage;
          }
        }
      } catch (e) {
        errorMessage = "Server error: ${response.statusCode}";
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
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
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
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadProfilePicture(String doctorId, String filePath) async {
    final ApiService parent = this as ApiService;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${parent.baseUrl}/Doctor/$doctorId/upload-profile-picture'),
      );
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });
      request.files.add(await http.MultipartFile.fromPath('File', filePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<SpecializationModel>> getAllSpecializations() async {
    final ApiService parent = this as ApiService;
    final response = await http.get(Uri.parse('${parent.baseUrl}/Specialization'), headers: parent._headers);
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
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDoctor(String id) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.delete(
        Uri.parse('${parent.baseUrl}/Doctor/$id'),
        headers: parent._headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
