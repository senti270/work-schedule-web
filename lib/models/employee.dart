enum EmployeeType { employee, partTime }

class Employee {
  final String id;
  final String name;
  final String phone;
  final String residentNumber;
  final double hourlyWage;
  final DateTime hireDate;
  final DateTime? resignDate;
  final EmployeeType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.residentNumber,
    required this.hourlyWage,
    required this.hireDate,
    this.resignDate,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'residentNumber': residentNumber,
      'hourlyWage': hourlyWage,
      'hireDate': hireDate.toIso8601String(),
      'resignDate': resignDate?.toIso8601String(),
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      residentNumber: map['residentNumber'],
      hourlyWage: map['hourlyWage'].toDouble(),
      hireDate: DateTime.parse(map['hireDate']),
      resignDate: map['resignDate'] != null ? DateTime.parse(map['resignDate']) : null,
      type: EmployeeType.values.firstWhere((e) => e.name == map['type']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? residentNumber,
    double? hourlyWage,
    DateTime? hireDate,
    DateTime? resignDate,
    EmployeeType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      residentNumber: residentNumber ?? this.residentNumber,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      hireDate: hireDate ?? this.hireDate,
      resignDate: resignDate ?? this.resignDate,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => resignDate == null;
}
