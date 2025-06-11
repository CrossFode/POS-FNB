// import 'package:posmobile/Model/Modifier.dart';

// class Product {
//   final int id;
//   final String name;
//   final int category_id;
//   final String description;
//   final String? image;
//   final int is_active;
//   final String outlet_id;
//   final DateTime created_at;
//   final DateTime updated_at;
//   final String category_name;
//   final List<Modifier> modifiers;
//   final List<Variants> variants;

//   Product(
//       {required this.id,
//       required this.name,
//       required this.category_id,
//       required this.description,
//       this.image,
//       required this.outlet_id,
//       required this.modifiers,
//       // required this.variants,
//       required this.created_at,
//       required this.updated_at,
//       required this.category_name,
//       required this.is_active,
//       required this.variants});


//   // KALO ERROR APUS INI
//       Map<String, dynamic> toJson() {
//         final data = <String, dynamic>{
//           'name': name,
//           'category_id': category_id,
//           'description': description,
//           'image': image,
//           'is_active': is_active,
//           'outlet_id': outlet_id,
//           'created_at': created_at.toIso8601String(),
//           'updated_at': updated_at.toIso8601String(),
//           'category_name': category_name,
//           'modifiers': modifiers.map((modifier) => modifier.toJson()).toList(),
//           'variants': variants.map((variant) => variant.toJson()).toList(),
//         };
//         // Add condition for creating product without variant, and with variant and modifier
//         if (variants.isEmpty && modifiers.isEmpty) {
//           // Product without variants and modifiers
//           data.remove('variants');
//           data.remove('modifiers');
//         } else if (variants.isNotEmpty && modifiers.isEmpty) {
//           // Product with variants only
//           data.remove('modifiers');
//         } else if (variants.isEmpty && modifiers.isNotEmpty) {
//           // Product with modifiers only
//           data.remove('variants');
//         }
//         return data;
//       }


//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product(
//       id: json['id'] as int,
//       name: json['name'] as String,
//       category_id: json['category_id'] as int,
//       description: json['description'] as String,
//       image: json['image'] as String?,
//       is_active: json['is_active'] as int,
//       outlet_id: json['outlet_id'] as String,
//       created_at: DateTime.parse(json['created_at'] as String),
//       updated_at: DateTime.parse(json['updated_at'] as String),
//       category_name: json['category_name'] as String,
//       modifiers: (json['modifiers'] as List<dynamic>?)
//               ?.map((modifierJson) =>
//                   Modifier.fromJson(modifierJson as Map<String, dynamic>))
//               .toList() ??
//           [],
//       variants: (json['variants'] as List<dynamic>?)
//               ?.map((variantsJson) =>
//                   Variants.fromJson(variantsJson as Map<String, dynamic>))
//               .toList() ??
//           [],
//     );
//   }

//   get status => null;
// }

// class Variants {
//   final int id;
//   final int product_id;
//   final String name;
//   final int price;

//   Variants({
//     required this.id,
//     required this.product_id,
//     required this.name,
//     required this.price,
//   });

//   factory Variants.fromJson(Map<String, dynamic> json) {
//     return Variants(
//         id: json['id'] as int,
//         product_id: json['product_id'] as int,
//         name: json['name'] as String,
//         price: json['price'] as int);
//   }

//   //KALO ERROR APUS INI

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'product_id': product_id,
//       'name': name,
//       'price': price,
//     };
//   }
// }

// class ProductResponse {
//   final String message;
//   final String status;
//   final List<Product> data;

//   ProductResponse({
//     required this.message,
//     required this.status,
//     required this.data,
//   });

//   factory ProductResponse.fromJson(Map<String, dynamic> json) {
//     return ProductResponse(
//       message: json['message'] as String,
//       status: json['status'] as String,
//       data: (json['data'] as List)
//           .map((i) => Product.fromJson(i as Map<String, dynamic>))
//           .toList(),
//     );
//   }
// }



import 'package:posmobile/Model/Modifier.dart';

class Product {
  final int id;
  final String name;
  final int category_id;
  final String description;
  final String? image;
  final int is_active;
  final String outlet_id;
  final DateTime created_at;
  final DateTime updated_at;
  final String category_name;
  final List<Modifier> modifiers;
  final List<Variants> variants;

  Product({
    required this.id,
    required this.name,
    required this.category_id,
    required this.description,
    this.image,
    required this.outlet_id,
    required this.modifiers,
    required this.variants,
    required this.created_at,
    required this.updated_at,
    required this.category_name,
    required this.is_active,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      category_id: json['category_id'] as int,
      description: json['description'] as String,
      image: json['image'] as String?,
      is_active: json['is_active'] as int,
      outlet_id: json['outlet_id'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      category_name: json['category_name'] as String,
      modifiers: (json['modifiers'] as List<dynamic>?)
          ?.map((m) => Modifier.fromJson(m))
          .toList() ?? [],
      variants: (json['variants'] as List<dynamic>?)
          ?.map((v) => Variants.fromJson(v))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'category_id': category_id,
      'description': description,
      'is_active': is_active,
      'outlet_id': outlet_id,
      'category_name': category_name,
    };

    if (image != null) data['image'] = image;
    if (variants.isNotEmpty) data['variants'] = variants.map((v) => v.toJson()).toList();
    if (modifiers.isNotEmpty) data['modifiers'] = modifiers.map((m) => m.id).toList();

    return data;
  }
}

class Variants {
  final int id;
  final int product_id;
  final String name;
  final int price;

  Variants({
    required this.id,
    required this.product_id,
    required this.name,
    required this.price,
  });

  factory Variants.fromJson(Map<String, dynamic> json) {
    return Variants(
      id: json['id'] as int,
      product_id: json['product_id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      if (id != 0) 'id': id,
      if (product_id != 0) 'product_id': product_id,
    };
  }
}

class ProductResponse {
  final String message;
  final String status;
  final List<Product> data;

  ProductResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      message: json['message'] as String,
      status: json['status'] as String,
      data: (json['data'] as List<dynamic>)
          .map((p) => Product.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'status': status,
      'data': data.map((p) => p.toJson()).toList(),
    };
  }
}