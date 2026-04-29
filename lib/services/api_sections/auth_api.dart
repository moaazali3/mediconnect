part of '../api_service.dart';

mixin AuthApi {
  Future<ApiResponse> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String gender,
    required double height,
    required double weight,
    required DateTime dateOfBirth,
    required String bloodType,
    required String address,
    required String emergencyContact,
  }) async {
    final ApiService parent = this as ApiService;
    try {
      String formattedDate = "${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Auth/Register'),
        headers: parent._headers,
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
          "phoneNumber": phone,
          "emergencyContact": emergencyContact,
          "gender": gender,
          "dateOfBirth": formattedDate,
          "address": address,
          "bloodType": bloodType,
          "height": height,
          "weight": weight
        }),
      );
      
      final dynamic body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: body.toString());
      } else {
        return ApiResponse(success: false, message: body['errors']?.toString() ?? body.toString());
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse> login(String email, String password) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Auth/Login'),
        headers: parent._headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final dynamic body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: "Login Successful", data: body);
      } else {
        return ApiResponse(success: false, message: body['errors']?.toString() ?? body.toString());
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<bool> changePassword(String id, String oldPassword, String newPassword) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Profile/change-password/$id'),
        headers: parent._headers,
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
