// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:posmobile/Model/Model.dart';
// import 'package:flutter/services.dart';
// import 'package:posmobile/Model/Modifier.dart';

// class ProductPage extends StatefulWidget {
//   final String token;
//   final String outletId;

//   ProductPage({Key? key, required this.token, required this.outletId})
//       : super(key: key);

//   @override
//   State<ProductPage> createState() => _ProductPageState();
// }

// class _ProductPageState extends State<ProductPage> {
//   final String baseUrl = 'http://10.0.2.2:8000';
//   final List<Map<String, dynamic>> _cartItems = [];
//   late Future<ProductResponse> _productFuture;
//   List<String> _categories = ['All']; // Default to 'All'

//   // Track product status (true = in stock, false = sold out)
//   Map<String, bool> productStatus = {};

//   // Controllers for product variants
//   List<Map<String, TextEditingController>> _variantControllers = [];

//   @override
//   void initState() {
//     super.initState();
//     _productFuture = fetchAllProduct(widget.token, widget.outletId);
//     _productFuture.then((productResponse) {
//       final categories = productResponse.data
//           .map((product) => product.category_name)
//           .toSet()
//           .toList();
//       setState(() {
//         _categories = ['All', ...categories];
//       });
//     });
//   }

//   Future<ProductResponse> fetchAllProduct(token, outletId) async {
//     final url = Uri.parse('$baseUrl/api/product/ext/outlet/${outletId}');
//     try {
//       final response = await http.get(url, headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       });
//       if (response.statusCode == 200) {
//         final data = ProductResponse.fromJson(jsonDecode(response.body));
//         // Initialize all products as in stock by default
//         for (var product in data.data) {
//           productStatus[product.id.toString()] = true;
//         }
//         return data;
//       } else {
//         throw Exception('Failed to load outlet: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load product: $e');
//     }
//   }

//   @override
//   void dispose() {
//     // Dispose all controllers to avoid memory leaks
//     for (var map in _variantControllers) {
//       map['name']?.dispose();
//       map['price']?.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.all(8),
//               child: Center(
//                 child: Text(
//                   "Menu",
//                   style: TextStyle(
//                     fontSize: 30,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: FutureBuilder<ProductResponse>(
//                 future: _productFuture,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
//                     return const Center(child: Text('No products available'));
//                   }
//                   return GridView.builder(
//                     padding: const EdgeInsets.all(16),
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                       childAspectRatio: 0.65,
//                     ),
//                     itemCount: snapshot.data!.data.length,
//                     itemBuilder: (context, index) {
//                       final product = snapshot.data!.data[index];
//                       final isInStock = productStatus[product.id.toString()] ?? true;

//                       return Card(
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(12),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               // Centered icon
//                               Center(
//                                 child: Icon(Icons.local_cafe, size: 40, color: Colors.black87),
//                               ),
//                               const SizedBox(height: 12),
//                               // Centered product name
//                               Center(
//                                 child: Text(
//                                   product.name.toString().toUpperCase(),
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                     letterSpacing: 0.5,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               // Centered price
//                               Center(
//                                 child: Text(
//                                   product.variants.isNotEmpty
//                                       ? 'Rp ${product.variants.first.price}'
//                                       : '-',
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                     color: Colors.black87,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                               const Spacer(),
//                               // Bottom row with status button and menu
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.center, // Center the children horizontally
//                                 children: [
//                                   TextButton(
//                                     style: TextButton.styleFrom(
//                                       backgroundColor: isInStock ? Colors.green[100] : Colors.red[100],
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                                     ),
//                                     onPressed: () {
//                                       setState(() {
//                                         productStatus[product.id.toString()] = !isInStock;
//                                       });
//                                     },
//                                     child: Text(
//                                       isInStock ? 'In Stock' : 'Sold Out',
//                                       style: TextStyle(
//                                         color: isInStock ? Colors.green[800] : Colors.red[800],
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.center, // Center the row's children
//                                     children: [
//                                       IconButton(
//                                         icon: const Icon(Icons.edit, color: Color.fromARGB(255, 71, 71, 71), size: 22),
//                                         tooltip: 'Edit',
//                                         onPressed: () {
//                                           // TODO: Implement edit logic here
//                                         },
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
//                                         tooltip: 'Delete',
//                                         onPressed: () {
//                                           // TODO: Implement delete logic here
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//     final _formKey = GlobalKey<FormState>();
//     String _productName = '';
//     String? _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
//     String _description = '';
//     int _price = 0;

