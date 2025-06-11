class Outlet {
  final String id;
  final String outlet_name;
  final String email;
  final String? image;

  Outlet({
    required this.id,
    required this.outlet_name,
    required this.email,
    this.image,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['id'] as String,
      outlet_name: json['outlet_name'] as String,
      email: json['email'] as String,
      image: json['image'] as String?,
    );
  }
}

class OutletResponse {
  final String message;
  final bool status;
  final List<Outlet> data;

  OutletResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory OutletResponse.fromJson(Map<String, dynamic> json) {
    return OutletResponse(
      message: json['message'] as String,
      status: json['status'] as bool,
      data: (json['data'] as List)
          .map((i) => Outlet.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
