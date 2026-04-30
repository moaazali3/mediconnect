part of '../api_service.dart';

mixin DoctorScheduleApi {
  // جلب جدول مواعيد الطبيب
  Future<List<DoctorScheduleModel>> getDoctorSchedule(String doctorId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorScheduleModel.fromJson(item)).toList();
    }
    throw "Error fetching doctor schedule";
  }

  // إنشاء جدول مواعيد جديد للطبيب
  Future<ApiResponse> createDoctorSchedule(String doctorId, Map<String, dynamic> scheduleData) async {
    final ApiService parent = this as ApiService;
    try {
      // بناء البيانات لتطابق Swagger تماماً
      // تحويل رقم اليوم إلى اسم اليوم إذا كان السيرفر يتوقعه كـ string
      final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      String dayName = scheduleData['dayOfWeek'] is int 
          ? days[scheduleData['dayOfWeek']] 
          : scheduleData['dayOfWeek'].toString();

      final wrappedData = {
        "doctorSchedules": [
          {
            "dayOfWeek": dayName,
            "startTime": scheduleData['startTime'],
            "isAvailable": scheduleData['isAvailable'] ?? true,
            // إذا كان الـ API يتوقع endTime أيضاً رغم عدم ظهوره في الصورة، يمكنك تفعيله هنا:
            "endTime": scheduleData['endTime'], 
          }
        ]
      };

      final response = await http.post(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
        body: jsonEncode(wrappedData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, message: "Doctor schedule created successfully.");
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['errors']?.toString() ?? "Failed to create schedule.");
      }
    } catch (e) {
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }

  // تحديث جدول مواعيد الطبيب
  Future<ApiResponse> updateDoctorSchedule(String doctorId, Map<String, dynamic> scheduleData) async {
    final ApiService parent = this as ApiService;
    try {
      final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      String dayName = scheduleData['dayOfWeek'] is int 
          ? days[scheduleData['dayOfWeek']] 
          : scheduleData['dayOfWeek'].toString();

      final wrappedData = {
        "doctorSchedules": [
          {
            "dayOfWeek": dayName,
            "startTime": scheduleData['startTime'],
            "isAvailable": scheduleData['isAvailable'] ?? true,
            "endTime": scheduleData['endTime'],
          }
        ]
      };

      final response = await http.put(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
        body: jsonEncode(wrappedData),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: "Doctor schedule updated successfully.");
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['errors']?.toString() ?? "Failed to update schedule.");
      }
    } catch (e) {
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }

  // حذف جدول مواعيد الطبيب
  Future<ApiResponse> deleteDoctorSchedule(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.delete(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: "Doctor schedule deleted successfully.");
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['errors']?.toString() ?? "Failed to delete schedule.");
      }
    } catch (e) {
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }
}
