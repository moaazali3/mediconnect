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
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => DoctorScheduleModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw "Server returned ${response.statusCode}";
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
      // بناءً على رسالة الخطأ "model field is required"
      // السيرفر يتوقع كائناً يحتوي على حقل يسمى "model" وهو عبارة عن قائمة
      final body = {
        "model": [
          {
            "doctorId": doctorId,
            "dayOfWeek": scheduleData['dayOfWeek'],
            "startTime": scheduleData['startTime'],
            "endTime": scheduleData['endTime'],
            "isAvailable": scheduleData['isAvailable'] ?? true,
          }
        ]
      };

      print("POST DoctorSchedule Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
        body: jsonEncode(body),
      );

      print("POST DoctorSchedule Status: ${response.statusCode}");
      print("POST DoctorSchedule Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return ApiResponse(success: true, message: "Doctor schedule updated successfully.");
      } else {
        String errorMsg = "Failed to update schedule";
        try {
          final data = jsonDecode(response.body);
          if (data['errors'] != null) {
            errorMsg = data['errors'].toString();
          } else {
            errorMsg = data['message'] ?? data['title'] ?? response.body;
          }
        } catch (_) {
          errorMsg = response.body;
        }
        return ApiResponse(success: false, message: errorMsg);
      }
    } catch (e) {
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }

  Future<ApiResponse> updateDoctorSchedule(String doctorId, Map<String, dynamic> scheduleData) async {
    return createDoctorSchedule(doctorId, scheduleData); 
  }

  Future<ApiResponse> deleteDoctorSchedule(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.delete(
        Uri.parse('${parent.baseUrl}/DoctorSchedule/$doctorId'),
        headers: parent._headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(success: true, message: "Doctor schedule deleted.");
      } else {
        return ApiResponse(success: false, message: "Failed to delete: ${response.body}");
      }
    } catch (e) {
      return ApiResponse(success: false, message: "Connection error: $e");
    }
  }
}
