part of '../api_service.dart';

mixin AdminApi {
  Future<AdminDashboardModel> getAdminDashboardStats() async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(Uri.parse('${parent.baseUrl}/Admin/dashboard'), headers: parent._headers);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        Map<String, dynamic> data = {};
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            data = Map<String, dynamic>.from(decoded['data']);
          } else {
            data = Map<String, dynamic>.from(decoded);
          }
        }
        return AdminDashboardModel.fromJson(data);
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

  Future<List<AppointmentModel>> getTodayAppointments({int pageNumber = 1}) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/today-appointments?pageNumber=$pageNumber'),
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
        Uri.parse('${parent.baseUrl}/Receptionist/$id'),
        headers: parent._headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String errorMessage = "Failed to delete receptionist";
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map) {
            errorMessage = errorBody['message'] ?? errorBody['errors']?.toString() ?? errorMessage;
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : "Error ${response.statusCode}";
        }

        if (errorMessage.contains("entity changes") || errorMessage.contains("inner exception")) {
          errorMessage = "Cannot delete receptionist because there are related records. Please delete the dependencies first.";
        }
        
        throw errorMessage;
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<double> getDoctorRevenue(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/revenue/doctor/$doctorId'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          var val = decoded['revenue'] ?? decoded['totalRevenue'] ?? decoded['data'] ?? 0;
          if (val is Map && val.containsKey('revenue')) val = val['revenue'];
          return (val ?? 0).toDouble();
        } else if (decoded is num) {
          return decoded.toDouble();
        } else {
          return double.tryParse(decoded.toString()) ?? 0.0;
        }
      } else {
        throw "Failed to load doctor revenue: ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<double> getSpecializationRevenue(String specializationName) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/revenue/specialization/$specializationName'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          var val = decoded['revenue'] ?? decoded['totalRevenue'] ?? decoded['data'] ?? 0;
          if (val is Map && val.containsKey('revenue')) val = val['revenue'];
          return (val ?? 0).toDouble();
        } else if (decoded is num) {
          return decoded.toDouble();
        } else {
          return double.tryParse(decoded.toString()) ?? 0.0;
        }
      } else {
        throw "Failed to load specialization revenue: ${response.statusCode}";
      }
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  Future<bool> deleteDoctor(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.delete(
        Uri.parse('${parent.baseUrl}/Doctor/$doctorId'),
        headers: parent._headers,
      );
      
      debugPrint("DELETE DOCTOR STATUS: ${response.statusCode}");
      debugPrint("DELETE DOCTOR BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String errorMessage = "Failed to delete doctor";
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map) {
            errorMessage = errorBody['message'] ?? errorBody['errors']?.toString() ?? errorMessage;
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : "Error ${response.statusCode}";
        }

        // Handle related records error in English
        if (errorMessage.contains("entity changes") || errorMessage.contains("inner exception")) {
          errorMessage = "Cannot delete doctor because there are related records (appointments or schedules). Please delete related data first.";
        }

        throw errorMessage;
      }
    } catch (e) {
      debugPrint("DELETE DOCTOR API EXCEPTION: $e");
      throw parent.handleError(e);
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
