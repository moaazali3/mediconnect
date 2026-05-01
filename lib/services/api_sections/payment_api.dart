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
    final response = await http.get(
      Uri.parse('${parent.baseUrl}/Payment/patient/$patientId'),
      headers: parent._headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => PaymentModel.fromJson(item)).toList();
    }
    throw "Error fetching payments";
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
}
