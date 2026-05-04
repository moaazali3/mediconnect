class AdminDashboardModel {
  final int totalPatients;
  final int totalDoctors;
  final int totalDoctorsToday;
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

  AdminDashboardModel copyWith({
    int? totalPatients,
    int? totalDoctors,
    int? totalDoctorsToday,
    int? totalAppointments,
    int? totalAppointmentsToday,
    int? totalPendingAppointmentsToday,
    int? totalCompletedAppointmentsToday,
    int? totalCancelledAppointmentsToday,
    int? totalPendingAppointments,
    int? totalCompletedAppointments,
    int? totalCancelledAppointments,
    double? totalRevenueToday,
    double? totalRevenue,
  }) {
    return AdminDashboardModel(
      totalPatients: totalPatients ?? this.totalPatients,
      totalDoctors: totalDoctors ?? this.totalDoctors,
      totalDoctorsToday: totalDoctorsToday ?? this.totalDoctorsToday,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      totalAppointmentsToday: totalAppointmentsToday ?? this.totalAppointmentsToday,
      totalPendingAppointmentsToday: totalPendingAppointmentsToday ?? this.totalPendingAppointmentsToday,
      totalCompletedAppointmentsToday: totalCompletedAppointmentsToday ?? this.totalCompletedAppointmentsToday,
      totalCancelledAppointmentsToday: totalCancelledAppointmentsToday ?? this.totalCancelledAppointmentsToday,
      totalPendingAppointments: totalPendingAppointments ?? this.totalPendingAppointments,
      totalCompletedAppointments: totalCompletedAppointments ?? this.totalCompletedAppointments,
      totalCancelledAppointments: totalCancelledAppointments ?? this.totalCancelledAppointments,
      totalRevenueToday: totalRevenueToday ?? this.totalRevenueToday,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalPatients: json['totalPatients'] ?? json['TotalPatients'] ?? 0,
      totalDoctors: json['totalDoctors'] ?? json['TotalDoctors'] ?? 0,
      totalDoctorsToday: json['totalDoctorsToday'] ?? json['TotalDoctorsToday'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? json['TotalAppointments'] ?? 0,
      totalAppointmentsToday: json['totalAppointmentsToday'] ?? json['TotalAppointmentsToday'] ?? 0,
      totalPendingAppointmentsToday: json['totalPendingAppointmentsToday'] ?? json['TotalPendingAppointmentsToday'] ?? 0,
      totalCompletedAppointmentsToday: json['totalCompletedAppointmentsToday'] ?? json['TotalCompletedAppointmentsToday'] ?? 0,
      totalCancelledAppointmentsToday: json['totalCancelledAppointmentsToday'] ?? json['TotalCancelledAppointmentsToday'] ?? 0,
      totalPendingAppointments: json['totalPendingAppointments'] ?? json['totalpendingAppointments'] ?? json['TotalPendingAppointments'] ?? 0,
      totalCompletedAppointments: json['totalCompletedAppointments'] ?? json['TotalCompletedAppointments'] ?? 0,
      totalCancelledAppointments: json['totalCancelledAppointments'] ?? json['TotalCancelledAppointments'] ?? 0,
      totalRevenueToday: (json['totalRevenueToday'] ?? json['TotalRevenueToday'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? json['TotalRevenue'] ?? 0).toDouble(),
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
      'totalPendingAppointments': totalPendingAppointments,
      'totalCompletedAppointments': totalCompletedAppointments,
      'totalCancelledAppointments': totalCancelledAppointments,
      'totalRevenueToday': totalRevenueToday,
      'totalRevenue': totalRevenue,
    };
  }
}
