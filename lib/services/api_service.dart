import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http_original;
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediconnect/auth/screens/login_screen.dart';

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

// Shadow class to route all http.get, http.post etc. through the AuthenticatedClient of ApiService
class http {
  static final ApiService _apiService = ApiService();

  static Future<http_original.Response> get(Uri url, {Map<String, String>? headers}) {
    return _apiService.client.get(url, headers: headers);
  }

  static Future<http_original.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _apiService.client.post(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http_original.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _apiService.client.put(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http_original.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _apiService.client.delete(url, headers: headers, body: body, encoding: encoding);
  }

  static http_original.MultipartRequest MultipartRequest(String method, Uri url) {
    return http_original.MultipartRequest(method, url);
  }
}

class ApiService with AuthApi, AdminApi, ProfileApi, AppointmentApi, DoctorApi, PaymentApi, DoctorScheduleApi {
  final String baseUrl = ApiConstants.baseUrl;

  late final http_original.Client client;

  // Global Navigator Key to support contextless navigation / logouts
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal() {
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

  // Global Logout method
  static Future<void> logout() async {
    print("[ApiService] Logging out user globally...");
    await SecureStorage.deleteData(key: 'auth_token');
    await SecureStorage.deleteData(key: 'refresh_token');
    setToken(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_id');

    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class AuthenticatedClient extends http_original.BaseClient {
  final http_original.Client _inner = http_original.Client();
  final ApiService _apiService;
  bool _isRefreshing = false;

  AuthenticatedClient(this._apiService);

  @override
  Future<http_original.StreamedResponse> send(http_original.BaseRequest request) async {
    // Inject auth token if available
    if (ApiService._token != null) {
      request.headers['Authorization'] = 'Bearer ${ApiService._token}';
    }

    var response = await _inner.send(request);

    if (response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        print("[AuthenticatedClient] 401 Detected. Attempting to refresh token...");
        final refreshResponse = await _apiService.refreshToken();
        if (refreshResponse.success) {
          print("[AuthenticatedClient] Token refreshed successfully! Retrying original request...");
          var newRequest = _cloneRequest(request);
          if (ApiService._token != null) {
            newRequest.headers['Authorization'] = 'Bearer ${ApiService._token}';
          }
          response = await _inner.send(newRequest);
        } else {
          print("[AuthenticatedClient] Token refresh failed. Triggering global logout...");
          await ApiService.logout();
        }
      } catch (e) {
        print("[AuthenticatedClient] Error during token refresh: $e. Triggering global logout...");
        await ApiService.logout();
      } finally {
        _isRefreshing = false;
      }
    } else if (response.statusCode == 401 && _isRefreshing) {
      print("[AuthenticatedClient] 401 Detected while already refreshing. Session is completely invalid. Logout...");
      await ApiService.logout();
    }

    return response;
  }

  http_original.BaseRequest _cloneRequest(http_original.BaseRequest request) {
    if (request is http_original.Request) {
      var newRequest = http_original.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      return newRequest;
    } else if (request is http_original.MultipartRequest) {
      var newRequest = http_original.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
      return newRequest;
    }
    return request;
  }
}
