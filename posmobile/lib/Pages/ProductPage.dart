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
  
  // Track product status (true = in stock, false = sold out)
  Map<String, bool> productStatus = {};

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
        final data = ProductResponse.fromJson(jsonDecode(response.body));
        // Initialize all products as in stock by default
        for (var product in data.data) {
          productStatus[product.id.toString()] = true;
        }
        return data;
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
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: snapshot.data!.data.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data!.data[index];
                      final isInStock = productStatus[product.id.toString()] ?? true;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Centered icon
                              Center(
                                child: Icon(Icons.local_cafe, size: 40, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              // Centered product name
                              Center(
                                child: Text(
                                  product.name.toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Centered price
                              Center(
                                child: Text(
                                  product.variants.isNotEmpty
                                      ? 'Rp ${product.variants.first.price}'
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Spacer(),
                              // Bottom row with status button and menu
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center, // Center the children horizontally
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: isInStock ? Colors.green[100] : Colors.red[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        productStatus[product.id.toString()] = !isInStock;
                                      });
                                    },
                                    child: Text(
                                      isInStock ? 'In Stock' : 'Sold Out',
                                      style: TextStyle(
                                        color: isInStock ? Colors.green[800] : Colors.red[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the row's children
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 71, 71, 71), size: 22),
                                        tooltip: 'Edit',
                                        onPressed: () {
                                          // TODO: Implement edit logic here
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                        tooltip: 'Delete',
                                        onPressed: () {
                                          // TODO: Implement delete logic here
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Create Product')),
      content: SizedBox(
        width: 400, // Set your desired width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('General Information', style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),),
            ),
            Divider(
              color: Colors.grey,
              thickness: 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      )
    );
  },
  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
  child: const Icon(Icons.add, color: Colors.white),
  tooltip: 'Create Product',
),
    );
  }
}