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
                                    fontSize: 16,
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
          )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> selectedModifiers = [];
  void _showOrderOptions(BuildContext context, Product product) {
    int quantity = 1;

    TextEditingController noteController = TextEditingController();

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
                          // _cartItems.add({
                          //   'name': pfr,
                          //   'price': price,
                          //   'modifier': selectedModifier,
                          //   'quantity': quantity,
                          //   'notes': noteController.text,
                          // });
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
                ],

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
          }
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
            m['id'] == modifier.id && m['modifier_options']['id'] == option.id);
      }
    }
  }
}
