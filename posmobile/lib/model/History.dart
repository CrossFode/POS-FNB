class History {
  final String id;
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

  History({
    required this.id,
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
  }) {
    return History(
      id: id ?? this.id,
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
    );
  }

  int get totalPrice =>
      products.fold(0, (sum, item) => sum + (item.price * item.quantity));

  factory History.fromJson(Map<String, dynamic> json) {
    final orderDetails = (json['order_details'] is List)
        ? json['order_details'] as List
        : <dynamic>[];
    return History(
      id: json['id']?.toString() ?? '',
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
    );
  }
}

class ProductItem {
  final String name;
  final int price;
  final int quantity;

  ProductItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return ProductItem(
      name: product != null && product['name'] != null
          ? product['name'].toString()
          : '-',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}
