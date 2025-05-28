// TODO Implement this library.
class Modifier {
  final int id;
  final String name;
  final int is_required;
  final int min_selected;
  final int max_selected;
  final String outlet_id;
  final DateTime created_at;
  final DateTime updated_at;
  final List<ModifierOptions> modifier_options;

  Modifier(
      {required this.id,
      required this.name,
      required this.is_required,
      required this.min_selected,
      required this.max_selected,
      required this.outlet_id,
      required this.created_at,
      required this.updated_at,
      required this.modifier_options});

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
        id: json['id'] as int,
        name: json['name'] as String,
        is_required: json['is_required'] as int,
        min_selected: json['min_selected'] as int,
        max_selected: json['max_selected'] as int,
        outlet_id: json['outlet_id'] as String,
        created_at: DateTime.parse(json['created_at'] as String),
        updated_at: DateTime.parse(json['updated_at'] as String),
        modifier_options: (json['modifier_options'] as List<dynamic>?)
                ?.map((modifierJson) => ModifierOptions.fromJson(
                    modifierJson as Map<String, dynamic>))
                .toList() ??
            []);
  }
}

class ModifierResponse {
  final String message;
  final String status;
  final List<Modifier> data;

  ModifierResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory ModifierResponse.fromJson(Map<String, dynamic> json) {
    return ModifierResponse(
      message: json['message'] as String,
      status: json['status'] as String,
      data: (json['data'] as List)
          .map((i) => Modifier.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ModifierOptions {
  final int id;
  final int modifier_id;
  final String name;
  final int price;
  final DateTime created_at;
  final DateTime updated_at;

  ModifierOptions({
    required this.id,
    required this.modifier_id,
    required this.name,
    required this.price,
    required this.created_at,
    required this.updated_at,
  });

  factory ModifierOptions.fromJson(Map<String, dynamic> json) {
    return ModifierOptions(
        id: json['id'] as int,
        modifier_id: json['modifier_id'] as int,
        name: json['name'] as String,
        price: json['price'] as int,
        created_at: DateTime.parse(json['created_at'] as String),
        updated_at: DateTime.parse(json['updated_at'] as String));
  }
}
