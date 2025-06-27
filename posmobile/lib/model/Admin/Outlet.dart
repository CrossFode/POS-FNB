class Outlet {
  final String id;
  final String outlet_name;
  final String email;
  final String? image;
  int? isActive;
  final String? longitude; // Tambahkan field longitude (opsional)
  final String? latitude;  // Tambahkan field latitude (opsional)

  Outlet({
    required this.id,
    required this.outlet_name,
    required this.email,
    this.image,
    this.isActive,
    this.longitude, // Tambahkan di constructor
    this.latitude,  // Tambahkan di constructor
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['id'].toString(),
      outlet_name: json['outlet_name'] ?? '',
      email: json['email'] ?? '',
      image: json['image'],
      isActive: json['is_active'] ?? json['isActive'],
      longitude: json['longitude']?.toString(), // Ambil dari json jika ada
      latitude: json['latitude']?.toString(),   // Ambil dari json jika ada
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

class OutletResponseById {
  final String message;
  final bool status;
  final Outlet data;

  OutletResponseById({
    required this.message,
    required this.status,
    required this.data,
  });

  factory OutletResponseById.fromJson(Map<String, dynamic> json) {
    return OutletResponseById(
      message: json['message'] as String,
      status: json['status'] as bool,
      data: Outlet.fromJson(
          json['data'] as Map<String, dynamic>), // Directly parse as Map
    );
  }
}
