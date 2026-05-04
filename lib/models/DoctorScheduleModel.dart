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
    bool parseBool(dynamic value) {
      if (value == null) return true; 
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return true;
    }

    return DoctorScheduleModel(
      scheduleId: (json['scheduleId'] ?? json['ScheduleId'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? json['DoctorId'])?.toString(),
      dayOfWeek: json['dayOfWeek'] ?? json['DayOfWeek'] ?? '',
      startTime: json['startTime'] ?? json['StartTime'] ?? '',
      endTime: json['endTime'] ?? json['EndTime'] ?? '',
      isAvailable: parseBool(json['isAvailable'] ?? json['IsAvailable']),
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

  // فحص مرن جداً يدعم كافة أنظمة ترقيم الأيام والنصوص
  bool isScheduledFor(int weekday) {
    if (dayOfWeek == null) return false;
    
    String dayStr = dayOfWeek.toString().trim().toLowerCase();
    const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    
    // تحويل يوم Flutter (1=الاثنين...7=الأحد) إلى نظام (0=الأحد...6=السبت)
    int target = weekday % 7; 
    
    int? dayInt = int.tryParse(dayStr.split('.')[0]);
    if (dayInt != null) {
      // 1. نظام ISO (1=الاثنين...7=الأحد)
      if (dayInt == weekday) return true;
      // 2. نظام 0-6 (0=الأحد)
      if (dayInt % 7 == target) return true;
      // 3. نظام 1-7 (1=الأحد)
      if (dayInt == (target + 1)) return true;
      return false;
    }

    // مقارنة النصوص (Sunday, Sun, etc.)
    for (int i = 0; i < dayNames.length; i++) {
      if (dayStr == dayNames[i] || dayStr.startsWith(dayNames[i].substring(0, 3))) {
        return i == target;
      }
    }
    
    return false;
  }

  String getDayName() {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int? dayInt = int.tryParse(dayOfWeek.toString().split('.')[0]);
    if (dayInt != null && dayInt >= 0 && dayInt <= 7) {
      return days[dayInt % 7 == 0 ? 0 : dayInt];
    }
    if (dayOfWeek is String && dayOfWeek.isNotEmpty) {
      String s = dayOfWeek.toString();
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }
    return 'Unknown';
  }
}
