part of '../api_service.dart';

mixin ProfileApi {
  Future<PatientProfileModel> getPatientProfile(String id) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Profile/Patient/$id'), headers: parent._headers);
      if (response.statusCode == 200) {
        return PatientProfileModel.fromJson(jsonDecode(response.body));
      } else {
        throw "Failed to load patient profile data";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<bool> updatePatientProfile(String id, PatientProfileModel profile) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Profile/Patient/$id'),
        headers: parent._headers,
        body: jsonEncode(profile.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String errorMessage = "Failed to update profile";
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            errorMessage = body['errors']?.toString() ?? body['message'] ?? errorMessage;
          }
        } catch (_) {
          if (response.body.isNotEmpty) errorMessage = response.body;
        }
        throw errorMessage;
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<DoctorProfileModel> getDoctorProfile(String id) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Profile/Doctor/$id'), headers: parent._headers);
      if (response.statusCode == 200) {
        return DoctorProfileModel.fromJson(jsonDecode(response.body));
      } else {
        throw "Failed to load doctor profile data";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<bool> updateDoctorProfile(String id, DoctorProfileModel profile) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Profile/Doctor/$id'),
        headers: parent._headers,
        body: jsonEncode(profile.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String errorMessage = "Failed to update doctor profile";
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            errorMessage = body['errors']?.toString() ?? body['message'] ?? errorMessage;
          }
        } catch (_) {
          if (response.body.isNotEmpty) errorMessage = response.body;
        }
        throw errorMessage;
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<ReceptionistProfileModel> getReceptionistProfile(String id) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Profile/Receptionist/$id'), headers: parent._headers);
      if (response.statusCode == 200) {
        return ReceptionistProfileModel.fromJson(jsonDecode(response.body));
      } else {
        throw "Failed to load receptionist profile data";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  // Method to fetch receptionist by doctor ID - now returns nullable to handle doctors without receptionists
  Future<ReceptionistProfileModel?> getReceptionistByDoctorId(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Receptionist/$doctorId'), headers: parent._headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ReceptionistProfileModel.fromJson(decoded);
        }
        return null;
      } else {
        // If doctor doesn't have a receptionist, it might return 404 or other status. 
        // We return null instead of throwing to avoid breaking the UI.
        return null;
      }
    } catch (e) {
      // Return null on any connection or parsing error for this specific optional data
      return null;
    }
  }

  Future<bool> updateReceptionistProfile(String id, ReceptionistProfileModel profile) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Profile/Receptionist/$id'),
        headers: parent._headers,
        body: jsonEncode({
          "firstName": profile.firstName.trim(),
          "lastName": profile.lastName.trim(),
          "dateOfBirth": profile.dateOfBirth,
          "gender": profile.gender,
          "address": profile.address?.trim(),
          "phoneNumber": profile.phoneNumber.trim(),
        }),
      );
      
      print("=== UPDATE RECEPTIONIST PROFILE ===");
      print("URL: ${parent.baseUrl}/Profile/Receptionist/$id");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("===================================");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String errorMessage = "Failed to update receptionist profile (${response.statusCode})";
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            errorMessage = body['errors']?.toString() ?? body['message'] ?? body['title'] ?? errorMessage;
          }
        } catch (_) {
          if (response.body.isNotEmpty) errorMessage = response.body;
        }
        throw errorMessage;
      }
    } catch (e) {
      print("=== UPDATE RECEPTIONIST ERROR: $e ===");
      throw parent.handleError(e);
    }
  }

  Future<bool> changeReceptionistDoctor(String receptionistId, String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Receptionist/$receptionistId/change-doctor/$doctorId'),
        headers: parent._headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String errorMessage = "Failed to change receptionist doctor";
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            errorMessage = body['message'] ?? body['errors']?.toString() ?? errorMessage;
          }
        } catch (_) {}
        throw errorMessage;
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }
}
