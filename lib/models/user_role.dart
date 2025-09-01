enum UserRole { master, admin, viewer }

class UserRoleModel {
  final String id;
  final String email;
  final UserRole role;
  final String? branchId;
  final String? branchName;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRoleModel({
    required this.id,
    required this.email,
    required this.role,
    this.branchId,
    this.branchName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'branchId': branchId,
      'branchName': branchName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserRoleModel.fromMap(Map<String, dynamic> map) {
    return UserRoleModel(
      id: map['id'],
      email: map['email'],
      role: UserRole.values.firstWhere((r) => r.name == map['role']),
      branchId: map['branchId'],
      branchName: map['branchName'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  bool get canEdit => role == UserRole.master || role == UserRole.admin;
  bool get canManageAllBranches => role == UserRole.master;
}
