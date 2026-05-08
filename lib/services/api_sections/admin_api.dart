part of '../api_service.dart';

mixin AdminApi {
  // 1. جلب بيانات الداشبورد
  Future<AdminDashboardModel> getAdminDashboard() async {
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
        Uri.parse('${parent.baseUrl}/Admin/receptionist/$id'),
        headers: parent._headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // 2. جلب أرباح دكتور معين
  Future<double> getDoctorRevenue(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/revenue/doctor/$doctorId'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is num) return data.toDouble();
          if (data is Map) {
            return (data['totalRevenue'] ?? data['TotalRevenue'] ?? data['revenue'] ?? data['Revenue'] ?? 0.0).toDouble();
          }
        } catch (_) {}
        final val = response.body.toString().trim();
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // 3. جلب أرباح تخصص معين
  Future<double> getSpecializationRevenue(String specializationName) async {
    final ApiService parent = this as ApiService;
    try {
      final encodedName = Uri.encodeComponent(specializationName.trim());
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Admin/revenue/specialization/$encodedName'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is num) return data.toDouble();
          if (data is Map) {
            return (data['totalRevenue'] ?? data['TotalRevenue'] ?? data['revenue'] ?? data['Revenue'] ?? 0.0).toDouble();
          }
        } catch (_) {}
        final val = response.body.toString().trim();
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
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
