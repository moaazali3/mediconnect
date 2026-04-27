class DoctorScheduleModel {
  final String scheduleId;
  final String doctorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  DoctorScheduleModel({
    required this.scheduleId,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      scheduleId: json['scheduleId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
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
}
