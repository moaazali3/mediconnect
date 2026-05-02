class AdminDashboardModel {
  final int totalPatients;
  final int totalDoctors;
  final int totalDoctorsToday; // Added this
  final int totalAppointments;
  final int totalAppointmentsToday;
  final int totalPendingAppointmentsToday;
  final int totalCompletedAppointmentsToday;
  final int totalCancelledAppointmentsToday;
  final int totalPendingAppointments;
  final int totalCompletedAppointments;
  final int totalCancelledAppointments;
  final double totalRevenueToday;
  final double totalRevenue;

  AdminDashboardModel({
    required this.totalPatients,
    required this.totalDoctors,
    required this.totalDoctorsToday,
    required this.totalAppointments,
    required this.totalAppointmentsToday,
    required this.totalPendingAppointmentsToday,
    required this.totalCompletedAppointmentsToday,
    required this.totalCancelledAppointmentsToday,
    required this.totalPendingAppointments,
    required this.totalCompletedAppointments,
    required this.totalCancelledAppointments,
    required this.totalRevenueToday,
    required this.totalRevenue,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalPatients: json['totalPatients'] ?? 0,
      totalDoctors: json['totalDoctors'] ?? 0,
      totalDoctorsToday: json['totalDoctorsToday'] ?? 0, // Added this
      totalAppointments: json['totalAppointments'] ?? 0,
      totalAppointmentsToday: json['totalAppointmentsToday'] ?? 0,
      totalPendingAppointmentsToday: json['totalPendingAppointmentsToday'] ?? 0,
      totalCompletedAppointmentsToday: json['totalCompletedAppointmentsToday'] ?? 0,
      totalCancelledAppointmentsToday: json['totalCancelledAppointmentsToday'] ?? 0,
      totalPendingAppointments: json['totalpendingAppointments'] ?? 0,
      totalCompletedAppointments: json['totalCompletedAppointments'] ?? 0,
      totalCancelledAppointments: json['totalCancelledAppointments'] ?? 0,
      totalRevenueToday: (json['totalRevenueToday'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPatients': totalPatients,
      'totalDoctors': totalDoctors,
      'totalDoctorsToday': totalDoctorsToday,
      'totalAppointments': totalAppointments,
      'totalAppointmentsToday': totalAppointmentsToday,
      'totalPendingAppointmentsToday': totalPendingAppointmentsToday,
      'totalCompletedAppointmentsToday': totalCompletedAppointmentsToday,
      'totalCancelledAppointmentsToday': totalCancelledAppointmentsToday,
      'totalpendingAppointments': totalPendingAppointments,
      'totalCompletedAppointments': totalCompletedAppointments,
      'totalCancelledAppointments': totalCancelledAppointments,
      'totalRevenueToday': totalRevenueToday,
      'totalRevenue': totalRevenue,
    };
  }
}
