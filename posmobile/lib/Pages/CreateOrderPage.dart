import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Auth/login.dart';
import 'package:posmobile/Model/Model.dart';
import 'package:posmobile/Pages/Dashboard/Home.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Api/CreateOrder.dart';
import 'package:posmobile/Pages/PaymentPage.dart';
import 'package:posmobile/Pages/ReferralPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _formKey = GlobalKey<FormState>();
  String _outletName = '';

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
    _loadOutletName();
  }

  Future<void> _loadOutletName() async {
    try {
      final outletResponse =
          await fetchOutletById(widget.token, widget.outletId);
      setState(() {
        _outletName = outletResponse.data.outlet_name;
      });
    } catch (e) {
      debugPrint('Error fetching outlet name: $e');
      // Don't show error to user, just keep empty outlet name
    }
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
          final matchesName =
              query.isEmpty || product.name.toLowerCase().contains(query);
          final matchesCategory = selectedCategory == 'All' ||
              product.category_name == selectedCategory;
          return matchesName && matchesCategory;
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
      double value = price / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }
    return price.toString();
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
                  "MENU",
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
        backgroundColor: const Color.fromARGB(255, 245, 244, 244),
        body: SafeArea(
          child: Stack(
            children: [
              // Background image - paling bawah dalam Stack

              // Konten asli - tetap sama seperti sebelumnya, hanya dimasukkan ke dalam Stack
              Column(
                children: [
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
                      ),
                      onChanged: (value) => _filterProducts(),
                    ),
                  ),
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
                              final isSelected = selectedCategory == category;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color.fromARGB(255, 53, 150,
                                              105), // Selected: white, Unselected: black
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor:
                                      const Color.fromARGB(255, 53, 150, 105),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                    _filterProducts();
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
                        List<Product> productsToDisplay =
                            _searchController.text.isNotEmpty
                                ? _filteredProducts
                                : (selectedCategory == 'All'
                                    ? snapshot.data!.data
                                    : snapshot.data!.data
                                        .where((p) =>
                                            p.category_name == selectedCategory)
                                        .toList());
                        final filteredProducts = selectedCategory == 'All'
                            ? snapshot.data!.data
                            : snapshot.data!.data
                                .where(
                                    (p) => p.category_name == selectedCategory)
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
                                color: Colors.white,
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            softWrap: true,
                                            maxLines: 2, // Maksimal 2 baris
                                            overflow:
                                                TextOverflow.ellipsis, // A
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                formatPriceToK(price),
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              if (product.is_active == 0) ...[
                                                Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius
                                                          .all(Radius.circular(
                                                              8))), // ini yang benar
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Text(
                                                      "Sold out",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize:
                                                            10, // opsional agar teks kelihatan
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      product.is_active == 1
                                          ? ElevatedButton(
                                              onPressed: () {
                                                _showOrderOptions(
                                                    context, product);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 53, 150, 105),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(40)),
                                                ),
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
                                                ),
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 49, 49, 49),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(40)),
                                                ),
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
                                                ),
                                              ),
                                            )
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
            ],
          ),
        ),
        floatingActionButton: _cartItems.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _showCart,
                backgroundColor: const Color.fromARGB(
                    255, 53, 150, 105), // Change color here
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

  void _showOrderOptions(BuildContext context, Product product) {
    int quantity = 1;
    bool variantError = false; // Tambahkan di StatefulBuilder
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
      backgroundColor: const Color.fromARGB(255, 255, 254, 254),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 16,
                right: 16,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tombol Save & Cancel di bawah judul
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 53, 150, 105),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                int? price;
                                Navigator.pop(context);
                                if (selectedVariants.isEmpty) {
                                  setModalState(() {
                                    variantError = true;
                                    // Snakbar untuk menunjukkan error
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Please select a variant for ${product.name}'),
                                      backgroundColor: Colors.red,
                                    ));
                                  });
                                  return;
                                } else {
                                  setModalState(() {
                                    variantError = false;
                                    price = selectedVariants[0]['price'];
                                  });
                                }

                                int totalPrice =
                                    _calculateTotalPriceWithModifiers(
                                        price!, selectedModifiers, quantity);

                                Map<String, dynamic> newItem = {
                                  'product_id': product.id,
                                  'name': product.name,
                                  'modifier': List.from(selectedModifiers),
                                  'quantity': quantity,
                                  'notes': noteController.text,
                                  'variants':
                                      List<dynamic>.from(selectedVariants),
                                  'variant_price': selectedVariants[0]['price'],
                                  'total_price': totalPrice
                                };

                                setState(() {
                                  bool itemExists = false;

                                  for (int i = 0; i < _cartItems.length; i++) {
                                    var item = _cartItems[i];

                                    if (item['product_id'] ==
                                            newItem['product_id'] &&
                                        _areVariantsEqual(item['variants'],
                                            newItem['variants']) &&
                                        _areModifiersEqual(item['modifier'],
                                            newItem['modifier']) &&
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
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 53, 150, 105),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Save",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Content: Modifiers, Variants, Quantity, Notes, dst
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
                                    crossAxisAlignment:
                                        WrapCrossAlignment.start,
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
                                        backgroundColor: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        selectedColor:
                                            Color.fromARGB(255, 53, 150, 105),
                                        checkmarkColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                              color: const Color.fromARGB(
                                                  255, 187, 187, 187)),
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
                                    variantError = false;
                                  });
                                },
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 255, 255),
                                selectedColor:
                                    Color.fromARGB(255, 53, 150, 105),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: const Color.fromARGB(
                                          255, 187, 187, 187)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (variantError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                            child: Text(
                              'Pilih salah satu varian!',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
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
                          Text('$quantity',
                              style: const TextStyle(fontSize: 18)),
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
              ));
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
    final _localFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 255, 254, 254),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 16,
              right: 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Form(
                  key: _localFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Center(
                          child: Text(
                            'Create Order',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Customer Name
                        const Text(
                          "CUSTOMER NAME",
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: "Enter Customer Name",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          controller: _customerNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the customer name first';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Phone Number
                        const Text(
                          "PHONE NUMBER",
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: "Enter Customer Phone Number",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          controller: _phoneNumberController,
                        ),
                        const SizedBox(height: 18),

                        // Order Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "ORDER DETAILS",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _cartItems.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "All of your items has been removed from cart"),
                                  ),
                                );
                              },
                              child: const Text(
                                "Clear All",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 53, 150, 105),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Cart Items
                        if (_cartItems.isEmpty)
                          const Text(
                            "No items in cart.",
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item['name']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final itemName = item['name'];
                                            setState(() {
                                              _cartItems.removeAt(index);
                                              Navigator.pop(context);
                                              _showCart();
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '$itemName removed from cart'),
                                                duration:
                                                    const Duration(seconds: 2),
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  onPressed: () {
                                                    setState(() {
                                                      _cartItems.insert(
                                                          index, item);
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                            if (_cartItems.isEmpty) {
                                              Navigator.pop(context);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    if (item['variants'].isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Variants: ${item['variants'].map((m) => '${m['name']} (Rp.${m['price']})').join(', ')}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    if (item['modifier'].isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Modifier: ${item['modifier'].map((m) {
                                            final options =
                                                m['modifier_options'];
                                            return '${options['name']} (Rp.${options['price']})';
                                          }).join(', ')}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    if (item['notes'].isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Notes: ${item['notes']}',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove,
                                                    size: 18),
                                                onPressed: () {
                                                  if (item['quantity'] > 1) {
                                                    setState(() {
                                                      _cartItems[index]
                                                          ['quantity']--;
                                                      _cartItems[index]
                                                              ['total_price'] =
                                                          _calculateTotalPriceWithModifiers(
                                                              item[
                                                                  'variant_price'],
                                                              item['modifier'],
                                                              item['quantity']);
                                                      Navigator.pop(context);
                                                      _showCart();
                                                    });
                                                  }
                                                },
                                              ),
                                              Text('${item['quantity']}'),
                                              IconButton(
                                                icon: const Icon(Icons.add,
                                                    size: 18),
                                                onPressed: () {
                                                  setState(() {
                                                    _cartItems[index]
                                                        ['quantity']++;
                                                    _cartItems[index]
                                                            ['total_price'] =
                                                        _calculateTotalPriceWithModifiers(
                                                            item[
                                                                'variant_price'],
                                                            item['modifier'],
                                                            item['quantity']);
                                                    Navigator.pop(context);
                                                    _showCart();
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Rp ${item['total_price'].toString().replaceAllMapped(
                                                RegExp(
                                                    r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                                (Match m) => '${m[1]}.',
                                              )}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),

                        // Total & Continue Button
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
                                if (_localFormKey.currentState!.validate()) {
                                  final orderDetails =
                                      _convertCartItemsToOrderDetails(
                                          _cartItems);
                                  final orderTotal =
                                      _calculateOrderTotal(_cartItems);
                                  final customer_name =
                                      _customerNameController.text;
                                  final outlet_id = widget.outletId;
                                  final phone_number =
                                      _phoneNumberController.text;
                                  final order_totals = orderTotal.toString();
                                  final order_table = _orderType
                                              .toLowerCase() !=
                                          'takeaway'
                                      ? int.tryParse(
                                              _tableNumberController.text) ??
                                          0
                                      : 1;

                                  final order = Order(
                                    outlet_id: outlet_id,
                                    customer_name: customer_name,
                                    phone_number: phone_number,
                                    order_totals: order_totals,
                                    order_table: order_table,
                                    order_type: 'takeaway',
                                    order_details: orderDetails,
                                    order_payment: 0,
                                  );
                                  _checkOut(order);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 53, 150, 105),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
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
    // List<String> payment = ['Cash', 'QRIS', 'Transfer'];
    // String _selectedPaymentMethod;
    // _selectedPaymentMethod
    PaymentMethod? _selectedPaymentMethod;

    int _finalTotalWithDiscount = 0;
    int? _referralDiscount = 0;
    int? _besarDiskon = 0;
    _cachedCheckoutData =
        Future.wait([_diskonFuture, _paymentFuture, _outletFuture]);
    bool isCheck;
    showModalBottomSheet(
        backgroundColor: const Color.fromARGB(255, 255, 254, 254),
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder(
              future: _cachedCheckoutData,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                }

                final diskonList = snapshot.data?[0]?.data ?? [];
                List<Diskon> diskonListWithNoOption =
                    [noDiscountOption] + diskonList;
                final paymentMethods = snapshot.data?[1]?.data ?? [];

                final orderTotal =
                    int.tryParse(order.order_totals.toString()) ?? 0;
                _finalTotalWithDiscount = _calculateFinalTotal(
                  orderTotal,
                  _selectedDiskon,
                  _referralDiscount ?? 0,
                  _besarDiskon ?? 0,
                );

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: 24,
                    left: 16,
                    right: 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        const Center(
                          child: Text(
                            "Payment",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Discount & Referral
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<Diskon>(
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  labelText: 'Discount',
                                  labelStyle: TextStyle(fontSize: 13),
                                  hintText: 'No Discount',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                                value: _selectedDiskon ?? noDiscountOption,
                                items: diskonListWithNoOption
                                    .map<DropdownMenuItem<Diskon>>((diskon) {
                                  return DropdownMenuItem<Diskon>(
                                    value: diskon,
                                    child: Text(
                                      '${diskon.name}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
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
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: referralCode,
                                      decoration: InputDecoration(
                                        labelText: 'Referral Code',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () async {
                                        if (referralCode.text.isEmpty) {
                                          setModalState(() {
                                            _referralDiscount = 0;
                                            _besarDiskon = 0;
                                            refCode = null;

                                            final orderTotal = int.tryParse(
                                                    order.order_totals
                                                        .toString()) ??
                                                0;
                                            final diskon = _selectedDiskon ==
                                                    noDiscountOption
                                                ? 0
                                                : (_selectedDiskon?.amount ??
                                                    0);

                                            if (_selectedDiskon?.type ==
                                                'fixed') {
                                              _finalTotalWithDiscount =
                                                  orderTotal -
                                                      (_selectedDiskon?.amount
                                                              ?.toInt() ??
                                                          0);
                                            } else {
                                              _finalTotalWithDiscount =
                                                  orderTotal -
                                                      ((orderTotal * diskon) ~/
                                                          100);
                                            }
                                          });

                                          return;
                                        }
                                        try {
                                          final response =
                                              await fetchReferralCodes(
                                            widget.token,
                                            referralCode.text.trim(),
                                          );

                                          if (response.status == true) {
                                            final orderTotal = int.tryParse(
                                                    order.order_totals ?? '') ??
                                                0;
                                            final discountPercent =
                                                response.data.discount.toInt();

                                            setModalState(() {
                                              // Di dalam onPressed untuk search referral code:
                                              setModalState(() {
                                                refCode =
                                                    referralCode.text.trim();
                                                _besarDiskon = discountPercent;
                                                _referralDiscount = (orderTotal *
                                                        discountPercent) ~/
                                                    100; // Hitung dari orderTotal awal
                                                _finalTotalWithDiscount =
                                                    _calculateFinalTotal(
                                                  orderTotal,
                                                  _selectedDiskon ??
                                                      noDiscountOption,
                                                  _referralDiscount ?? 0,
                                                  discountPercent,
                                                );
                                              });
                                            });
                                          }
                                        } catch (e) {
                                          // Error handling
                                        }
                                      },
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Method
                        DropdownButtonFormField<PaymentMethod>(
                          dropdownColor: Colors.white,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          value: _selectedPaymentMethod,
                          hint: const Text('Select Payment Method'),
                          // hint: const Text('Select Payment Method'),
                          items: paymentMethods
                              .map<DropdownMenuItem<PaymentMethod>>((method) {
                            return DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Text(
                                method.payment_name,
                                style: const TextStyle(fontSize: 14),
                                // style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (PaymentMethod? newValue) {
                            setModalState(() {
                              _selectedPaymentMethod = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Total & Process Order Button
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
                                final outletResponse = await _outletFuture;
                                final outletName =
                                    outletResponse.data.outlet_name;
                                final recalculatedTotal = _calculateFinalTotal(
                                  int.parse(order.order_totals),
                                  _selectedDiskon,
                                  _referralDiscount ?? 0,
                                  _besarDiskon ?? 0,
                                );
                                try {
                                  final result = await makeOrder(
                                    token: widget.token,
                                    order: Order(
                                      outlet_id: widget.outletId,
                                      customer_name: order.customer_name,
                                      phone_number: order.phone_number,
                                      order_payment:
                                          _selectedPaymentMethod?.id ?? 1,
                                      order_table: order.order_table,
                                      discount_id: _selectedDiskon?.id,
                                      referral_code: refCode,
                                      order_totals:
                                          recalculatedTotal.toString(),
                                      order_type: order.order_type,
                                      order_details: order.order_details,
                                    ),
                                  );
                                  print(result);
                                  if (result['success'] == true) {
                                    // Jangan di Delete dulu, karena kita ini uat tutup modal yg dibelakang
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message']),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    await Navigator.push(
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
                                          subtotal:
                                              _calculateOrderTotal(_cartItems),
                                          discountVoucher: (_selectedDiskon
                                                  ?.amount
                                                  .toInt() ??
                                              0),
                                          discountType: _selectedDiskon!.type,
                                          discountRef: (_besarDiskon ?? 0),
                                          total: _finalTotalWithDiscount,
                                          paymentMethod: _selectedPaymentMethod
                                                  ?.payment_name ??
                                              'N/A',
                                          orderTime: DateTime.now(),
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      _cartItems.clear();
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    });
                                    // Clear cart items after successful order
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message']),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  print(e);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 53, 150, 105),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Process Order",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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

  int _calculateFinalTotal(int orderTotal, Diskon? discount,
      int referralDiscount, int discountPercent) {
    int tempTotal = orderTotal;

    // 1. Apply referral discount first (percentage of original order total)

    // 2. Then apply main discount (fixed or percentage)
    if (discount != null && discount != noDiscountOption) {
      if (discount.type == 'fixed') {
        tempTotal -= discount.amount.toInt();
        tempTotal -= (tempTotal * discountPercent ~/ 100);
        // Untuk diskon fixed, langsung kurangi amount
      } else {
        if (referralDiscount > 0) {
          tempTotal -= (orderTotal * discountPercent ~/ 100);
        }
        tempTotal -= (tempTotal *
            discount.amount.toInt() ~/
            100); // Untuk diskon persentase
      }
    } else {
      // Jika tidak ada diskon yang dipilih, hanya kurangi referral discount
      tempTotal -= referralDiscount;
    }

    return tempTotal > 0 ? tempTotal : 0;
  }
}
