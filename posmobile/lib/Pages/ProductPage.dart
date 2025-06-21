import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Model/Model.dart';
import 'package:flutter/services.dart';
import 'package:posmobile/Model/Modifier.dart';
import 'package:posmobile/Model/Category.dart';
import 'package:posmobile/Components/Navbar.dart';



import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Pages/CategoryPage.dart';
import 'package:posmobile/Pages/CreateOrderPage.dart';
import 'package:posmobile/Pages/HistoryPage.dart';
import 'package:posmobile/Pages/ModifierPage.dart';

// Fungsi format harga agar seperti "20.0K" dan "5.5K" tanpa "Rp" dan underline
String formatPrice(int price) {
  if (price >= 1000) {
    double value = price / 1000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
  }
  return price.toString();
}

class ProductPage extends StatefulWidget {
  final String token;
  final String outletId;

  ProductPage({Key? key, required this.token, required this.outletId})
      : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

  class _ProductPageState extends State<ProductPage> {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    // final List<Map<String, dynamic>> _cartItems = [];
    late Future<ProductResponse> _productFuture;
    List<String> _categories = ['All']; // Default to 'All'
    Map<String, bool> productStatus = {};
    // Tambahkan Map untuk menyimpan status aktif produk di dalam State class
    Map<int, bool> _productActiveStatus = {};

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
          for (var product in productResponse.data) {
            _productActiveStatus[product.id] = product.is_active == 1;
          }
        });
      });
    }

  Future<CategoryResponse> fetchCategories(
      String token, String outletId) async {
    final url =
        Uri.parse('$baseUrl/api/category'); // Ganti sesuai endpoint yang benar
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    print('Category API status: ${response.statusCode}');
    print('Category API body: ${response.body}');
    if (response.statusCode == 200) {
      return CategoryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load categories');
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
    required String category_name,
    required String name,
    required String description,
    required String price,
    required List<Map<String, dynamic>> variants,
    required List<int> modifier_ids,
  }) async {
    final url = Uri.parse('$baseUrl/api/product');

    // Fetch categories instead of products
    final categoryResponse =
        await fetchCategories(widget.token, widget.outletId);

    // Debug print untuk melihat data kategori
    print(
        'Available categories: ${categoryResponse.data.map((c) => '${c.id}:${c.category_name}').toList()}');
    print('Selected category: $category_name');

    // Find category_id from categories data
    final categoryList = categoryResponse.data
        .where(
          (cat) =>
              cat.category_name.trim().toLowerCase() ==
              category_name.trim().toLowerCase(),
        )
        .toList();
    final categoryData = categoryList.isNotEmpty ? categoryList.first : null;

    final category_id = categoryData?.id;

    if (category_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to determine category ID.')),
      );
      return;
    }

    // Create product data
    final productData = {
      'name': name,
      'category_id': category_id, // Use category_id from categories
      'description': description,
      'price': int.tryParse(price),
      'is_active': 1,
      'outlet_id': widget.outletId,
      if (variants.isNotEmpty) 'variants': variants,
      if (modifier_ids.isNotEmpty) 'modifiers': modifier_ids,
    };

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

  void _showCreateProductDialog(
      {BuildContext? context, Product? product, bool isEdit = false}) {
    final _formKey = GlobalKey<FormState>();
    String _productName = '';
    String? _selectedCategory = _categories.isNotEmpty
        ? _categories.firstWhere((c) => c != 'All', orElse: () => 'All')
        : null;
    String _description = '';
    String _price = '';
    final List<Map<String, TextEditingController>> _variantControllers = [];
    bool _showSinglePrice = true;
    final Map<int, bool> _selectedModifiers = {};

    // Jika product != null dan isEdit == true, isi field form dengan data produk
    // Jika product == null, form kosong (mode tambah)
    if (product != null && isEdit) {
      _productName = product.name;
      _description = product.description;
      _selectedCategory = product.category_name;
      _showSinglePrice = product.variants.isEmpty;
      if (product.variants.isNotEmpty) {
        _variantControllers.addAll(product.variants.map((variant) {
          return {
            'name': TextEditingController(text: variant.name),
            'price': TextEditingController(text: variant.price.toString()),
          };
        }));
      }
      // Set modifier status
      for (var mod in product.modifiers) {
        _selectedModifiers[mod.id] = true;
      }
    }

    showDialog(
      context: context!,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Center(
                child: Text(
                  isEdit ? 'Edit Product' : 'Create Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
                            'GENERAL INFORMATION',
                            style: TextStyle(
                                color: Color.fromARGB(255, 66, 66, 66),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
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
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                          onSaved: (value) => _productName = value!,
                          initialValue: isEdit ? product?.name : null,
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        FutureBuilder<CategoryResponse>(
                          future:
                              fetchCategories(widget.token, widget.outletId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.data.isEmpty) {
                              return const Text('No categories available');
                            }
                            final categories = snapshot.data!.data;
                            final categoryNames =
                                categories.map((c) => c.category_name).toList();
                            // Ensure _selectedCategory is either null or in the list
                            final dropdownValue =
                                (categoryNames.contains(_selectedCategory))
                                    ? _selectedCategory
                                    : null;
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              value: dropdownValue,
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category.category_name,
                                  child: Text(category.category_name),
                                );
                              }).toList(),
                              onChanged: (value) => setStateDialog(
                                  () => _selectedCategory = value),
                              validator: (value) =>
                                  value == null ? 'Select a category' : null,
                            );
                          },
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
                          initialValue: isEdit ? product?.description : null,
                        ),
                        const SizedBox(height: 16),

                        // Pricing Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PRICING',
                            style: TextStyle(
                                color: Color.fromARGB(255, 66, 66, 66),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
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
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onSaved: (value) => _price = value!,
                            initialValue: isEdit &&
                                    (product?.variants.isNotEmpty ?? false)
                                ? product!.variants.first.price.toString()
                                : null,
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
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Required'
                                                : null,
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
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        validator: (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () {
                                        setStateDialog(() {
                                          _variantControllers
                                              .remove(controller);
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
                              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
                            'MODIFIERS',
                            style: TextStyle(
                                color: Color.fromARGB(255, 68, 68, 68),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(color: Colors.grey, thickness: 1),

                        // Modifiers List
                        FutureBuilder<ModifierResponse>(
                          future: fetchModifiers(widget.token, widget.outletId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.data.isEmpty) {
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
                                  title: Text(
                                    modifier.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  value:
                                      _selectedModifiers[modifier.id] ?? false,
                                  onChanged: (bool? value) {
                                    setStateDialog(() {
                                      _selectedModifiers[modifier.id] =
                                          value ?? false;
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  dense: true,
                                  contentPadding:
                                      EdgeInsets.zero, // Remove all padding
                                  visualDensity: VisualDensity(
                                      horizontal: -4,
                                      vertical: -4), // Make it more compact
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
                  style: TextButton.styleFrom(
                    // backgroundColor: const Color.fromARGB(255, 255, 255, 255), // warna hitam
                    foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                  ),
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

                      if (isEdit) {
                        // Update product
                        try {
                          final url =
                              Uri.parse('$baseUrl/api/product/${product!.id}');

                          // Ambil category_id dari data kategori, bukan dari produk
                          final categoryResponse = await fetchCategories(
                              widget.token, widget.outletId);
                          final categoryData = categoryResponse.data.firstWhere(
                            (cat) =>
                                cat.category_name.trim().toLowerCase() ==
                                _selectedCategory!.trim().toLowerCase(),
                            orElse: () => categoryResponse.data.first,
                          );

                          // Gunakan id dari kategori yang dipilih
                          final category_id = categoryData?.id;

                          if (category_id == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Failed to determine category ID')),
                            );
                            return;
                          }

                          final response = await http.put(
                            url,
                            headers: {
                              'Authorization': 'Bearer ${widget.token}',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'name': _productName,
                              'category_id':
                                  category_id, // Gunakan category_id dari kategori yang dipilih
                              'description': _description,
                              'price': _showSinglePrice
                                  ? int.tryParse(_price)
                                  : null,
                              'is_active': 1,
                              'outlet_id': product.outlet_id,
                              if (variants.isNotEmpty) 'variants': variants,
                              if (modifier_ids.isNotEmpty)
                                'modifiers': modifier_ids,
                              'updated_at': DateTime.now().toIso8601String(),
                            }),
                          );

                          print(
                              'Update response status: ${response.statusCode}');
                          print('Update response body: ${response.body}');

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Product updated successfully!')),
                            );
                            setState(() {
                              _productFuture = fetchAllProduct(
                                  widget.token, widget.outletId);
                            });
                          } else {
                            final error = jsonDecode(response.body);
                            final errorMsg = error['message'] ??
                                error['error'] ??
                                response.body;
                            throw Exception('Server responded with: $errorMsg');
                          }
                        } catch (e) {
                          print('Update error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Update failed: ${e.toString()}')),
                          );
                        }
                      } else {
                        // Create new product
                        await _createProduct(
                          name: _productName,
                          category_name: _selectedCategory!,
                          description: _description,
                          price: _showSinglePrice ? _price : '',
                          variants: variants,
                          modifier_ids: modifier_ids,
                        );
                      }

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
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
    int _currentIndex = 0; // Assuming Create Order is at index 2

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
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: snapshot.data!.data.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data!.data[index];
                      return Card(
                        shadowColor: const Color.fromARGB(255, 136, 155, 205),
                        color: const Color.fromARGB(255, 255, 255, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Product info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      product.variants.isNotEmpty
                                          ? formatPrice(
                                              product.variants.first.price)
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF6B7A8F),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Right: Actions
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 28),
                                        onPressed: () {
                                          _showCreateProductDialog(
                                            context: context,
                                            product:
                                                product, // kirim data produk yang akan diedit
                                            isEdit:
                                                true, // tambahkan parameter untuk mode edit
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 28, color: Colors.red),
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text('Delete Product'),
                                              content: const Text(
                                                  'Apakah anda yakin ingin menghapus produk ini?'),
                                              actions: [
                                                TextButton(style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(255, 0, 0, 0),),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            try {
                                              final url = Uri.parse(
                                                  '$baseUrl/api/product/${product.id}');
                                              final response =
                                                  await http.delete(
                                                url,
                                                headers: {
                                                  'Authorization':
                                                      'Bearer ${widget.token}',
                                                  'Content-Type':
                                                      'application/json',
                                                },
                                              );
                                              if (response.statusCode == 200 ||
                                                  response.statusCode == 204) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Product deleted successfully!')),
                                                );
                                                setState(() {
                                                  _productFuture =
                                                      fetchAllProduct(
                                                          widget.token,
                                                          widget.outletId);
                                                });
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Failed to delete product: ${response.body}')),
                                                );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text('Error: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Switch(
  value: _productActiveStatus[product.id] ?? false, // Fallback to false if null
  onChanged: (value) async {
    setState(() {
      _productActiveStatus[product.id] = value; // Update state
    });
    try {
      await updateProductStatus(
        token: widget.token,
        product: product,
        isActive: value,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );
    } catch (e) {
      setState(() {
        _productActiveStatus[product.id] = !value; // Revert on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  },
  activeColor: Colors.blueGrey,
  inactiveThumbColor: Colors.red,
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
          _showCreateProductDialog(context: context, isEdit: false);
        },
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Product',
      ),
      bottomNavigationBar: Navbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Handle navigation here
          if (index != _currentIndex) {
            // Example navigation logic - adjust as needed
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HistoryPage(
                        token: widget.token, outletId: widget.outletId)),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateOrderPage(
                        token: widget.token, outletId: widget.outletId)),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => CategoryPage()
                        ),
              );
            } else if (index == 4) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ModifierPage(
                        token: widget.token, outletId: widget.outletId)),
              );
            }
            // And so on for other indices
          }
        },
      ),
    );
  }

  Future<void> updateProductStatus({
    required String token,
    required Product product,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/api/product/${product.id}');
    final body = {
      'name': product.name,
      'category_id': product.category_id,
      'description': product.description,
      'price': product.variants.isNotEmpty ? product.variants.first.price : 0,
      'is_active': isActive ? 1 : 0,
      'outlet_id': product.outlet_id,
      // tambahkan field lain jika diperlukan oleh API
    };
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to update product status');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
