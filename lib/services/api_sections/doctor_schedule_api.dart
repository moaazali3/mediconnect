part of '../api_service.dart';

mixin DoctorScheduleApi {
  // جلب جدول مواعيد الطبيب
  Future<List<DoctorScheduleModel>> getDoctorSchedule(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => DoctorScheduleModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        // إذا كان الطبيب لا يملك جدولاً بعد، نرجع قائمة فارغة بدلاً من خطأ
        return [];
      } else {
        throw "Server returned ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      print("Error in getDoctorSchedule: $e");
      // في حالة وجود خطأ، نفضل إرجاع قائمة فارغة لضمان استمرار عمل الواجهة
      return [];
    }
  }

  // إنشاء جدول مواعيد جديد للطبيب
  Future<ApiResponse> createDoctorSchedule(String doctorId, Map<String, dynamic> scheduleData) async {
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
