import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mediconnect/constants/api_constants.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/models/DoctorFullModel.dart';
import 'package:mediconnect/models/SpecializationModel.dart';
import 'package:mediconnect/models/CreateDoctorModel.dart';
import 'package:mediconnect/models/UpdateDoctorModel.dart';
import 'package:mediconnect/models/CreateSpecializationModel.dart';
import 'package:mediconnect/models/DoctorProfileModel.dart';
import 'package:mediconnect/models/PatientProfileModel.dart';
import 'package:mediconnect/models/ReceptionistProfileModel.dart';
import 'package:mediconnect/models/AppointmentModels.dart';
import 'package:mediconnect/models/DoctorScheduleModel.dart';
import 'package:mediconnect/models/MedicalRecordModel.dart';
import 'package:mediconnect/models/PaymentModel.dart';
import 'package:mediconnect/models/AdminDashboardModel.dart';
import 'package:mediconnect/models/CreateReceptionistModel.dart';
import 'package:mediconnect/services/secure_storage.dart';
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
  final String baseUrl = ApiConstants.baseUrl;

  late final http.Client client;

  ApiService() {
    client = AuthenticatedClient(this);
  }

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

  String handleError(dynamic e) {
    if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
      return "No internet connection. Please check your network and try again.";
    }
    return "Connection error: $e";
  }
}

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final ApiService _apiService;
  bool _isRefreshing = false;

  AuthenticatedClient(this._apiService);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var response = await _inner.send(request);

    if (response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshResponse = await _apiService.refreshToken();
        if (refreshResponse.success) {
          // Clone the request with the new token
          var newRequest = _cloneRequest(request);
          if (ApiService._token != null) {
            newRequest.headers['Authorization'] = 'Bearer ${ApiService._token}';
          }
          response = await _inner.send(newRequest);
        }
      } finally {
        _isRefreshing = false;
      }
    }

    return response;
  }

  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    if (request is http.Request) {
      var newRequest = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      return newRequest;
    } else if (request is http.MultipartRequest) {
      var newRequest = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
      return newRequest;
    }
    // Fallback for custom or streamed requests
    return request;
  }
}
