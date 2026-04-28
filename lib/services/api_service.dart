import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/MedicalRecordModel.dart';
import 'package:mediconnect/models/PaymentModel.dart';

class ApiService {
  final String baseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev/api";

  // إضافة هيدر لتخطي تحذير ngrok وضمان استلام JSON
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': '69420', // كود تخطي تحذير ngrok
  };

  // --- Profile Services ---
  Future<PatientProfileModel> getPatientProfile(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Profile/patient/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return PatientProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw "فشل في تحميل بيانات ملف المريض (كود: ${response.statusCode})";
    }
  }

  Future<bool> updatePatientProfile(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Profile/patient/$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<DoctorProfileModel> getDoctorProfile(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Profile/doctor/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return DoctorProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw "فشل في تحميل بيانات الملف الشخصي (كود: ${response.statusCode})";
    }
  }

  Future<bool> updateDoctorProfile(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Profile/doctor/$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- Auth Services ---
  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Profile/change-password/$userId'),
        headers: _headers,
        body: jsonEncode({
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- Appointment Services ---
  Future<bool> createAppointment(CreateAppointmentModel appointment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Appointment'),
      headers: _headers,
      body: jsonEncode(appointment.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<DoctorAppointmentModel>> getDoctorAppointments(String doctorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Appointment/doctor/$doctorId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorAppointmentModel.fromJson(item)).toList();
    }
    throw "خطأ في جلب مواعيد الطبيب (كود: ${response.statusCode})";
  }

  Future<List<PatientAppointmentModel>> getPatientAppointments(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Appointment/patient/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => PatientAppointmentModel.fromJson(item)).toList();
    }
    throw "خطأ في جلب مواعيد المريض (كود: ${response.statusCode})";
  }

  Future<bool> completeAppointmentStatus(String appointmentId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Appointment/complete?appointmentId=$appointmentId'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  Future<bool> cancelAppointmentStatus(String appointmentId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Appointment/cancel?appointmentId=$appointmentId'),
      headers: _headers,
    );
    return response.statusCode == 200;
  }

  // --- Doctor Schedule Services ---
  Future<List<DoctorScheduleModel>> getDoctorSchedule(String doctorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/DoctorSchedule/$doctorId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorScheduleModel.fromJson(item)).toList();
    }
    throw "Error fetching doctor schedule (كود: ${response.statusCode})";
  }

  Future<bool> createDoctorSchedule(DoctorScheduleModel schedule, String doctorId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DoctorSchedule?DoctorId=$doctorId'),
        headers: _headers,
        body: jsonEncode(schedule.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Medical Record Services ---
  Future<List<MedicalRecordModel>> getPatientMedicalHistory(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MedicalRecord/patient/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => MedicalRecordModel.fromJson(item)).toList();
    }
    throw "Error fetching medical history (كود: ${response.statusCode})";
  }

  // --- Payment Services ---
  Future<bool> createPayment(PaymentModel payment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Payment'),
      headers: _headers,
      body: jsonEncode(payment.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // --- Doctor Services ---
  Future<List<DoctorModel>> getAllDoctors({String? specializationName, int pageNumber = 1}) async {
    final Map<String, String> queryParameters = {
      'pageNumber': pageNumber.toString(),
    };

    if (specializationName != null && specializationName != "All") {
      queryParameters['specializationName'] = specializationName;
    }

    final uri = Uri.parse('$baseUrl/Doctor').replace(queryParameters: queryParameters);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorModel.fromJson(item)).toList();
    } else {
      throw "Server error! (كود: ${response.statusCode})";
    }
  }

  Future<DoctorFullModel> getDoctorDetails(String doctorId, String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Doctor/$doctorId/$patientId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return DoctorFullModel.fromJson(jsonDecode(response.body));
    }
    throw "خطأ في تحميل بيانات الدكتور (كود: ${response.statusCode})";
  }

  Future<bool> createDoctor(CreateDoctorModel doctor) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Doctor'),
        headers: _headers,
        body: jsonEncode(doctor.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Specialization Services ---
  Future<List<SpecializationModel>> getAllSpecializations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Specialization'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => SpecializationModel.fromJson(item)).toList();
    } else {
      throw "Error fetching specializations (كود: ${response.statusCode})";
    }
  }

  Future<bool> updateSpecialization(int id, CreateSpecializationModel specialization) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Specialization/$id'),
        headers: _headers,
        body: jsonEncode(specialization.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createSpecialization(CreateSpecializationModel specialization) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Specialization'),
        headers: _headers,
        body: jsonEncode(specialization.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Auth Services ---
  Future<bool> registerUser({
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
    try {
      String formattedDate = "${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'),
        headers: _headers,
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
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