//     showDialog(
//       context: context,
//       builder: (context) {
//         // These must be local to the dialog and updated via setState in StatefulBuilder
//         String? localSelectedCategory = _selectedCategory;
//         List<Map<String, TextEditingController>> localVariantControllers = [];
//         bool showSinglePrice = true;

//         return StatefulBuilder(
//           builder: (context, setStateDialog) => AlertDialog(
//             title: const Center(child: Text('Create Product')),
//             content: SizedBox(
//               width: 400,
//               child: SingleChildScrollView(
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'General Information',
//                           style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
//                         ),
//                       ),
//                       const Divider(
//                         color: Colors.grey,
//                         thickness: 1,
//                       ),
//                       const SizedBox(height: 10),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Product Name',
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) =>
//                             value == null || value.isEmpty ? 'Enter product name' : null,
//                         onSaved: (value) => _productName = value ?? '',
//                       ),
//                       const SizedBox(height: 16),
//                       DropdownButtonFormField<String>(
//                         decoration: const InputDecoration(
//                           labelText: 'Category',
//                           border: OutlineInputBorder(),
//                         ),
//                         value: localSelectedCategory,
//                         items: _categories
//                             .map((cat) => DropdownMenuItem(
//                                   value: cat,
//                                   child: Text(cat),
//                                 ))
//                             .toList(),
//                         onChanged: (value) => setStateDialog(() => localSelectedCategory = value),
//                         validator: (value) => value == null ? 'Select a category' : null,
//                       ),
//                       const SizedBox(height: 16),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Description',
//                           border: OutlineInputBorder(),
//                         ),
//                         maxLines: 2,
//                         validator: (value) =>
//                             value == null || value.isEmpty ? 'Enter description' : null,
//                         onSaved: (value) => _description = value ?? '',
//                       ),
//                       const SizedBox(height: 16),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Pricing',
//                           style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
//                         ),
//                       ),
//                       const Divider(
//                         color: Colors.grey,
//                         thickness: 1,
//                       ),
//                       const SizedBox(height: 10),
//                       if (showSinglePrice)
//                         TextFormField(
//                           keyboardType: TextInputType.number,
//                           decoration: const InputDecoration(
//                             labelText: 'Price',
//                             prefixText: 'Rp ',
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (value) =>
//                               value == null || value.isEmpty ? 'Enter price' : null,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           onSaved: (value) {
//                             _price = int.tryParse(value ?? '') ?? 0;
//                           },
//                         ),
//                       if (!showSinglePrice && localVariantControllers.isNotEmpty)
//                         Column(
//                           children: List.generate(localVariantControllers.length, (index) {
//                             final nameController = localVariantControllers[index]['name']!;
//                             final priceController = localVariantControllers[index]['price']!;
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 8.0),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     flex: 2,
//                                     child: TextFormField(
//                                       controller: nameController,
//                                       decoration: const InputDecoration(
//                                         labelText: 'Variant Name',
//                                         border: OutlineInputBorder(),
//                                       ),
//                                       validator: (value) =>
//                                           value == null || value.isEmpty ? 'Enter variant name' : null,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     flex: 2,
//                                     child: TextFormField(
//                                       controller: priceController,
//                                       keyboardType: TextInputType.number,
//                                       decoration: const InputDecoration(
//                                         labelText: 'Price',
//                                         prefixText: 'Rp ',
//                                         border: OutlineInputBorder(),
//                                       ),
//                                       inputFormatters: [
//                                         FilteringTextInputFormatter.digitsOnly,
//                                       ],
//                                       validator: (value) =>
//                                           value == null || value.isEmpty ? 'Enter price' : null,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   IconButton(
//                                     icon: const Icon(Icons.close, color: Colors.red),
//                                     onPressed: () {
//                                       setStateDialog(() {
//                                         localVariantControllers.removeAt(index);
//                                         if (localVariantControllers.isEmpty) {
//                                           showSinglePrice = true;
//                                         }
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }),
//                         ),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           onPressed: () {
//                             setStateDialog(() {
//                               if (showSinglePrice) {
//                                 showSinglePrice = false;
//                               }
//                               localVariantControllers.add({
//                                 'name': TextEditingController(),
//                                 'price': TextEditingController(),
//                               });
//                             });
//                           },
//                           child: const Text('ADD VARIANT'),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Modifiers',
//                           style: TextStyle(color: Color.fromARGB(255, 112, 112, 112)),
//                         ),
//                       ),
//                       const Divider(
//                         color: Colors.grey,
//                         thickness: 1,
//                       ),
                      
