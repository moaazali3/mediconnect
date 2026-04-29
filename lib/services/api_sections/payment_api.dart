part of '../api_service.dart';

mixin PaymentApi {
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
}
