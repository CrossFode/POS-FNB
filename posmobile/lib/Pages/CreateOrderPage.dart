import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:posmobile/Model/Model.dart';

class CreateOrderPage extends StatefulWidget {
  final String token;
  final String outletId;

  CreateOrderPage({Key? key, required this.token, required this.outletId})
      : super(key: key);

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  // final String baseUrl = 'https://pos.lakesidefnb.group';
  final String baseUrl = 'http://10.0.2.2:8000';

  final List<Map<String, dynamic>> _cartItems = [];

  late Future<ProductResponse> _productFuture;
  late Future<DiskonResponse> _diskonFuture;
  late Future<PaymentMethodResponse> _paymentFuture;
  Diskon? _selectedDiskon;

  @override
  void initState() {
    super.initState();
    _productFuture = fetchAllProduct(widget.token, widget.outletId);
    _diskonFuture = fetchDiskonByOutlet(widget.token, widget.outletId);
    _paymentFuture = fetchPaymentMethod(widget.token, widget.outletId);
  }

  Future<PaymentMethodResponse> fetchPaymentMethod(token, outletId) async {
    final url = Uri.parse('$baseUrl/api/payment');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return PaymentMethodResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load outlet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<ProductResponse> fetchAllProduct(token, outletId) async {
    final url = Uri.parse('$baseUrl/api/product/ext/outlet/${outletId}');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return ProductResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load outlet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<DiskonResponse> fetchDiskonByOutlet(token, outletId) async {
    final url = Uri.parse('$baseUrl/api/discount/outlet');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return DiskonResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load discount: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load discount: $e');
    }
  }

  Future<ReferralCodeResponse> fetchReferralCodes(
      String token, String code) async {
    final url = Uri.parse('$baseUrl/api/referralcode/verified');

    try {
      // Create a custom Request object for GET with body
      final request = http.Request('GET', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({'code': code});

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Sukses menggunakan referral');
        return ReferralCodeResponse.fromJson(jsonData);
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(
            errorResponse['message'] ?? 'Failed to verify referral code');
      }
    } catch (e) {
      print('Error verifying referral code: $e');
      throw Exception('Failed to verify referral code: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> makeOrder(
      {required String token, required Order order}) async {
    final url = Uri.parse('$baseUrl/api/order');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(order.toJson()),
      );

      print('Request data: ${jsonEncode(order.toJson())}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseBody,
          'message': responseBody['message'] ?? 'Order created successfully'
        };
      } else {
        final errorResponse = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorResponse['message'] ?? 'Failed to create order'
        };
      }
    } catch (e) {
      print('Error making order: $e');
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Dummy categories for demonstration
  List<String> categories = [
    'All',
    'Food',
    'Cofee',
    'Non coffee',
    'Milk',
    'Tea'
  ];
  String selectedCategory = 'All';

  // sampai sini

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: Text(
                  "Menu",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            // Kategori
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selectedCategory == cat,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<ProductResponse>(
                future: _productFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return const Center(child: Text('No products available'));
                  }
                  final filteredProducts = selectedCategory == 'All'
                      ? snapshot.data!.data
                      : snapshot.data!.data
                          .where((p) => p.category_name == selectedCategory)
                          .toList();
                  final allCategories = snapshot.data!.data
                      .map((p) => p.category_name)
                      .toSet()
                      .toList();
                  return GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8 // Adjust card aspect ratio
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return InkWell(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => HomePage(
                          //       token: widget.token,
                          //       outletId: outlet.id,
                          //     ),
                          //   ),
                          // );
                          // Handle outlet selection
                        },
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // product.image != null
                                  //     ? Image(
                                  //         width: 40,
                                  //         height: 40,
                                  //         image: NetworkImage(
                                  //             '${baseUrl}/${product.image}'),
                                  //       )
                                  //     :
                                  Icon(Icons.emoji_food_beverage, size: 40),
                                  SizedBox(height: 8),
                                  Text(
                                    product.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // Text(
                                  //   product.description,
                                  //   textAlign: TextAlign.center,
                                  //   style: TextStyle(
                                  //     fontSize: 10,
                                  //     fontWeight: FontWeight.normal,
                                  //   ),
                                  // ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showOrderOptions(context, product);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(40))),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8.0,
                                              left: 8,
                                              top: 15,
                                              bottom: 15),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          )),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCart,
              backgroundColor: Colors.black,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '${_cartItems.length} item(s)',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _showOrderOptions(BuildContext context, Product product) {
    int quantity = 1;
    List<Map<String, dynamic>> selectedModifiers = [];
    List<Map<String, dynamic>> selectedVariants = [];
    TextEditingController noteController = TextEditingController();
    void _handleModifierSelection({
      required bool selected,
      required Modifier modifier,
      required ModifierOptions option,
    }) {
      if (modifier.max_selected == 1) {
        // Single selection mode - replace any existing selection for this modifier
        selectedModifiers.removeWhere((m) => m['id'] == modifier.id);
        if (selected) {
          selectedModifiers.add({
            'id': modifier.id,
            'name': modifier.name,
            'modifier_options': {
              'id': option.id,
              'name': option.name,
              'price': option.price,
            },
          });
        }
      } else {
        // Multiple selection mode
        if (selected) {
          selectedModifiers.add({
            'id': modifier.id,
            'name': modifier.name,
            'modifier_options': {
              'id': option.id,
              'name': option.name,
              'price': option.price,
            }
          });
        } else {
          selectedModifiers.removeWhere((m) =>
              m['id'] == modifier.id &&
              m['modifier_options']['id'] == option.id);
        }
      }
    }

    void _handlerVariantsSelection({
      required bool selected,
      required int max_selected,
      required Variants variants,
    }) {
      // Single selection mode - replace any existing selection for this modifier
      if (max_selected == 1) {
        selectedVariants.removeWhere((v) => v['product_id'] == product.id);
        if (selected) {
          selectedVariants.add({
            'id': variants.id,
            'product_id': product.id,
            'name': variants.name,
            'price': variants.price
          });
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          int price = selectedVariants[0]['price'];
                          int totalPrice = _calculateTotalPriceWithModifiers(
                              price, selectedModifiers, quantity);
                          _cartItems.add({
                            'product_id': product.id,
                            'name': product.name,
                            'modifier': List.from(selectedModifiers),
                            'quantity': quantity,
                            'notes': noteController.text,
                            'variants': List<dynamic>.from(selectedVariants),
                            'variant_price': selectedVariants[0]
                                ['price'], // Tambahkan ini

                            'total_price': totalPrice
                          });
                        });
                        print(_cartItems);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const Divider(),

                // Modifier
                if (product.modifiers.isNotEmpty) ...[
                  ...product.modifiers.map(
                    (modifier) => Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${modifier.name}${modifier.is_required == 1 ? ' (Required) ' : ''}",
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (modifier.modifier_options.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: modifier.modifier_options.map((option) {
                                final isSelected = selectedModifiers.any((m) =>
                                    m['id'] == modifier.id &&
                                    m['modifier_options']['id'] == option.id);

                                return ChoiceChip(
                                  label: Text(
                                    "${option.name}${option.price! > 0 ? ' (+${option.price})' : ''}",
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      _handleModifierSelection(
                                        selected: selected,
                                        modifier: modifier,
                                        option: option,
                                      );
                                    });
                                  },
                                  selectedColor: Colors.black,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Text(
                            "No options available",
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    "No options available",
                    style: TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 8),
                // Variants
                if (product.variants.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Variants",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: product.variants.map((variants) {
                        final isSelected = selectedVariants.any((v) =>
                            v['id'] == variants.id &&
                            v['product_id'] == product.id);

                        return ChoiceChip(
                          label: Text(
                            "${variants.name}${variants.price > 0 ? ' ${variants.price}' : ''}",
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              _handlerVariantsSelection(
                                  selected: selected,
                                  variants: variants,
                                  max_selected: 1);
                            });
                          },
                          selectedColor: Colors.black,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.black),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ] else
                  Text(
                    "No options available",
                    style: TextStyle(color: Colors.grey),
                  ),

                const SizedBox(height: 16),

                // Quantity
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Quantity",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) setModalState(() => quantity--);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      onPressed: () => setModalState(() => quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Notes",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes here',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCart() {
    String _orderType = 'Take Away'; // Default order type
    final TextEditingController _customerNameController =
        TextEditingController();
    final TextEditingController _tableNumberController =
        TextEditingController();
    final TextEditingController _phoneNumberController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header and form section
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Order Type",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ["TakeAway", "DineIn"]
                              .map(
                                (type) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: OutlinedButton(
                                      onPressed: () => setModalState(
                                          () => _orderType = type),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _orderType == type
                                            ? Colors.black
                                            : Colors.white,
                                        foregroundColor: _orderType == type
                                            ? Colors.white
                                            : Colors.black,
                                        side: const BorderSide(
                                            color: Colors.black),
                                      ),
                                      child: Text(type),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: 16),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Costumer Name",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextField(
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "Enter Costumer name"),
                                  controller: _customerNameController,
                                )
                              ],
                            )),
                        SizedBox(height: 16),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Phone Number",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextField(
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "Enter Customer Phone Number"),
                                  controller: _phoneNumberController,
                                )
                              ],
                            )),
                        SizedBox(height: 12),
                        if (_orderType.toLowerCase() == 'dinein')
                          Align(
                              alignment: Alignment.topLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Table Number",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextField(
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: "Enter table number"),
                                    controller: _tableNumberController,
                                  )
                                ],
                              )),
                        const SizedBox(height: 4),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text("Order Details : ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    setState(() {
                                      _cartItems.clear();
                                    });
                                  },
                                  child: Text(
                                    "Clear All",
                                    style: TextStyle(color: Colors.red),
                                  ))
                            ]),
                      ],
                    );
                  },
                ),

                // Scrollable order details section
                Expanded(
                  child: SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return ListTile(
                          title: Text('${item['name']} x${item['quantity']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['variants'].isNotEmpty)
                                Text('Variants: ${item['variants'].map((m) {
                                  return '${m['name']} (Rp.${m['price']})';
                                }).join(', ')}'),
                              if (item['modifier'].isNotEmpty)
                                Text(
                                  'Modifier: ${item['modifier'].map((m) {
                                    final options = m['modifier_options'];
                                    return '${options['name']} (Rp.${options['price']})';
                                  }).join(', ')}',
                                ),
                              Text(
                                item['notes'].isNotEmpty
                                    ? item['notes']
                                    : 'No notes',
                              ),
                            ],
                          ),
                          trailing: Text(
                            'Rp ${item['total_price'].toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]}.',
                                )}',
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 16),
                // Checkout section (stays at bottom)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Rp ${NumberFormat("#,##0", "id_ID").format(_calculateOrderTotal(_cartItems))}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Debug 1: Print awal proses
                          print('Memulai proses order...');
                          print('Jumlah item di cart: ${_cartItems.length}');

                          final orderDetails =
                              _convertCartItemsToOrderDetails(_cartItems);
                          final orderTotal = _calculateOrderTotal(_cartItems);
                          final customer_name = _customerNameController.text;
                          final outlet_id = widget.outletId;
                          final phone_number = _phoneNumberController.text;
                          final order_totals = orderTotal.toString();
                          final order_table = _orderType.toLowerCase() !=
                                  'takeaway'
                              ? int.tryParse(_tableNumberController.text) ?? 0
                              : 1;
                          final order_type = _orderType.toLowerCase();
                          final order_details = orderDetails;
                          final order = Order(
                            outlet_id: outlet_id,
                            customer_name: customer_name,
                            phone_number: phone_number,
                            order_totals: order_totals,
                            order_table: order_table,
                            order_type: order_type,
                            order_details: order_details,
                            order_payment: 0,
                          );
                          _checkOut(order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "CONTINUE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  late Future<List<dynamic>> _cachedCheckoutData;

  void _checkOut(Order order) {
    String selectedValue = 'Option 1';
    TextEditingController referralCode = TextEditingController();
    String? refCode = null;
    PaymentMethod? _selectedPaymentMethod;

    // Tambahkan variabel untuk selected payment method
    _cachedCheckoutData = Future.wait([
      _diskonFuture,
      _paymentFuture,
    ]);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder(
              future: _cachedCheckoutData,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading data'));
                }

                final diskonList = snapshot.data?[0]?.data ?? [];
                final paymentMethods = snapshot.data?[1]?.data ?? [];

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: 270,
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          "Payment",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row untuk Dropdown dan TextField
                              Row(
                                children: [
                                  // Dropdown diskon
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<Diskon>(
                                      decoration: InputDecoration(
                                        labelText: 'Discount',
                                        hintText: 'No Discount',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                      ),
                                      value: _selectedDiskon,
                                      items: diskonList
                                          .map<DropdownMenuItem<Diskon>>(
                                              (diskon) {
                                        return DropdownMenuItem<Diskon>(
                                          value: diskon,
                                          child: Text('${diskon.name}',
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (Diskon? newValue) {
                                        setModalState(() {
                                          _selectedDiskon = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // TextField referral code
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: referralCode,
                                            decoration: InputDecoration(
                                              labelText: 'Referral Code',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.search),
                                            onPressed: () async {
                                              if (referralCode.text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Please enter a referral code'),
                                                  ),
                                                );
                                                return;
                                              }

                                              try {
                                                final response =
                                                    await fetchReferralCodes(
                                                        widget.token,
                                                        referralCode.text);
                                                if (response.status == 200) {
                                                  refCode = referralCode.text;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Referral code applied successfully!'),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 16),
                              // Dropdown payment method
                              DropdownButtonFormField<PaymentMethod>(
                                decoration: InputDecoration(
                                  labelText: 'Payment Method',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                                value: _selectedPaymentMethod,
                                hint: Text(
                                    'Select Payment Method'), // Placeholder jelas
                                items: paymentMethods
                                    .map<DropdownMenuItem<PaymentMethod>>(
                                        (method) {
                                  return DropdownMenuItem<PaymentMethod>(
                                    value: method,
                                    child: Text(
                                      method.payment_name,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (PaymentMethod? newValue) {
                                  setModalState(() {
                                    _selectedPaymentMethod = newValue;
                                  });
                                },
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_selectedPaymentMethod == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Please select a payment method'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        final int orderTotal = int.tryParse(
                                                order.order_totals
                                                    .toString()) ??
                                            0;
                                        final int diskon =
                                            _selectedDiskon?.amount ?? 0;
                                        final int finalTotal = (orderTotal -
                                            (orderTotal * diskon) ~/ 100);
                                        print(orderTotal);
                                        print(diskon);
                                        print(finalTotal);
                                        final result = await makeOrder(
                                          token: widget.token,
                                          order: Order(
                                            outlet_id: widget.outletId,
                                            customer_name: order.customer_name,
                                            phone_number: order.phone_number,
                                            order_totals: finalTotal.toString(),
                                            order_payment: _selectedPaymentMethod!
                                                .id, // Gunakan ID payment method yang dipilih
                                            order_table: order.order_table,
                                            discount_id: _selectedDiskon?.id,
                                            referral_code: refCode,
                                            order_type: order.order_type,
                                            order_details: order.order_details,
                                          ),
                                        );

                                        if (result['success'] == true) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result['message']),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          setState(() => _cartItems.clear());
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result['message']),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Error: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      fixedSize:
                                          Size.fromWidth(double.infinity),
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Confirm",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          });
        });
  }

  int _calculateTotalPriceWithModifiers(
      int basePrice, List<dynamic> modifiers, int quantity) {
    int modifierTotal = modifiers.fold(0, (sum, modifier) {
      return sum + (modifier['modifier_options']['price'] as num).toInt();
    });
    return (basePrice + modifierTotal) * quantity;
  }

  List<OrderDetails> _convertCartItemsToOrderDetails(List<dynamic> cartItems) {
    return cartItems.map((item) {
      return OrderDetails(
          notes: item['notes'] ?? '',
          product_id: item['product_id'] ?? item['product']['id'],
          qty: item['quantity'],
          variant_id:
              item['variants'].isNotEmpty ? item['variants'].first['id'] : 0,
          // price: item['variants'].first['price'], // Calculate unit price
          modifier_option_ids: (item['modifier'] as List)
              .map((mod) => mod['modifier_options']['id'] as int)
              .toList());
    }).toList();
  }

  int _calculateOrderTotal(List<dynamic> cartItems) {
    int total = 0;
    for (var item in cartItems) {
      total += (item['total_price'] as num).toInt();
    }
    return total;
  }
}
