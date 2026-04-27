class PaymentModel {
  final String paymentId;
  final String appointmentId;
  final String createdDate;
  final String paymentMethod;
  final String paymentStatus;
  final double amount;

  PaymentModel({
    required this.paymentId,
    required this.appointmentId,
    required this.createdDate,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.amount,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      createdDate: json['createdDate'] ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      paymentStatus: json['paymentStatus']?.toString() ?? 'Pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "appointmentId": appointmentId,
      "paymentMethod": paymentMethod,
      "amount": amount,
    };
  }
}
