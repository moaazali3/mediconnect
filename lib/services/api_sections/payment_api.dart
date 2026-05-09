part of '../api_service.dart';

mixin PaymentApi {
  // إنشاء عملية دفع جديدة
  Future<bool> createPayment(PaymentModel payment) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Payment'),
        headers: parent._headers,
        body: jsonEncode(payment.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // جلب سجل المدفوعات للمريض
  Future<List<PaymentModel>> getPatientPayments(String patientId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Payment/patient/$patientId'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => PaymentModel.fromJson(item)).toList();
      }
      throw "Error fetching payments";
    } catch (e) {
      throw parent.handleError(e);
    }
  }

  // جلب إجمالي أرباح الطبيب (للاستخدام في البروفايل أو التحليلات)
  Future<double> getDoctorTotalEarnings(String doctorId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Payment/doctor/$doctorId/earnings'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return (body['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  // جلب بيانات الدفع لموعد محدد
  // GET /api/Payment/{appointmentId}
  Future<PaymentModel?> getPaymentByAppointment(String appointmentId) async {
    final ApiService parent = this as ApiService;
    try {
      final response = await http.get(
        Uri.parse('${parent.baseUrl}/Payment/$appointmentId'),
        headers: parent._headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          if (data.isEmpty) return null;
          return PaymentModel.fromJson(data.first);
        }
        return PaymentModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // إنشاء دفعة باستخدام appointmentId في الـ path و paymentMethod في الـ body
  // POST /api/Payment/{appointmentId}
  Future<bool> createPaymentByAppointment({
    required String appointmentId,
    required String paymentMethod,
  }) async {
    final ApiService parent = this as ApiService;
    // الـ Backend يتوقع 'Visa' بدل 'Card' لتفادي خطأ الـ Enum Parse
    final backendMethod = paymentMethod == 'Card' ? 'Visa' : paymentMethod;
    try {
      final response = await http.post(
        Uri.parse('${parent.baseUrl}/Payment/$appointmentId'),
        headers: parent._headers,
        body: jsonEncode({'paymentMethod': backendMethod}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
