import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/UpdateDoctorModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/MedicalRecordModel.dart';
import 'package:mediconnect/models/PaymentModel.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/CreateReceptionistModel.dart';
import 'package:mediconnect/services/secure_storage.dart';

// استيراد الأجزاء المقسمة
part 'api_sections/auth_api.dart';
part 'api_sections/admin_api.dart';
part 'api_sections/profile_api.dart';
part 'api_sections/appointment_api.dart';
part 'api_sections/doctor_api.dart';
part 'api_sections/payment_api.dart';
part 'api_sections/doctor_schedule_api.dart';

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({required this.success, required this.message, this.data});
}

class ApiService with AuthApi, AdminApi, ProfileApi, AppointmentApi, DoctorApi, PaymentApi, DoctorScheduleApi {
  // ملاحظة: تأكد من أن هذا الرابط هو نفس الرابط الظاهر في Terminal الخاص بـ ngrok
  final String baseUrl = "https://wisdom-frisk-exciting.ngrok-free.dev/api";
  
  // Static cache for doctor images
  static final Map<String, String?> _doctorImagesCache = {};
  
  // Static token to be used in headers
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  // Headers with Authorization token
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  void cacheDoctorImages(List<DoctorModel> doctors) {
    for (var doc in doctors) {
      _doctorImagesCache[doc.id] = doc.profilePictureUrl;
    }
  }

  String? getCachedDoctorImage(String doctorId) {
    return _doctorImagesCache[doctorId];
  }
}
