class DoctorScheduleModel {
  final String scheduleId;
  final String? doctorId;
  final dynamic dayOfWeek; 
  final String startTime;
  final String endTime;
  final bool isAvailable;

  DoctorScheduleModel({
    required this.scheduleId,
    this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      scheduleId: (json['scheduleId'] ?? json['ScheduleId'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['DoctorId'])?.toString(),
      dayOfWeek: json['dayOfWeek'] ?? json['DayOfWeek'] ?? '',
      startTime: json['startTime'] ?? json['StartTime'] ?? '',
      endTime: json['endTime'] ?? json['EndTime'] ?? '',
      isAvailable: json['isAvailable'] ?? json['IsAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "scheduleId": scheduleId,
      "doctorId": doctorId,
      "dayOfWeek": dayOfWeek,
      "startTime": startTime,
      "endTime": endTime,
      "isAvailable": isAvailable,
    };
  }

  String getDayName() {
    if (dayOfWeek is String && dayOfWeek.isNotEmpty) return dayOfWeek;
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    if (dayOfWeek is int && dayOfWeek >= 0 && dayOfWeek < 7) return days[dayOfWeek];
    return 'Unknown';
  }
}
