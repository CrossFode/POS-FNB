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
      id: json['id'] ?? '',
      outletName: json['outlet_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}


