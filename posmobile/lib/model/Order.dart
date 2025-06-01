import 'package:posmobile/Model/Modifier.dart';

class Order {
  final String outlet_id;
  final String customer_name;
  final String phone_number;
  final String order_totals;
  final int order_payment;
  final int? order_table;
  final String order_type;
  final int? discount_id;
  final String? referral_code;
  final List<OrderDetails> order_details;

  Order(
      {required this.outlet_id,
      required this.customer_name,
      required this.phone_number,
      required this.order_totals,
      required this.order_payment,
      this.order_table,
      required this.order_type,
      this.discount_id,
      this.referral_code,
      required this.order_details});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'outlet_id': outlet_id,
      'customer_name': customer_name,
      'phone_number': phone_number,
      'order_totals': order_totals,
      'order_payment': order_payment,
      'order_type': order_type,
      'order_details': order_details.map((detail) => detail.toJson()).toList(),
    };

    if (order_table != null) {
      data['order_table'] = order_table;
    }
    if (discount_id != null) {
      data['discount_id'] = discount_id;
    }
    if (referral_code != null) {
      data['referral_code'] = referral_code;
    }

    return data;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      outlet_id: json['outlet_id'] as String,
      customer_name: json['customer_name'] as String,
      phone_number: json['phone_number'] as String,
      order_totals: json['order_totals'] as String,
      order_payment: json['order_payment'] as int,
      order_table: json['order_table'] as int?,
      order_type: json['order_type'] as String,
      discount_id: json['discount_id'] as int?,
      referral_code: json['referral_code'] as String?,
      order_details: (json['order_details'] as List<dynamic>?)
              ?.map((orderJson) =>
                  OrderDetails.fromJson(orderJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderResponse {
  final String message;
  final String status;
  final List<Order> data;

  OrderResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
        message: json['message'] as String,
        status: json['status'] as String,
        data: (json['data'] as List)
            .map((i) => Order.fromJson(i as Map<String, dynamic>))
            .toList());
  }
}

class OrderDetails {
  final String notes;
  final int product_id;
  final int qty;
  final int variant_id;
  // final int price; // Added price field

  final List<int> modifier_option_ids;

  OrderDetails(
      {required this.notes,
      required this.product_id,
      required this.qty,
      required this.variant_id,
      // required this.price,
      required this.modifier_option_ids});

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'product_id': product_id,
        'qty': qty,
        // 'price': price,
        'variant_id': variant_id,
        'modifier_option_ids': modifier_option_ids
      };
  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      notes: json['notes'] as String,
      product_id: json['product_id'] as int,
      qty: json['qty'] as int,
      // price: json['price'] as int,
      variant_id: json['variant_id'] as int,
      modifier_option_ids: (json['modifier_option_ids'] as List<int>?)
              ?.map((id) => id)
              .toList() ??
          [],
    );
  }
  @override
  String toString() {
    return '''
    OrderDetails(
      notes: "$notes",
      product_id: $product_id,
      qty: $qty,
      variant_id: $variant_id,
      modifiers: $modifier_option_ids)''';
  }
}
