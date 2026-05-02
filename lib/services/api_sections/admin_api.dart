part of '../api_service.dart';

mixin AdminApi {
  Future<AdminDashboardModel> getAdminDashboardStats() async {
    final ApiService parent = this as ApiService;
    final response = await http.get(Uri.parse('${parent.baseUrl}/Admin/dashboard'), headers: parent._headers);
    if (response.statusCode == 200) {
      return AdminDashboardModel.fromJson(jsonDecode(response.body));
    } else {
      throw "Failed to load admin dashboard stats";
    }
  }

  Future<List<AppointmentModel>> getAllAppointments({int pageNumber = 1}) async {
    final ApiService parent = this as ApiService;
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
  }

  Future<bool> deleteDoctor(String doctorId) async {
    final ApiService parent = this as ApiService;
    final response = await http.delete(
      Uri.parse('${parent.baseUrl}/Admin/doctor/$doctorId'),
      headers: parent._headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
