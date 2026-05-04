part of '../api_service.dart';

mixin AdminApi {
  Future<AdminDashboardModel> getAdminDashboardStats() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Admin/dashboard'), headers: parent._headers);
      if (response.statusCode == 200) {
        return AdminDashboardModel.fromJson(jsonDecode(response.body));
      } else {
        throw "Failed to load admin dashboard stats";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<List<AppointmentModel>> getAllAppointments({int pageNumber = 1}) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/appointments?pageNumber=$pageNumber'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => AppointmentModel.fromJson(item)).toList();
      } else {
        throw "Failed to load all appointments";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDoctorRevenue(String doctorId) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Admin/revenue/doctor/$doctorId'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw "Failed to load doctor revenue";
    }
  }

  Future<Map<String, dynamic>> getSpecializationRevenue(String specializationName) async {
    final ApiService parent = this as ApiService;
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Admin/revenue/specialization/$specializationName'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw "Failed to load specialization revenue";
    }
  }

  Future<bool> deleteDoctor(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.delete(
        Uri.parse('${parent.baseUrl}/Admin/doctor/$doctorId'),
        headers: parent._headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createReceptionist(CreateReceptionistModel receptionist) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Receptionist'),
        headers: parent._headers,
        body: jsonEncode(receptionist.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        String errorMessage = "Failed to add receptionist";
        if (errorBody is Map) {
          errorMessage = errorBody['message'] ?? errorBody['errors']?.toString() ?? errorMessage;
        }
        throw errorMessage;
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }
}
