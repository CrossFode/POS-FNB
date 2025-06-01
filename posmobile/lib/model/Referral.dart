class ReferralCode {
  final int id;
  final String? code; // Dari `String` jadi `String?` (nullable)
  final String? description; // Dari `String` jadi `String?`
  final int quotas;
  final DateTime expiredDate;
  final int discount;
  final DateTime? createdAt; // Dari `DateTime` jadi `DateTime?`
  final int? usaged; // Dari `int` jadi `int?`

  ReferralCode({
    required this.id,
    this.code, // Tidak `required` lagi
    this.description, // Tidak `required` lagi
    required this.quotas,
    required this.expiredDate,
    required this.discount,
    this.createdAt, // Tidak `required` lagi
    this.usaged, // Tidak `required` lagi
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      id: json['id'] ?? 0,
      code: json['code'], // Boleh null
      description: json['description'], // Boleh null
      quotas: json['quotas'] ?? 0,
      expiredDate: DateTime.parse(json['expired_date']),
      discount: json['discount'] ?? 0,
      createdAt: json['created_at'] != null // Handle null
          ? DateTime.parse(json['created_at'])
          : null,
      usaged: json['usaged'], // Boleh null
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
      };
}

class ReferralCodeResponse {
  final String message;
  final bool status;
  final ReferralCode data;

  ReferralCodeResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory ReferralCodeResponse.fromJson(Map<String, dynamic> json) {
    return ReferralCodeResponse(
        message: json['message'] ?? '',
        status: json['status'] ?? false,
        data: ReferralCode.fromJson(json['data'] ?? {}));
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
        'data': data.toJson(),
      };
}
