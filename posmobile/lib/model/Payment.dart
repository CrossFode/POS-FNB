class PaymentMethod {
  final int id;
  final String payment_name;
  final String payment_description;
  final DateTime created_at;
  final DateTime updated_at;

  PaymentMethod({
    required this.id,
    required this.payment_name,
    required this.payment_description,
    required this.created_at,
    required this.updated_at,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      payment_name: json['payment_name'],
      payment_description: json['payment_description'],
      created_at: DateTime.parse(json['created_at']),
      updated_at: DateTime.parse(json['updated_at']),
    );
  }
}

class PaymentMethodResponse {
  final String message;
  final String status;
  final List<PaymentMethod> data;

  PaymentMethodResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory PaymentMethodResponse.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResponse(
      message: json['message'],
      status: json['status'],
      data: (json['data'] as List)
          .map((item) => PaymentMethod.fromJson(item))
          .toList(),
    );
  }
}
