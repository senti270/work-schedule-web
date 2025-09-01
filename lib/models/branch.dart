class Branch {
  final String id;
  final String name;
  final String adminId;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.name,
    required this.adminId,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      name: map['name'],
      adminId: map['adminId'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Branch copyWith({
    String? id,
    String? name,
    String? adminId,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      adminId: adminId ?? this.adminId,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
