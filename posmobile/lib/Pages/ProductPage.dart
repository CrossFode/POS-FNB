import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Auth/login.dart';
import 'package:posmobile/Model/Model.dart';
import 'package:flutter/services.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Api/CreateOrder.dart';

import 'package:posmobile/Pages/Dashboard/Home.dart';

import 'package:posmobile/Pages/Pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final int navIndex;
  final Function(int)? onNavItemTap;
  final bool isManager;

  const ProductPage({
    Key? key,
    required this.token,
    required this.outletId,
    this.navIndex = 2,
    this.onNavItemTap,
    required this.isManager,
  }) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  late Future<ProductResponse> _productFuture;
  List<String> _categories = ['All'];
  Map<String, bool> productStatus = {};
  Map<int, bool> _productActiveStatus = {};
  bool _isLoading = true;
  String _outletName = '';

  @override
  void initState() {
    super.initState();
    _productFuture = fetchAllProduct(widget.token, widget.outletId);
    _loadProducts();
    _loadOutletName();
  }

  Future<void> _loadOutletName() async {
    try {
      final outletResponse = await fetchOutletById(widget.token, widget.outletId);
      setState(() {
        _outletName = outletResponse.data.outlet_name;
      });
    } catch (e) {
      debugPrint('Error fetching outlet name: $e');
      // Don't show error to user, just keep empty outlet name
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final productResponse =
          await fetchAllProduct(widget.token, widget.outletId);

      final categories = productResponse.data
          .map((product) => product.category_name)
          .toSet()
          .toList();

      final statusMap = <int, bool>{};
      for (var product in productResponse.data) {
        statusMap[product.id] = product.is_active == 1;
        productStatus[product.id.toString()] = true;
      }

      setState(() {
        _categories = ['All', ...categories];
        _productActiveStatus = statusMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }

  Future<ProductResponse> fetchAllProduct(String token, String outletId) async {
    final url = Uri.parse('$baseUrl/api/product/ext/outlet/$outletId');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return ProductResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
    }
  }

  // Removed duplicate build method to resolve 'The name 'build' is already defined.' error.

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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Center(
                          child: Text(
                            isEdit ? 'Edit Product' : 'Create Product',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Product Name
                        const Text(
                          "PRODUCT NAME",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Product Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (value != value.toUpperCase()) {
                              return 'Use Capital Letters Only';
                            }
                            return null;
                          },
                          onSaved: (value) => _productName = value!,
                          initialValue: isEdit ? product?.name : null,
                        ),
                        const SizedBox(height: 18),

                        // Category Dropdown
                        const Text(
                          "CATEGORY",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                            final dropdownValue =
                                (categoryNames.contains(_selectedCategory))
                                    ? _selectedCategory
                                    : null;
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                hintText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: dropdownValue,
                              dropdownColor: Colors.white,
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
                        const SizedBox(height: 18),

                        // Description
                        const Text(
                          "DESCRIPTION",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 2,
                          onSaved: (value) => _description = value ?? '',
                          initialValue: isEdit ? product?.description : null,
                        ),
                        const SizedBox(height: 18),

                        // Pricing Section
                        const Text(
                          "PRICING",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Single Price or Variants
                        if (_showSinglePrice)
                          TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Price',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.white,
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
                                        decoration: InputDecoration(
                                          hintText: 'Variant Name',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                          filled: true,
                                          fillColor: Colors.white,
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
                                        decoration: InputDecoration(
                                          hintText: 'Price',
                                          prefixText: 'Rp ',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                          filled: true,
                                          fillColor: Colors.white,
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

                        // Tambahkan jarak sebelum tombol
                        const SizedBox(
                            height: 10), // <--- Tambahkan ini sebelum tombol
                        // Add Variant Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 53, 150, 105),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize:
                                  const Size(0, 44), // tinggi 44, lebar penuh
                              elevation: 0,
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
                            child: const Text(
                              'ADD VARIANT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Modifiers Section
                        const Text(
                          "MODIFIERS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),

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
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  activeColor:
                                      const Color.fromARGB(255, 53, 150, 105),
                                  checkColor: Colors.white,
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 53, 150, 105),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 53, 150, 105),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();

                                    final modifier_ids = _selectedModifiers
                                        .entries
                                        .where((e) => e.value)
                                        .map((e) => e.key)
                                        .toList();

                                    final variants =
                                        _variantControllers.map((c) {
                                      return {
                                        'name': c['name']!.text,
                                        'price': int.parse(c['price']!.text),
                                      };
                                    }).toList();

                                    if (isEdit) {
                                      // Update product
                                      try {
                                        final url = Uri.parse(
                                            '$baseUrl/api/product/${product!.id}');
                                        final categoryResponse =
                                            await fetchCategories(
                                                widget.token, widget.outletId);
                                        final categoryData =
                                            categoryResponse.data.firstWhere(
                                          (cat) =>
                                              cat.category_name
                                                  .trim()
                                                  .toLowerCase() ==
                                              _selectedCategory!
                                                  .trim()
                                                  .toLowerCase(),
                                          orElse: () =>
                                              categoryResponse.data.first,
                                        );
                                        final category_id = categoryData.id;

                                        final response = await http.put(
                                          url,
                                          headers: {
                                            'Authorization':
                                                'Bearer ${widget.token}',
                                            'Content-Type': 'application/json',
                                          },
                                          body: jsonEncode({
                                            'name': _productName,
                                            'category_id': category_id,
                                            'description': _description,
                                            'price': _showSinglePrice
                                                ? int.tryParse(_price)
                                                : null,
                                            'is_active': 1,
                                            'outlet_id': product.outlet_id,
                                            if (variants.isNotEmpty)
                                              'variants': variants,
                                            if (modifier_ids.isNotEmpty)
                                              'modifiers': modifier_ids,
                                            'updated_at': DateTime.now()
                                                .toIso8601String(),
                                          }),
                                        );

                                        if (response.statusCode == 200) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Product updated successfully!')),
                                          );
                                          setState(() {
                                            _productFuture = fetchAllProduct(
                                                widget.token, widget.outletId);
                                          });
                                        } else {
                                          final error =
                                              jsonDecode(response.body);
                                          final errorMsg = error['message'] ??
                                              error['error'] ??
                                              response.body;
                                          throw Exception(
                                              'Server responded with: $errorMsg');
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Update failed: ${e.toString()}')),
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
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 30), // geser ke kanan 16px
            child: Row(
              children: [
                Text(
                  "PRODUCT",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                if (_outletName.isNotEmpty) ...[
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      "$_outletName",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
          elevation: 0,
          centerTitle: false,
          foregroundColor: Colors.black,
          shape: const Border(
            bottom: BorderSide(
              color: Color.fromARGB(255, 102, 105, 108), // Outline color
              width: 0.5, // Outline thickness
            ),
          ),
        ),

        //APP BACKGROUND COLOR
        backgroundColor: const Color.fromARGB(255, 245, 244, 244),
        body: SafeArea(
          child: Stack(
            children: [
              // Background image - paling bawah dalam Stack
             

              // Konten asli tetap di sini
              Column(
                children: [
                  Expanded(
                    child: FutureBuilder<ProductResponse>(
                      future: _productFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.data.isEmpty) {
                          return const Center(
                              child: Text('No products available'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: snapshot.data!.data.length,
                          itemBuilder: (context, index) {
                            final product = snapshot.data!.data[index];
                            return Card(
                              shadowColor: const Color.fromARGB(255, 0, 0, 0),
                              color: const Color.fromARGB(255, 255, 254, 254),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                //                     side: const BorderSide(
                                // color: Color.fromARGB(255, 0, 0, 0), // Outline color
                                // width: 1.5,)
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            product.variants.isNotEmpty
                                                ? formatPrice(product
                                                    .variants.first.price)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 28),
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
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            255, 255, 255, 255),
                                                    title: const Center(
                                                      // <-- Add Center here
                                                      child: Text(
                                                        'Delete Product',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20),
                                                      ),
                                                    ),
                                                    content: const Text(
                                                      'Apakah anda yakin ingin menghapus produk ini?',
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    actions: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextButton(
                                                              style: TextButton
                                                                  .styleFrom(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            16),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                  side: BorderSide(
                                                                      color: Colors
                                                                              .grey[
                                                                          300]!),
                                                                ),
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          false),
                                                              child: const Text(
                                                                'Cancel',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          145,
                                                                          145,
                                                                          145),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Expanded(
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          true),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            16),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Delete',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
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
                                                    if (response.statusCode ==
                                                            200 ||
                                                        response.statusCode ==
                                                            204) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Product deleted successfully!')),
                                                      );
                                                      setState(() {
                                                        _productFuture =
                                                            fetchAllProduct(
                                                                widget.token,
                                                                widget
                                                                    .outletId);
                                                      });
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Failed to delete product: ${response.body}')),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Error: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        Switch(
                                          value: _productActiveStatus[
                                                  product.id] ??
                                              false, // Fallback to false if null
                                          onChanged: (value) async {
                                            setState(() {
                                              _productActiveStatus[product.id] =
                                                  value; // Update state
                                            });
                                            try {
                                              await updateProductStatus(
                                                token: widget.token,
                                                product: product,
                                                isActive: value,
                                              );
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Status updated successfully!')),
                                              );
                                            } catch (e) {
                                              setState(() {
                                                _productActiveStatus[
                                                        product.id] =
                                                    !value; // Revert on error
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Failed to update status')),
                                              );
                                            }
                                          },
                                          activeColor: const Color.fromARGB(
                                              255, 53, 150, 105),
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
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showCreateProductDialog(context: context, isEdit: false);
          },
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Create Product',
        ),
        bottomNavigationBar: _buildNavbar());
  }

  Widget _buildNavbar() {
    return FlexibleNavbar(
      currentIndex: widget.navIndex,
      isManager: widget.isManager,
      onTap: (index) {
        if (widget.outletId == null && index != 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select an outlet first')),
          );
          return;
        }
        if (index != widget.navIndex) {
          _handleNavigation(index);
        }
      },
      onMorePressed: () {
        _showMoreOptions(context);
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Menu untuk semua user (baik manager maupun staff)
              _buildMenuOption(
                icon: Icons.settings,
                color: Colors.grey,
                label: 'Modifier',
                onTap: () {
                  if (widget.outletId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an outlet first')),
                    );
                    return;
                  }
                  _navigateTo(ModifierPage(
                    token: widget.token,
                    outletId: widget.outletId!,
                    isManager: widget.isManager,
                  ));
                },
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.category,
                color: Colors.grey,
                label: 'Category',
                onTap: () {
                  if (widget.outletId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select an outlet first')),
                    );
                    return;
                  }
                  _navigateTo(CategoryPage(
                    token: widget.token,
                    outletId: widget.outletId!,
                    isManager: widget.isManager,
                  ));
                },
              ),
              Divider(),

              // Menu tambahan khusus untuk manager
              if (widget.isManager) ...[
                _buildMenuOption(
                  icon: Icons.card_giftcard,
                  color: Colors.grey,
                  label: 'Referral Code',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(ReferralCodePage(
                      token: widget.token,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                    ));
                  },
                ),
                Divider(),
                _buildMenuOption(
                  icon: Icons.discount,
                  color: Colors.grey,
                  label: 'Discount',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(DiscountPage(
                      token: widget.token,
                      userRoleId: 2,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                      isOpened: true,
                    ));
                  },
                ),
                Divider(),
                _buildMenuOption(
                  icon: Icons.history,
                  color: Colors.grey,
                  label: 'History',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(HistoryPage(
                      token: widget.token,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                    ));
                  },
                ),
                Divider(),
                _buildMenuOption(
                  icon: Icons.payment,
                  color: Colors.grey,
                  label: 'Payment',
                  onTap: () {
                    if (widget.outletId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select an outlet first')),
                      );
                      return;
                    }
                    _navigateTo(Payment(
                      token: widget.token,
                      outletId: widget.outletId!,
                      isManager: widget.isManager,
                    ));
                  },
                ),
                Divider(),
              ],

              // Menu logout untuk semua user
              _buildMenuOption(
                icon: Icons.logout,
                color: Colors.red,
                label: 'Logout',
                onTap: () async {
                  SharedPreferences pref =
                      await SharedPreferences.getInstance();
                  pref.remove('token');
                  pref.remove('role');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required MaterialColor color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> _handleNavigation(int index) async {
    if (widget.isManager == true) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(
              token: widget.token,
              outletId: null,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        _showMoreOptions(context);
      }
    } else {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(
              token: widget.token,
              outletId: null,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId!,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        _showMoreOptions(context);
      }
    }
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

  Future<CategoryResponse> fetchCategories(
      String token, String outletId) async {
    final url = Uri.parse('$baseUrl/api/category/outlet/$outletId');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return CategoryResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<ModifierResponse> fetchModifiers(String token, String outletId) async {
    final url = Uri.parse(
        '$baseUrl/api/modifier/ext/outlet/$outletId'); // <-- perbaiki di sini
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        return ModifierResponse.fromJson(jsonDecode(response.body));
        print(response.body);
      } else {
        throw Exception('Failed to load modifiers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching modifiers: $e');
      rethrow;
    }
  }

  Future<void> _createProduct({
    required String name,
    required String category_name,
    required String description,
    required String price,
    required List<Map<String, dynamic>> variants,
    required List<int> modifier_ids,
  }) async {
    try {
      // Fetch category_id from category_name
      final categoryResponse =
          await fetchCategories(widget.token, widget.outletId);
      final categoryData = categoryResponse.data.firstWhere(
        (cat) =>
            cat.category_name.trim().toLowerCase() ==
            category_name.trim().toLowerCase(),
        orElse: () => categoryResponse.data.first,
      );
      final category_id = categoryData.id;

      final url = Uri.parse('$baseUrl/api/product');
      final body = {
        'name': name,
        'category_id': category_id,
        'description': description,
        'price': variants.isEmpty ? int.tryParse(price) : null,
        'is_active': 1,
        'outlet_id': widget.outletId,
        if (variants.isNotEmpty) 'variants': variants,
        if (modifier_ids.isNotEmpty) 'modifiers': modifier_ids,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