//                       // Fetch and display modifiers as checkboxes
//                       FutureBuilder<ModifierResponse>(
//                         future: fetchModifiers(widget.token, widget.outletId),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState == ConnectionState.waiting) {
//                             return const Padding(
//                               padding: EdgeInsets.symmetric(vertical: 8.0),
//                               child: Center(child: CircularProgressIndicator()),
//                             );
//                           } else if (snapshot.hasError) {
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 8.0),
//                               child: Text('Failed to load modifiers', style: TextStyle(color: Colors.red)),
//                             );
//                           } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
//                             return const Padding(
//                               padding: EdgeInsets.symmetric(vertical: 8.0),
//                               child: Text('No modifiers available'),
//                             );
//                           }
//                           // Local state for selected modifiers
//                           Map<int, bool> selectedModifiers = {}; // <-- Move this here
//                           for (var mod in snapshot.data!.data) {
//                             selectedModifiers.putIfAbsent(mod.id, () => false);
//                           }
//                           return StatefulBuilder(
//                             builder: (context, setStateDialog) {
//                               return Column(
//                                 children: snapshot.data!.data.map((modifier) {
//                                   return CheckboxListTile(
//                                     title: Text(modifier.name),
//                                     value: selectedModifiers[modifier.id] ?? false,
//                                     onChanged: (bool? value) {
//                                       setStateDialog(() {
//                                         selectedModifiers[modifier.id] = value ?? false;
//                                       });
//                                     },
//                                     controlAffinity: ListTileControlAffinity.leading,
//                                     dense: true,
//                                     contentPadding: EdgeInsets.zero,
//                                   );
//                                 }).toList(),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Close'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     _formKey.currentState?.save();
//                     final variants = !showSinglePrice
//                         ? localVariantControllers
//                             .map((map) => {
//                                   'name': map['name']!.text,
//                                   'price': int.tryParse(map['price']!.text) ?? 0,
//                                 })
//                             .toList()
//                         : [];
//                     print('Name: $_productName, Category: $localSelectedCategory, Description: $_description, Price: $_price, Variants: $variants');
//                     Navigator.of(context).pop();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Product Created!')),
//                     );
//                   }
//                 },
//                 child: const Text('Create'),
//               ),
//             ],
//           ),
//         );
//       },
//         );
//       },
//       backgroundColor: const Color.fromARGB(255, 0, 0, 0),
//       child: const Icon(Icons.add, color: Colors.white),
//       tooltip: 'Create Product',
//     ),
//     );
//   }

