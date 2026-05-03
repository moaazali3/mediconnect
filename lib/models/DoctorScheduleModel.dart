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

  bool isScheduledFor(int weekday) {
    if (dayOfWeek == null) return false;
    String dayStr = dayOfWeek.toString().trim().toLowerCase();
    
    // Handle Numeric representation (e.g. "1" or 1)
    int? dayInt = int.tryParse(dayStr);
    if (dayInt != null) {
      if (dayInt == 0 && weekday == 7) return true; // Sunday as 0
      if (dayInt == 7 && weekday == 7) return true; // Sunday as 7
      return dayInt == weekday;
    }

    // Handle String representation (e.g. "Monday" or "Mon")
    const dayNames = ['', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    if (weekday >= 1 && weekday <= 7) {
      String targetDay = dayNames[weekday];
      return dayStr == targetDay || dayStr.startsWith(targetDay.substring(0, 3));
    }
    
    return false;
  }

  String getDayName() {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int? dayInt = int.tryParse(dayOfWeek.toString());
    if (dayInt != null && dayInt >= 0 && dayInt <= 7) {
      return days[dayInt];
    }
    if (dayOfWeek is String && dayOfWeek.isNotEmpty) {
      return dayOfWeek;
    }
    return 'Unknown';
  }
}
