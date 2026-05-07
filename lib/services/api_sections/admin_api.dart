part of '../api_service.dart';

mixin AdminApi {
  Future<AdminDashboardModel> getAdminDashboardStats() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Admin/dashboard'), headers: parent._headers);
      if (response.statusCode == 200) {
        return AdminDashboardModel.fromJson(jsonDecode(response.body));
      } else {
        throw "Failed to load dashboard: ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<List<AppointmentModel>> getAllAppointments({int pageNumber = 1, int pageSize = 1000}) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/all-appointments?pageNumber=$pageNumber&pageSize=$pageSize'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = decoded['data'] ?? decoded['appointments'] ?? decoded['items'] ?? decoded['values'] ?? [];
        }
        return data.map((item) => AppointmentModel.fromJson(item)).toList();
      } else {
        throw "Failed to load all appointments: Status ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<List<AppointmentModel>> getTodayAppointments() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/today-appointments'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = decoded['data'] ?? decoded['appointments'] ?? decoded['items'] ?? decoded['values'] ?? [];
        }
        return data.map((item) => AppointmentModel.fromJson(item)).toList();
      } else {
        throw "Failed to load today's appointments: Status ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<List<PatientProfileModel>> getAllPatients() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/patients'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = decoded['data'] ?? decoded['patients'] ?? decoded['items'] ?? decoded['values'] ?? [];
        }
        return data.map((item) => PatientProfileModel.fromJson(item)).toList();
      } else {
        throw "Failed to load patients: ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<List<DoctorModel>> getDoctorsWorkingToday() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/doctors-working-today'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = decoded['data'] ?? decoded['doctors'] ?? decoded['items'] ?? decoded['values'] ?? [];
        }
        return data.map((item) => DoctorModel.fromJson(item)).toList();
      } else {
        throw "Failed to load doctors working today: ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<List<ReceptionistProfileModel>> getAllReceptionists() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/receptionists'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          data = decoded['data'] ?? decoded['receptionists'] ?? decoded['items'] ?? decoded['values'] ?? [];
        }
        return data.map((item) => ReceptionistProfileModel.fromJson(item)).toList();
      } else {
        throw "Failed to load receptionists: ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<bool> deleteReceptionist(String id) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.delete(
        Uri.parse('${parent.baseUrl}/Admin/receptionist/$id'),
        headers: parent._headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
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
      throw "Failed to load doctor revenue: ${response.statusCode}";
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
      throw "Failed to load specialization revenue: ${response.statusCode}";
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
