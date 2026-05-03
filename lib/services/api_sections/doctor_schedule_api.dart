part of '../api_service.dart';

mixin DoctorScheduleApi {
  // Get doctor schedule
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
        // If doctor has no schedule yet, return empty list instead of error
        return [];
      } else {
        throw "Server returned ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw parent.handleError(e);
      }
      print("Error in getDoctorSchedule: $e");
      // In case of error, prefer returning empty list to ensure UI continues working
      return [];
    }
  }

  // Create new doctor schedule
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
      return ApiResponse(success: false, message: parent.handleError(e));
    }
  }

  // Update doctor schedule
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
      return ApiResponse(success: false, message: parent.handleError(e));
    }
  }

  // Delete doctor schedule
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
      return ApiResponse(success: false, message: parent.handleError(e));
    }
  }
}
