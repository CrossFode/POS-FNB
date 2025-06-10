class Diskon {
  final int? id;
  final String name;
  final String type;
  final int amount;
  final DateTime? created_at;
  final DateTime? updated_at;

  Diskon(
      {this.id,
      required this.name,
      required this.type,
      required this.amount,
      this.created_at,
      this.updated_at});

  factory Diskon.fromJson(Map<String, dynamic> json) {
    return Diskon(
        id: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        amount: json['amount'] as int,
        created_at: DateTime.parse(json['created_at'] as String),
        updated_at: DateTime.parse(json['updated_at'] as String));
  }
}

class DiskonResponse {
  final String message;
  final bool status;
  final List<Diskon> data;

  DiskonResponse(
      {required this.message, required this.status, required this.data});

  factory DiskonResponse.fromJson(Map<String, dynamic> json) {
    return DiskonResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      data:
          (json['data'] as List).map((item) => Diskon.fromJson(item)).toList(),
    );
  }
}
