import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart'; // تأكد من إضافة الاستيراد
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
class ApiService {
  final String baseUrl = "https://localhost:7039/api";

  Future<PatientProfileModel> getPatientProfile(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/profile/Patient/$id'));
    if (response.statusCode == 200) {
      return PatientProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw "فشل في تحميل بيانات ملف المريض";
    }
  }
  Future<DoctorProfileModel> getDoctorProfile(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/profile/Doctor/$id'));
    if (response.statusCode == 200) {
      return DoctorProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw "فشل في تحميل بيانات الملف الشخصي";
    }
  }
  Future<bool> createAppointment(CreateAppointmentModel appointment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Appointment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(appointment.toJson()),
    );
    return response.statusCode == 200;
  }

// جلب مواعيد الطبيب
  Future<List<DoctorAppointmentModel>> getDoctorAppointments(String doctorId) async {
    final response = await http.get(Uri.parse('$baseUrl/Appointment/Doctor/$doctorId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorAppointmentModel.fromJson(item)).toList();
    }
    throw "خطأ في جلب مواعيد الطبيب";
  }

// جلب مواعيد المريض
  Future<List<PatientAppointmentModel>> getPatientAppointments(String patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/Appointment/Patient/$patientId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => PatientAppointmentModel.fromJson(item)).toList();
    }
    throw "خطأ في جلب مواعيد المريض";
  }
  // تحديث دالة جلب الأطباء لتناسب الـ Backend الجديد (Pagination & Filter)
  Future<List<DoctorModel>> getAllDoctors({String? specializationName, int pageNumber = 1}) async {
    final Map<String, String> queryParameters = {
      'pageNumber': pageNumber.toString(),
    };

    if (specializationName != null && specializationName != "All") {
      queryParameters['specializationName'] = specializationName;
    }

    final uri = Uri.parse('$baseUrl/Doctor').replace(queryParameters: queryParameters);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => DoctorModel.fromJson(item)).toList();
    } else {
      throw "Server error!";
    }
  }

  Future<List<SpecializationModel>> getAllSpecializations() async {
    final response = await http.get(Uri.parse('$baseUrl/Specialization'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => SpecializationModel.fromJson(item)).toList();
    } else {
      throw "Error fetching specializations";
    }
  }
  // دالة لتعديل تخصص موجود
  Future<bool> updateSpecialization(int id, CreateSpecializationModel specialization) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Specialization/$id'), // نرسل الـ id في المسار
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(specialization.toJson()), // نستخدم نفس الـ toJson الخاص بموديل الإضافة
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print("خطأ في تعديل التخصص: ${response.body}");
        return false;
      }
    } catch (e) {
      print("حدث خطأ أثناء الاتصال: $e");
      return false;
    }
  }
  Future<DoctorFullModel> getDoctorDetails(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/Doctor/$id'));
    if (response.statusCode == 200) {
      return DoctorFullModel.fromJson(jsonDecode(response.body));
    }
    throw "خطأ في تحميل بيانات الدكتور";
  }

  // دالة لإضافة طبيب جديد باستخدام الموديل
  Future<bool> createDoctor(CreateDoctorModel doctor) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Doctor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(doctor.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("خطأ في إضافة الطبيب: ${response.body}");
        return false;
      }
    } catch (e) {
      print("حدث خطأ أثناء الاتصال: $e");
      return false;
    }
  }

  // دالة لإضافة تخصص جديد باستخدام الموديل
  Future<bool> createSpecialization(CreateSpecializationModel specialization) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Specialization'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(specialization.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("خطأ في إضافة التخصص: ${response.body}");
        return false;
      }
    } catch (e) {
      print("حدث خطأ أثناء الاتصال: $e");
      return false;
    }
  }

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
      // السطر السحري اللي بيحول التاريخ لـ YYYY-MM-DD من غير وقت
      String formattedDate = "${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
          "phoneNumber": phone,
          "emergencyContact": emergencyContact,
          "gender": gender,
          "dateOfBirth": formattedDate, // <--- التعديل حصل هنا
          "address": address,
          "bloodType": bloodType,
          "height": height,
          "weight": weight
        }),
      );

      print('🔥 Status Code: ${response.statusCode}');
      print('🔥 Server Reply: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 Exception in API request: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        print(jsonDecode(response.body).toString());
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
