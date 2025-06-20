class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int roleId;
  final int isActive;
  final String created;
  final List<UserOutlet> outlets;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleId,
    required this.isActive,
    required this.created,
    required this.outlets,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      roleId: int.tryParse(json['role_id'].toString()) ?? 0,
      isActive: int.tryParse(json['is_active'].toString()) ?? 0,
      created: json['created'] ?? '',
      outlets: (json['outlets'] as List<dynamic>?)
              ?.map((o) => UserOutlet.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class RoleModel {
  final int value;
  final String label;

  RoleModel({required this.value, required this.label});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      value: int.tryParse(json['value'].toString()) ?? 0,
      label: json['label'] ?? '',
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

class UserOutlet {
  final String id;
  final String outletName;
  final String email;

  UserOutlet({
    required this.id,
    required this.outletName,
    required this.email,
  });

  factory UserOutlet.fromJson(Map<String, dynamic> json) {
    return UserOutlet(
      id: json['id']?.toString() ?? '',
      outletName: json['outlet_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class UserResponse {
  final String message;
  final bool status;
  final List<User> data;

  UserResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? false,
      data: (json['data'] as List?)
          ?.map((item) => User.fromJson(item))
          .toList() ?? [],
    );
  }
}