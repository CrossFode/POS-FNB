class History {
  final String id;
  final String customerId;
  final String customer;
  final String customerPhone;
  final String orderType;
  final List<ProductItem> products;
  final int itemCount;
  final String cashier;
  final String paymentMethod;
  final DateTime orderDate;
  String status;
  final String outlet;
  final String? tableNumber;
  
  // Tambahkan properti untuk diskon dan harga
  final int subtotalPrice;  // total sebelum diskon
  final int totalPrice;     // total setelah diskon
  final String? discountName;
  final int? discountAmount;
  final String? discountType;
  final String? referralCode;
  final int? referralDiscount;

  History({
    required this.id,
    required this.customerId,
    required this.customer,
    required this.customerPhone,
    required this.orderType,
    required this.products,
    required this.itemCount,
    required this.cashier,
    required this.paymentMethod,
    required this.orderDate,
    required this.status,
    required this.outlet,
    this.tableNumber,
    required this.subtotalPrice,
    required this.totalPrice,
    this.discountName,
    this.discountAmount,
    this.discountType,
    this.referralCode,
    this.referralDiscount,
  });

  History copyWith({
    String? id,
    String? customer,
    String? customerPhone,
    String? orderType,
    List<ProductItem>? products,
    int? itemCount,
    String? cashier,
    String? paymentMethod,
    DateTime? orderDate,
    String? status,
    String? outlet,
    String? tableNumber,
    int? subtotalPrice,
    int? totalPrice,
    String? discountName,
    int? discountAmount,
    String? discountType,
    String? referralCode,
    int? referralDiscount,
  }) {
    return History(
      id: id ?? this.id,
      customerId:
          this.customerId, // customerId is not nullable in the constructor
      customer: customer ?? this.customer,
      customerPhone: customerPhone ?? this.customerPhone,
      orderType: orderType ?? this.orderType,
      products: products ?? this.products,
      itemCount: itemCount ?? this.itemCount,
      cashier: cashier ?? this.cashier,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      outlet: outlet ?? this.outlet,
      tableNumber: tableNumber ?? this.tableNumber,
      subtotalPrice: subtotalPrice ?? this.subtotalPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      discountName: discountName ?? this.discountName,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      referralCode: referralCode ?? this.referralCode,
      referralDiscount: referralDiscount ?? this.referralDiscount,
    );
  }

  factory History.fromJson(Map<String, dynamic> json) {
    final orderDetails = (json['order_details'] is List)
        ? json['order_details'] as List
        : <dynamic>[];
        
    return History(
      id: json['id']?.toString() ?? '',
      customerId: json['customer']?['id']?.toString() ?? '',
      customer: json['customer']?['name']?.toString() ?? '-',
      customerPhone: json['customer']?['phone']?.toString() ?? '-',
      orderType: json['order_type'] == 'dinein'
          ? 'Dine In'
          : (json['order_type'] == 'takeaway'
              ? 'Take Away'
              : (json['order_type']?.toString() ?? '-')),
      products: orderDetails
          .map((item) => ProductItem.fromJson(item))
          .toList()
          .cast<ProductItem>(),
      itemCount: orderDetails.length,
      cashier: json['cashier']?['name']?.toString() ?? '-',
      paymentMethod: json['payment']?['payment_name']?.toString().trim() ?? '-',
      orderDate: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: (json['status']?.toString() ?? '').toUpperCase(),
      outlet: json['outlet']?['outlet_name']?.toString() ?? '-',
      tableNumber: json['order_table']?.toString(),
      
      // Tambahkan informasi diskon dan subtotal
      subtotalPrice: json['order_subtotal'] != null 
          ? int.tryParse(json['order_subtotal'].toString()) ?? 0 
          : 0,
      totalPrice: json['order_total'] != null 
          ? int.tryParse(json['order_total'].toString()) ?? 0 
          : 0,
      discountName: json['discount']?['name']?.toString(),
      discountAmount: json['discount']?['amount'] != null
          ? int.tryParse(json['discount']['amount'].toString()) ?? 0
          : null,
      discountType: json['discount']?['type']?.toString(),
      referralCode: json['referral']?['code']?.toString(),
      referralDiscount: json['referral']?['discount'] != null
          ? int.tryParse(json['referral']['discount'].toString()) ?? 0
          : null,
    );
  }
}

class ProductItem {
  final String name;
  final int price;
  final int quantity;
  final String? variantName;

  ProductItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.variantName,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final variantName = json['variants']?['variant_name']?.toString();
    return ProductItem(
      name: product != null && product['name'] != null
          ? product['name'].toString()
          : '-',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      variantName: variantName,
    );
  }
}
