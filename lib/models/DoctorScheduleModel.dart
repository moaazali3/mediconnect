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

  // دالة متطورة للتحقق من اليوم الحالي
  bool isScheduledFor(int weekday) {
    // تحويل اليوم القادم من API لنص موحد
    String dayStr = dayOfWeek.toString().trim().toLowerCase();
    
    // الأيام بالترتيب (DateTime.monday = 1, ..., DateTime.sunday = 7)
    const dayNames = ['', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    // 1. إذا كان القادم من API هو رقم
    int? dayInt = int.tryParse(dayStr);
    if (dayInt != null) {
      // التعامل مع الأنظمة التي تعتبر الأحد 0 أو 7
      if (dayInt == 0 && weekday == 7) return true; // Sunday
      return dayInt == weekday;
    }

    // 2. إذا كان القادم من API هو نص (اسم اليوم)
    if (weekday >= 1 && weekday <= 7) {
      String currentDayName = dayNames[weekday];
      return dayStr == currentDayName || dayStr.startsWith(currentDayName.substring(0, 3));
    }

    return false;
  }

  String getDayName() {
    if (dayOfWeek is String && dayOfWeek.isNotEmpty) return dayOfWeek;
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek is int && dayOfWeek >= 0 && dayOfWeek <= 7) return days[dayOfWeek];
    return 'Unknown';
  }
}
