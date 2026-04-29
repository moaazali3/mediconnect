class AdminDashboardModel {
  final int totalPatients;
  final int totalDoctors;
  final int totalAppointments;
  final int totalCompletedAppointments;
  final int totalCancelledAppointments;
  final int totalPendingAppointments;
  final double totalRevenue;

  AdminDashboardModel({
    required this.totalPatients,
    required this.totalDoctors,
    required this.totalAppointments,
    required this.totalCompletedAppointments,
    required this.totalCancelledAppointments,
    required this.totalPendingAppointments,
    required this.totalRevenue,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalPatients: json['totalPatients'] ?? 0,
      totalDoctors: json['totalDoctors'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      totalCompletedAppointments: json['totalCompletedAppointments'] ?? 0,
      totalCancelledAppointments: json['totalCancelledAppointments'] ?? 0,
      totalPendingAppointments: json['totalpendingAppointments'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPatients': totalPatients,
      'totalDoctors': totalDoctors,
      'totalAppointments': totalAppointments,
      'totalCompletedAppointments': totalCompletedAppointments,
      'totalCancelledAppointments': totalCancelledAppointments,
      'totalpendingAppointments': totalPendingAppointments,
      'totalRevenue': totalRevenue,
    };
  }
}
