class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int roleId;
  final List<int> outlets;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleId,
    required this.outlets,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? '',
      roleId: json['role_id'] ?? 0,
      outlets: (json['outlets'] as List?)
          ?.map((outlet) => outlet is Map ? outlet['id'] as int : outlet as int)
          .toList() ?? [],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RoleModel {
  final int value;
  final String label;

  RoleModel({required this.value, required this.label});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      value: json['value'],
      label: json['label'],
    );
  }
}

class OutletModel {
  final int id;
  final String name;

  OutletModel({required this.id, required this.name});

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'],
      name: json['outlet_name'] ?? json['name'] ?? '',
    );
  }
}