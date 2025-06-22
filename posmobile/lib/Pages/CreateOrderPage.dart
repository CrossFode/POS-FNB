import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Model/Model.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Api/CreateOrder.dart';

class CreateOrderPage extends StatefulWidget {
  final String token;
  final String outletId;
  final int navIndex;
  final Function(int)? onNavItemTap;
  final bool isManager;

  CreateOrderPage(
      {Key? key,
      required this.token,
      required this.outletId,
      this.navIndex = 1,
      this.onNavItemTap,
      required this.isManager})
      : super(key: key);

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
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

class _CreateOrderPageState extends State<CreateOrderPage> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final List<Map<String, dynamic>> _cartItems = [];
  late Future<ProductResponse> _productFuture;
  late Future<DiskonResponse> _diskonFuture;
  late Future<PaymentMethodResponse> _paymentFuture;
  late Future<CategoryResponse> _categoryFuture;
  late Future<OutletResponseById> _outletFuture;
  TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  Diskon? _selectedDiskon;
  final Diskon noDiscountOption = Diskon(
    id: null,
    name: 'No Discount',
    amount: 0,
    type: '',
  );

  @override
  void initState() {
    super.initState();
    _productFuture = fetchAllProduct(widget.token, widget.outletId);
    _diskonFuture = fetchDiskonByOutlet(widget.token, widget.outletId);
    _paymentFuture = fetchPaymentMethod(widget.token, widget.outletId);
    _categoryFuture = fetchCategoryinOutlet(widget.token, widget.outletId);
    _outletFuture = fetchOutletById(widget.token, widget.outletId);
    _selectedDiskon = noDiscountOption;
    _filteredProducts = []; // Initialize empty
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _filterProducts() async {
    final query = _searchController.text.toLowerCase();

    try {
      final productResponse = await _productFuture;
      setState(() {
        _filteredProducts = productResponse.data.where((product) {
          return query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              (product.description.toLowerCase().contains(query));
        }).toList();
      });
    } catch (e) {
      print('Error filtering products: $e');
      setState(() {
        _filteredProducts = [];
      });
    }
  }

  List<String> categories = ['All'];
  String selectedCategory = 'All';

  String formatPriceToK(num price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return price.toString();
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
              Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts();
                        },
                      ),
                      // ... rest of your decoration
                    ),
                    onChanged: (value) => _filterProducts(),
                  )),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FutureBuilder<CategoryResponse>(
                  future: _categoryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final categoryNames = ['All'] +
                          snapshot.data!.data
                              .map((category) => category.category_name)
                              .toList();

                      return Row(
                        children: categoryNames.map((category) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    return const CircularProgressIndicator();
                  },
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
                    } else if (!snapshot.hasData ||
                        snapshot.data!.data.isEmpty) {
                      return const Center(child: Text('No products available'));
                    }
                    List<Product> productsToDisplay = _searchController
                            .text.isNotEmpty
                        ? _filteredProducts
                        : selectedCategory == 'All'
                            ? snapshot.data!.data
                            : snapshot.data!.data
                                .where(
                                    (p) => p.category_name == selectedCategory)
                                .toList();
                    final filteredProducts = selectedCategory == 'All'
                        ? snapshot.data!.data
                        : snapshot.data!.data
                            .where((p) => p.category_name == selectedCategory)
                            .toList();

                    if (filteredProducts.isEmpty) {
                      return Center(child: Text('No items found'));
                    }
                    return ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: productsToDisplay.length,
                      itemBuilder: (context, index) {
                        productsToDisplay.sort((a, b) => a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase()));
                        final product = productsToDisplay[index];
                        final price = product.variants[0].price;
                        return InkWell(
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        formatPriceToK(price),
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
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
        bottomNavigationBar: _buildNavbar());
  }

  Widget _buildNavbar() {
    return FlexibleNavbar(
      currentIndex: widget.navIndex,
      isManager: widget.isManager,
      onTap: (index) {
        if (index != widget.navIndex) {
          if (widget.onNavItemTap != null) {
            widget.onNavItemTap!(index);
          } else {
            _handleNavigation(index);
          }
        }
      },
      onMorePressed: () {
        _showMoreOptions(context);
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuOption(
                icon: Icons.settings,
                label: 'Modifier',
                onTap: () => _navigateTo(ModifierPage(
                  token: widget.token,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.card_giftcard,
                label: 'Referral Code',
                onTap: () => _navigateTo(ModifierPage(
                  token: widget.token,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.discount,
                label: 'Discount',
                onTap: () => _navigateTo(DiscountPage(
                  token: widget.token,
                  userRoleId: 2,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.history,
                label: 'History',
                onTap: () => _navigateTo(HistoryPage(
                  token: widget.token,
                  outletId: widget.outletId,
                )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _handleNavigation(int index) {
    if (widget.isManager == true) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId,
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
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModifierPage(
                token: widget.token,
                outletId: widget.outletId,
                isManager: widget.isManager),
          ),
        );
      }
    } else {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId,
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
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
            ),
          ),
        );
      } else if (index == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModifierPage(
                token: widget.token,
                outletId: widget.outletId,
                isManager: widget.isManager),
          ),
        );
      }
    }
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

    bool _areVariantsEqual(List<dynamic> variants1, List<dynamic> variants2) {
      if (variants1.length != variants2.length) return false;

      for (int i = 0; i < variants1.length; i++) {
        if (variants1[i]['id'] != variants2[i]['id']) {
          return false;
        }
      }
      return true;
    }

    bool _areModifiersEqual(
        List<dynamic> modifiers1, List<dynamic> modifiers2) {
      if (modifiers1.length != modifiers2.length) return false;

      final sorted1 = List.from(modifiers1)
        ..sort((a, b) => a['id'].compareTo(b['id']));
      final sorted2 = List.from(modifiers2)
        ..sort((a, b) => a['id'].compareTo(b['id']));

      for (int i = 0; i < sorted1.length; i++) {
        if (sorted1[i]['id'] != sorted2[i]['id'] ||
            sorted1[i]['modifier_options']['id'] !=
                sorted2[i]['modifier_options']['id']) {
          return false;
        }
      }
      return true;
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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

                          int price = selectedVariants[0]['price'];
                          int totalPrice = _calculateTotalPriceWithModifiers(
                              price, selectedModifiers, quantity);

                          Map<String, dynamic> newItem = {
                            'product_id': product.id,
                            'name': product.name,
                            'modifier': List.from(selectedModifiers),
                            'quantity': quantity,
                            'notes': noteController.text,
                            'variants': List<dynamic>.from(selectedVariants),
                            'variant_price': selectedVariants[0]['price'],
                            'total_price': totalPrice
                          };

                          setState(() {
                            bool itemExists = false;

                            for (int i = 0; i < _cartItems.length; i++) {
                              var item = _cartItems[i];

                              if (item['product_id'] == newItem['product_id'] &&
                                  _areVariantsEqual(
                                      item['variants'], newItem['variants']) &&
                                  _areModifiersEqual(
                                      item['modifier'], newItem['modifier']) &&
                                  item['notes'] == newItem['notes']) {
                                _cartItems[i]['quantity'] +=
                                    newItem['quantity'];
                                _cartItems[i]['total_price'] +=
                                    newItem['total_price'];
                                itemExists = true;
                                break;
                              }
                            }

                            if (!itemExists) {
                              _cartItems.add(newItem);
                            }
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
                                children:
                                    modifier.modifier_options.map((option) {
                                  final isSelected = selectedModifiers.any(
                                      (m) =>
                                          m['id'] == modifier.id &&
                                          m['modifier_options']['id'] ==
                                              option.id);

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
            ),
          );
        });
      },
    );
  }

  void _showCart() {
    String _orderType = 'Take Away';
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
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
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

                          final order_details = orderDetails;
                          final order = Order(
                            outlet_id: outlet_id,
                            customer_name: customer_name,
                            phone_number: phone_number,
                            order_totals: order_totals,
                            order_table: order_table,
                            order_type: 'takeaway',
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
    TextEditingController referralCode = TextEditingController();
    String? refCode = null;
    PaymentMethod? _selectedPaymentMethod;
    int _finalTotalWithDiscount = 0;
    int _referralDiscount = 0;
    int? _besarDiskon = 0;

    _cachedCheckoutData =
        Future.wait([_diskonFuture, _paymentFuture, _outletFuture]);
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
                List<Diskon> diskonListWithNoOption =
                    [noDiscountOption] + diskonList;
                final paymentMethods = snapshot.data?[1]?.data ?? [];

                final orderTotal =
                    int.tryParse(order.order_totals.toString()) ?? 0;
                final diskon = _selectedDiskon == noDiscountOption
                    ? 0
                    : (_selectedDiskon?.amount ?? 0);
                _finalTotalWithDiscount =
                    (orderTotal - (orderTotal * diskon) ~/ 100) -
                        _referralDiscount;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          "Payment",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<Diskon>(
                                decoration: InputDecoration(
                                  labelText: 'Discount',
                                  labelStyle: TextStyle(fontSize: 8),
                                  hintText: 'No Discount',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 14),
                                ),
                                value: _selectedDiskon ?? noDiscountOption,
                                items: diskonListWithNoOption
                                    .map<DropdownMenuItem<Diskon>>((diskon) {
                                  return DropdownMenuItem<Diskon>(
                                    value: diskon,
                                    child: Text(
                                      '${diskon.name}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14),
                                    ),
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
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: referralCode,
                                      decoration: InputDecoration(
                                        labelText: 'Referral Code',
                                        labelStyle: TextStyle(fontSize: 14),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
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
                                          if (response.status == true) {
                                            refCode = referralCode.text;

                                            setModalState(() {
                                              _referralDiscount =
                                                  (_finalTotalWithDiscount *
                                                          response
                                                              .data.discount) ~/
                                                      100;
                                              _besarDiskon = response
                                                  .data.discount
                                                  .toInt();
                                              _finalTotalWithDiscount -=
                                                  _referralDiscount;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Referral code applied successfully!'),
                                                backgroundColor: Colors.green,
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
                        DropdownButtonFormField<PaymentMethod>(
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          value: _selectedPaymentMethod,
                          hint: Text('Select Payment Method'),
                          items: paymentMethods
                              .map<DropdownMenuItem<PaymentMethod>>((method) {
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
                                  "Rp ${NumberFormat("#,##0", "id_ID").format(_finalTotalWithDiscount)}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                final outletResponse = await _outletFuture;
                                final outletName =
                                    outletResponse.data.outlet_name;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Previewbill(
                                            outletName: outletName,
                                            orderId:
                                                'ORDER-${DateTime.now().millisecondsSinceEpoch}',
                                            customerName: order.customer_name,
                                            orderType: order.order_type,
                                            tableNumber: order.order_table ?? 0,
                                            items: _cartItems,
                                            subtotal: int.tryParse(
                                                    order.order_totals) ??
                                                0,
                                            discountVoucher:
                                                (_selectedDiskon?.amount ?? 0),
                                            discountRef: (_besarDiskon ?? 0),
                                            total: _finalTotalWithDiscount,
                                            paymentMethod:
                                                _selectedPaymentMethod
                                                        ?.payment_name ??
                                                    'N/A',
                                            orderTime: DateTime.now(),
                                          )),
                                );
                                try {
                                  final result = await makeOrder(
                                    token: widget.token,
                                    order: Order(
                                      outlet_id: widget.outletId,
                                      customer_name: order.customer_name,
                                      phone_number: order.phone_number,
                                      order_payment: _selectedPaymentMethod!.id,
                                      order_table: order.order_table,
                                      discount_id: _selectedDiskon?.id,
                                      referral_code: refCode,
                                      order_totals:
                                          _finalTotalWithDiscount.toString(),
                                      order_type: order.order_type,
                                      order_details: order.order_details,
                                    ),
                                  );
                                  if (mounted)
                                    return setState(() {
                                      _cartItems.clear();
                                    });
                                  ;
                                  if (result['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message']),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    setState(() => _cartItems.clear());
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to process order: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Process Order",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
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
