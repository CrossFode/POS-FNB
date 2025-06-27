class Diskon {
  final int? id;
  final String name;
  final String type;
  final double amount;
  final DateTime? created_at;

  final List<String> outletIds;

  Diskon({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.created_at,
    this.outletIds = const [], // Default empty list
  });

  factory Diskon.fromJson(Map<String, dynamic> json) {
    List<String> outletIds = [];

    // Parse outlet IDs jika ada
    if (json['outlets'] != null) {
      outletIds = (json['outlets'] as List)
          .map((outlet) => outlet['id'].toString())
          .toList();
    }

    return Diskon(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      amount: double.parse(json['amount'].toString()),
      created_at: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      outletIds: outletIds,
    );
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
