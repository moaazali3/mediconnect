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

      print("GET DoctorSchedule Status: ${response.statusCode}");
      print("GET DoctorSchedule Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => DoctorScheduleModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw "Server returned ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      print("Error in getDoctorSchedule: $e");
      return [];
    }
  }

  // إنشاء جدول مواعيد جديد للطبيب
  Future<ApiResponse> createDoctorSchedule(String doctorId, Map<String, dynamic> scheduleData) async {
    final ApiService parent = this as ApiService;
    try {
      // إرسال كائن واحد وليس قائمة، وبمسميات الحقول المتوقعة للسيرفر
      final body = {
        "doctorId": doctorId,
        "dayOfWeek": scheduleData['dayOfWeek'],
        "startTime": scheduleData['startTime'],
        "endTime": scheduleData['endTime'],
        "isAvailable": scheduleData['isAvailable'] ?? true,
      };

      print("POST DoctorSchedule URL: ${parent.baseUrl}/DoctorSchedule/$doctorId");
      print("POST DoctorSchedule Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
        body: jsonEncode(body),
      );

      print("POST DoctorSchedule Status: ${response.statusCode}");
      print("POST DoctorSchedule Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, message: "Doctor schedule created successfully.");
      } else {
        String errorMsg = "Failed to create schedule";
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['errors']?.toString() ?? data['message']?.toString() ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        return ApiResponse(success: false, message: errorMsg);
      }
    } catch (e) {
      print("Error in createDoctorSchedule: $e");
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }

  // تحديث جدول مواعيد الطبيب
  Future<ApiResponse> updateDoctorSchedule(String doctorId, Map<String, dynamic> scheduleData) async {
    final ApiService parent = this as ApiService;
    try {
      // إرسال كائن واحد وليس قائمة
      final body = {
        "doctorId": doctorId,
        "dayOfWeek": scheduleData['dayOfWeek'],
        "startTime": scheduleData['startTime'],
        "endTime": scheduleData['endTime'],
        "isAvailable": scheduleData['isAvailable'] ?? true,
      };

      print("PUT DoctorSchedule Body: ${jsonEncode(body)}");

      final response = await http.put(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
        body: jsonEncode(body),
      );

      print("PUT DoctorSchedule Status: ${response.statusCode}");
      print("PUT DoctorSchedule Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(success: true, message: "Doctor schedule updated successfully.");
      } else {
        String errorMsg = "Failed to update schedule";
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['errors']?.toString() ?? data['message']?.toString() ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        return ApiResponse(success: false, message: errorMsg);
      }
    } catch (e) {
      print("Error in updateDoctorSchedule: $e");
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

      print("DELETE DoctorSchedule Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(success: true, message: "Doctor schedule deleted successfully.");
      } else {
        return ApiResponse(success: false, message: "Failed to delete schedule: ${response.body}");
      }
    } catch (e) {
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }
}
