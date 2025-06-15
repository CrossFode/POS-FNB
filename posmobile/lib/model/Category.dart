// "id": 4,
//             "category_name": "FOOD",
//             "outlet_id": "OUT-FRPCTENMO7",
//             "is_food": 1,
//             "created_at": "2025-05-30T17:18:36.000000Z",
//             "updated_at": "2025-05-30T17:18:36.000000Z"

class Category {
  final int id;
  final String category_name;
  final String outlet_id;
  final int is_food;
  final DateTime? created_at;
  final DateTime? updated_at;

  Category(
      {required this.id,
      required this.category_name,
      required this.outlet_id,
      required this.is_food,
      this.created_at,
      this.updated_at});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        id: json['id'] as int,
        category_name: json['category_name'] as String,
        outlet_id: json['outlet_id'] as String,
        is_food: json['is_food'] as int,
        created_at: DateTime.parse(json['created_at'] as String),
        updated_at: DateTime.parse(json['updated_at'] as String));
  }
}

class CategoryResponse {
  final String message;
  final String status;
  final List<Category> data;

  CategoryResponse(
      {required this.message, required this.status, required this.data});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      data: (json['data'] as List)
          .map((item) => Category.fromJson(item))
          .toList(),
    );
  }
}
