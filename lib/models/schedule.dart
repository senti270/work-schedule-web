class Schedule {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime workDate;
  final DateTime startTime;
  final DateTime endTime;
  final double workHours;
  final double breakHours;
  final String branchId;
  final String branchName;
  final double hourlyWage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.workHours,
    required this.breakHours,
    required this.branchId,
    required this.branchName,
    required this.hourlyWage,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'workDate': workDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'workHours': workHours,
      'breakHours': breakHours,
      'branchId': branchId,
      'branchName': branchName,
      'hourlyWage': hourlyWage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      employeeId: map['employeeId'],
      employeeName: map['employeeName'],
      workDate: DateTime.parse(map['workDate']),
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      workHours: map['workHours'].toDouble(),
      breakHours: map['breakHours'].toDouble(),
      branchId: map['branchId'],
      branchName: map['branchName'],
      hourlyWage: map['hourlyWage'].toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Schedule copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? workDate,
    DateTime? startTime,
    DateTime? endTime,
    double? workHours,
    double? breakHours,
    String? branchId,
    String? branchName,
    double? hourlyWage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      workDate: workDate ?? this.workDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workHours: workHours ?? this.workHours,
      breakHours: breakHours ?? this.breakHours,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalPay => workHours * hourlyWage;
}

class WeeklySchedule {
  final String id;
  final String branchId;
  final String branchName;
  final DateTime weekStartDate;
  final List<Schedule> schedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklySchedule({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.weekStartDate,
    required this.schedules,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchId': branchId,
      'branchName': branchName,
      'weekStartDate': weekStartDate.toIso8601String(),
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeeklySchedule.fromMap(Map<String, dynamic> map) {
    return WeeklySchedule(
      id: map['id'],
      branchId: map['branchId'],
      branchName: map['branchName'],
      weekStartDate: DateTime.parse(map['weekStartDate']),
      schedules: (map['schedules'] as List)
          .map((s) => Schedule.fromMap(s))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
