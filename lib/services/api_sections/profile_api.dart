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
        final body = jsonDecode(response.body);
        String errorMessage = body['errors']?.toString() ?? "Failed to update profile";
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
        final body = jsonDecode(response.body);
        String errorMessage = body['errors']?.toString() ?? "Failed to update doctor profile";
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

  Future<bool> updateReceptionistProfile(String id, ReceptionistProfileModel profile) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.put(
        Uri.parse('${parent.baseUrl}/Profile/Receptionist/$id'),
        headers: parent._headers,
        body: jsonEncode(profile.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        String errorMessage = body['errors']?.toString() ?? "Failed to update receptionist profile";
        throw errorMessage;
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }
}