//   // Add this function in your _ProductPageState class
//   Future<ModifierResponse> fetchModifiers(String token, String outletId) async {
//     final url = Uri.parse('$baseUrl/api/modifier/ext/outlet/$outletId');
//     final response = await http.get(url, headers: {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     });
//     if (response.statusCode == 200) {
//       return ModifierResponse.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load modifiers');
//     }
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Model/Model.dart';
import 'package:flutter/services.dart';
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
  final String baseUrl = 'http://10.0.2.2:8000';
  // final List<Map<String, dynamic>> _cartItems = [];
  late Future<ProductResponse> _productFuture;
  List<String> _categories = ['All']; // Default to 'All'
  Map<String, bool> productStatus = {};

  @override
  void initState() {
    super.initState();
    _productFuture = fetchAllProduct(widget.token, widget.outletId);
    _productFuture.then((productResponse) {
      final categories = productResponse.data
          .map((product) => product.category_name)
          .toSet()
          .toList();
      setState(() {
        _categories = ['All', ...categories];
      });
    });
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

 Future<void> _createProduct({
  required String name,
  required String category_name,
  required String description,
  required int? price,
  required List<Map<String, dynamic>> variants,
  required List<int> modifier_ids,
}) async {
  final url = Uri.parse('$baseUrl/api/product');

  // Fetch all products to get category mapping (assuming categories are unique by name)
  final productResponse = await fetchAllProduct(widget.token, widget.outletId);
  // Find the first product with the selected category name to get its category_id
  final categoryProduct = productResponse.data.where((product) => product.category_name == category_name).isNotEmpty
      ? productResponse.data.firstWhere((product) => product.category_name == category_name)
      : null;
  final category_id = categoryProduct != null ? categoryProduct.category_id : null;

  if (category_id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to determine category ID.')),
    );
    return;
  }

  // Debug print the request payload
  final productData = {
    'name': name,
    'category_id': category_id,
    'description': description,
    'outlet_id': widget.outletId,
    'is_active': 1,
    if (variants.isEmpty && price != null) 'price': price,
    if (variants.isNotEmpty) 'variants': variants,
    if (modifier_ids.isNotEmpty) 'modifiers': modifier_ids,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  print('Attempting to create product with: ${jsonEncode(productData)}');

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(productData),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully!')),
      );
      setState(() {
        _productFuture = fetchAllProduct(widget.token, widget.outletId);
      });
    } else {
      final error = jsonDecode(response.body);
      final errorMsg = error['message'] ?? error['error'] ?? response.body;
      throw Exception('Server responded with: $errorMsg');
    }
  } catch (e) {
    print('Creation error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Creation failed: ${e.toString()}')),
    );
  }
}

  Future<ModifierResponse> fetchModifiers(String token, String outletId) async {
    final url = Uri.parse('$baseUrl/api/modifier/ext/outlet/$outletId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      return ModifierResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load modifiers');
    }
  }

  void _showCreateProductDialog() {
    final _formKey = GlobalKey<FormState>();
    String _productName = '';
    String? _selectedCategory = _categories.isNotEmpty ? _categories.firstWhere((c) => c != 'All', orElse: () => 'All') : null;
    String _description = '';
    String _price = '';
    final List<Map<String, TextEditingController>> _variantControllers = [];
    bool _showSinglePrice = true;
    final Map<int, bool> _selectedModifiers = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Center(child: Text('Create Product')),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // General Information
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'General Information',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Divider(color: Colors.grey, thickness: 1),
                        const SizedBox(height: 10),
                        
                        // Product Name
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Product Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          onSaved: (value) => _productName = value!,
                        ),
                        const SizedBox(height: 16),
                        
                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategory,
                          items: _categories.where((c) => c != 'All').map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) => setStateDialog(() => _selectedCategory = value),
                          validator: (value) => value == null ? 'Select a category' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          onSaved: (value) => _description = value ?? '',
                        ),
                        const SizedBox(height: 16),
                        
                        // Pricing Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pricing',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Divider(color: Colors.grey, thickness: 1),
                        const SizedBox(height: 10),
                        
                        // Single Price or Variants
                        if (_showSinglePrice)
                          TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onSaved: (value) => _price = value!,
                          ),
                        
                        if (!_showSinglePrice)
                          Column(
                            children: _variantControllers.map((controller) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: controller['name'],
                                        decoration: const InputDecoration(
                                          labelText: 'Variant Name',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: controller['price'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Price',
                                          prefixText: 'Rp ',
                                          border: OutlineInputBorder(),
                                        ),
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setStateDialog(() {
                                          _variantControllers.remove(controller);
                                          if (_variantControllers.isEmpty) {
                                            _showSinglePrice = true;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        
                        // Add Variant Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _variantControllers.add({
                                  'name': TextEditingController(),
                                  'price': TextEditingController(),
                                });
                                _showSinglePrice = false;
                              });
                            },
                            child: const Text('ADD VARIANT'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Modifiers Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Modifiers',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const Divider(color: Colors.grey, thickness: 1),
                        
                        // Modifiers List
                        FutureBuilder<ModifierResponse>(
                          future: fetchModifiers(widget.token, widget.outletId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                              return const Text('No modifiers available');
                            }
                            
                            if (_selectedModifiers.isEmpty) {
                              for (var mod in snapshot.data!.data) {
                                _selectedModifiers[mod.id] = false;
                              }
                            }
                            
                            return Column(
                              children: snapshot.data!.data.map((modifier) {
                                return CheckboxListTile(
                                  title: Text(modifier.name),
                                  value: _selectedModifiers[modifier.id] ?? false,
                                  onChanged: (bool? value) {
                                    setStateDialog(() {
                                      _selectedModifiers[modifier.id] = value ?? false;
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    
    final modifier_ids = _selectedModifiers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    
    final variants = _variantControllers.map((c) {
      return {
        'name': c['name']!.text,
        'price': int.parse(c['price']!.text),
      };
    }).toList();
    
    await _createProduct(
      name: _productName,
      category_name: _selectedCategory!,
      description: _description,
      price: _showSinglePrice ? int.tryParse(_price) : null,
      variants: variants,
      modifier_ids: modifier_ids,
    );
    
    Navigator.of(context).pop();
  }
},
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
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
                              Center(
                                child: Icon(Icons.local_cafe, size: 40, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 71, 71, 71), size: 22),
                                        onPressed: () {
                                          // TODO: Implement edit
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                        onPressed: () {
                                          // TODO: Implement delete
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
  onPressed: _showCreateProductDialog,
  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
  child: const Icon(Icons.add, color: Colors.white),
  tooltip: 'Create Product',
),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}