import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Model/Model.dart';
import 'package:posmobile/Model/Modifier.dart';

class ProductPage extends StatefulWidget {
  final String token;
  final String outletId;

  ProductPage({Key? key, required this.token, required this.outletId})
      : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final String baseUrl = 'https://pos.lakesidefnb.group';

  final List<Map<String, dynamic>> _cartItems = [];

  late Future<ProductResponse> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = fetchAllProduct(widget.token, widget.outletId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columns
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8 // Adjust card aspect ratio
                      ),
                  itemCount: snapshot.data!.data.length,
                  itemBuilder: (context, index) {
                    final product = snapshot.data!.data[index];
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

                // return ListView.builder(
                //     itemCount: snapshot.data!.data.length,
                //     itemBuilder: (context, index) {
                //       final product = snapshot.data!.data[index];
                //       return Container(
                //         margin: const EdgeInsets.only(bottom: 16),
                //         padding: const EdgeInsets.all(16),
                //         decoration: BoxDecoration(
                //           color: Colors.white,
                //           borderRadius: BorderRadius.circular(8),
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.black.withOpacity(0.1),
                //               blurRadius: 4,
                //               offset: const Offset(0, 2),
                //             ),
                //           ],
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Text(product.name,
                //                 style: const TextStyle(
                //                     fontSize: 15, fontWeight: FontWeight.bold)),
                //             const SizedBox(height: 8),
                //             Text(product.description,
                //                 style: const TextStyle(
                //                     fontSize: 11,
                //                     fontWeight: FontWeight.normal,
                //                     color: Colors.brown)),

                //             // SizedBox(
                //             //   width: 50,
                //             //   height: 47,
                //             //   child: ElevatedButton(
                //             //     onPressed: () {
                //             //       _showOrderOptions(context, name, price);
                //             //     },
                //             //     style: ElevatedButton.styleFrom(
                //             //       backgroundColor:
                //             //           const Color.fromARGB(255, 46, 44, 43),
                //             //       shape: RoundedRectangleBorder(
                //             //         borderRadius: BorderRadius.circular(20),
                //             //       ),
                //             //       padding: EdgeInsets.zero,
                //             //     ),
                //             //     child: const Icon(Icons.add,
                //             //         color: Colors.white, size: 24),
                //             //   ),
                //             // ),
                //           ],
                //         ),
                //       );
                //     });
              },
            ),
          ),
        ],
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
                          double price =
                              product.variants.first.price.toDouble();
                          double totalPrice = _calculateTotalPriceWithModifiers(
                              price, selectedModifiers, quantity);
                          _cartItems.add({
                            'product': product,
                            'name': product.name,
                            'modifier': List.from(selectedModifiers),
                            'quantity': quantity,
                            'notes': noteController.text,
                            'variants': List<dynamic>.from(selectedVariants)
                          });
                        });
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
                                    "${option.name}${option.price > 0 ? ' (+${option.price})' : ''}",
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  const Text(
                    "Order Type",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ["Take Away", "Dine In"]
                        .map(
                          (type) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: OutlinedButton(
                                onPressed: () =>
                                    setModalState(() => _orderType = type),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _orderType == type
                                      ? Colors.black
                                      : Colors.white,
                                  foregroundColor: _orderType == type
                                      ? Colors.white
                                      : Colors.black,
                                  side: const BorderSide(color: Colors.black),
                                ),
                                child: Text(type),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Input Nama Customer
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Customer Name",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter customer name',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cart items
                  SizedBox(
                    height: 200, // Fixed height to prevent overflow
                    child: ListView(
                      children: _cartItems.map((item) {
                        return ListTile(
                          title: Text('${item['name']} x${item['quantity']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['variants'].isNotEmpty)
                                Text(
                                  'Variant: ${item['variants'].map((v) => v['name']).join(', ')}',
                                ),
                              if (item['modifier'].isNotEmpty)
                                Text(
                                  'Modifier: ${item['modifier'].map((m) => m['modifier_options']['name']).join(', ')}',
                                ),
                              Text(
                                item['notes'].isNotEmpty
                                    ? item['notes']
                                    : 'No notes',
                              ),
                            ],
                          ),
                          trailing: Text(
                            'Rp ${(item['variants'].isNotEmpty ? item['variants'][0]['price'] : 0) * item['quantity']}',
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Checkout button
                  ElevatedButton(
                    onPressed: () {
                      print("Order Type: $_orderType");
                      print("Customer Name: ${_customerNameController.text}");
                      print("Items: $_cartItems");
                      // Tambahkan logika checkout sesuai kebutuhan
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "CHECKOUT",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _calculateTotalPriceWithModifiers(
      double basePrice, List<Map<String, dynamic>> modifiers, int quantity) {
    double modifierTotal = modifiers.fold(0, (sum, modifier) {
      return sum + (modifier['modifier_options']['price'] as num).toDouble();
    });
    return (basePrice + modifierTotal) * quantity;
  }
}
