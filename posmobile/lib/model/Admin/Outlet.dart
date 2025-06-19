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
      id: json['id'].toString(),
      outlet_name: json['outlet_name'] ?? '',
      email: json['email'] ?? '',
      image: json['image'],
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
      message: json['message'] ?? '',
      status: json['status'] ?? false,
      data: (json['data'] as List?)
          ?.map((item) => Outlet.fromJson(item))
          .toList() ?? [],
    );
  }
}
