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

  Future<DoctorFullModel> getDoctorDetails(String doctorId, String patientId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(Uri.parse('${parent.baseUrl}/Doctor/$doctorId/$patientId'), headers: parent._headers);
    if (response.statusCode == 200) {
      return DoctorFullModel.fromJson(jsonDecode(response.body));
    }
    throw "خطأ في تحميل بيانات الدكتور";
  }

  Future<bool> createDoctor(CreateDoctorModel doctor) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Doctor'),
        headers: parent._headers,
        body: jsonEncode(doctor.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ميثود جديدة لرفع صورة الطبيب
  Future<bool> uploadDoctorImage(String doctorId, String filePath) async {
    final ApiService parent = this as ApiService;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${parent.baseUrl}/Doctor/$doctorId/upload-image'),
      );

      // إضافة الـ Headers (نفس الهيدرز المستخدمة ولكن بدون Content-Type لأن MultipartRequest يضيفه تلقائياً)
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });

      // إضافة الملف (يجب أن يتطابق اسم الحقل 'File' مع المكتوب في الـ C# DTO)
      request.files.add(await http.MultipartFile.fromPath('File', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print("Upload failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error uploading image: $e");
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
}
