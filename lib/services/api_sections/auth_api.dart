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
      
      dynamic body;
      try {
        if (response.body.isNotEmpty) {
          body = jsonDecode(response.body);
        }
      } catch (_) {
        body = response.body;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, message: "Verification code sent to your email", data: body);
      } else {
        String errorMessage = "Registration failed";
        if (body is Map) {
          if (body.containsKey('errors')) {
            errorMessage = body['errors'].toString();
          } else if (body.containsKey('message')) {
            errorMessage = body['message'];
          } else if (body.containsKey('title')) {
            errorMessage = body['title'];
          }
        } else if (body is String && body.isNotEmpty) {
          errorMessage = body;
        }
        return ApiResponse(success: false, message: errorMessage);
      }
    } catch (e) {
      return ApiResponse(success: false, message: parent.handleError(e));
    }
  }

  Future<ApiResponse> confirmEmail(String email, String otp) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Auth/ConfirmEmail?email=$email&otp=$otp'),
        headers: parent._headers,
      );

      dynamic body;
      try {
        if (response.body.isNotEmpty) {
          body = jsonDecode(response.body);
        }
      } catch (_) {
        body = response.body;
      }

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: "Email verified successfully", data: body);
      } else {
        String errorMessage = "Verification failed";
        if (body is Map && body.containsKey('message')) {
          errorMessage = body['message'];
        }
        return ApiResponse(success: false, message: errorMessage);
      }
    } catch (e) {
      return ApiResponse(success: false, message: parent.handleError(e));
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
      
      dynamic body;
      try {
        if (response.body.isNotEmpty) {
          body = jsonDecode(response.body);
        }
      } catch (_) {
        body = response.body;
      }

      if (response.statusCode == 200) {
        // Save tokens in secure storage
        if (body is Map && body.containsKey('token')) {
          await SecureStorage.writeData(key: 'auth_token', value: body['token']);
          await SecureStorage.writeData(key: 'refresh_token', value: body['refreshToken']);
        }
        return ApiResponse(success: true, message: "Login Successful", data: body);
      } else {
        String errorMessage = "Login failed";
        if (body is Map) {
          if (body.containsKey('errors')) {
            errorMessage = body['errors'].toString();
          } else if (body.containsKey('message')) {
            errorMessage = body['message'];
          }
        }
        return ApiResponse(success: false, message: errorMessage);
      }
    } catch (e) {
      return ApiResponse(success: false, message: parent.handleError(e));
    }
  }

  Future<ApiResponse> refreshToken() async {
    final ApiService parent = this as ApiService;
    try {
      final currentRefreshToken = await SecureStorage.readData(key: 'refresh_token');
      if (currentRefreshToken == null) {
        return ApiResponse(success: false, message: "No refresh token found");
      }

      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Auth/RefreshToken?refreshToken=$currentRefreshToken'),
        headers: parent._headers,
      );

      dynamic body;
      try {
        if (response.body.isNotEmpty) {
          body = jsonDecode(response.body);
        }
      } catch (_) {
        body = response.body;
      }

      if (response.statusCode == 200) {
        if (body is Map && body.containsKey('token')) {
          await SecureStorage.writeData(key: 'auth_token', value: body['token']);
          await SecureStorage.writeData(key: 'refresh_token', value: body['refreshToken']);
        }
        return ApiResponse(success: true, message: "Token refreshed", data: body);
      } else {
        return ApiResponse(success: false, message: "Failed to refresh token");
      }
    } catch (e) {
      return ApiResponse(success: false, message: parent.handleError(e));
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
