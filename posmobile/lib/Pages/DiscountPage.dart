import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/model/model.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/Auth/login.dart';
import 'package:posmobile/Pages/Dashboard/Home.dart';
import 'package:posmobile/Api/CreateOrder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscountPage extends StatefulWidget {
  final String token;
  final int? userRoleId;
  final String outletId;
  final bool isManager;
  final int navIndex;
  final bool? isOpened;
  final Function(int)? onNavItemTap;

  const DiscountPage({
    Key? key,
    required this.token,
    required this.outletId,
    this.userRoleId,
    this.navIndex = 3, // Default ke tab History (index 3)
    this.onNavItemTap,
    this.isOpened = true, // Default ke false
    required this.isManager,
  }) : super(key: key);

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  List<Diskon> _discounts = [];
  List<Outlet> _outlets = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _outletName = '';

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      if (widget.token.isEmpty) {
        // Tampilkan SnackBar setelah frame build selesai
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('API token is missing!')),
            );
          }
        });
        setState(() => _isLoading = false);
      } else {
        _loadData();
        _loadOutletName();
      }
    }
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

  Future<void> _loadData() async {
    final String? token = widget.token;
    if (widget.token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API token is missing!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final discounts = await _getDiscounts();
      final outlets = await _getOutlets();
      if (!mounted) return;
      setState(() {
        _discounts = discounts;
        _outlets = outlets;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<List<Diskon>> _getDiscounts() async {
    try {
      final String apiUrl = '$baseUrl/api/discount';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> discountList = data['data'] ?? [];
        return discountList.map((json) => Diskon.fromJson(json)).toList();
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        throw Exception('Failed to load discounts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching discounts: $e');
      throw Exception('Error fetching discounts: $e');
    }
  }

  Future<List<Outlet>> _getOutlets() async {
    try {
      final endpoint =
          widget.userRoleId == 1 ? 'api/outlet' : 'api/outlet/current/user';
      final String apiUrl = '$baseUrl/$endpoint';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> outletList = data['data'] ?? [];
        return outletList.map((json) => Outlet.fromJson(json)).toList();
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        throw Exception('Failed to load outlets: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching outlets: $e');
      throw Exception('Error fetching outlets: $e');
    }
  }

  Future<bool> _createDiscount({
    required String name,
    required String type,
    required int amount,
    required List<String> outletIds,
  }) async {
    try {
      final String apiUrl = '$baseUrl/api/discount';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode({
          'name': name,
          'type': type,
          'amount': amount,
          'outlet_ids': outletIds, // Kirim outletIds ke API
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Error creating discount: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating discount: $e');
      throw Exception('Error creating discount: $e');
    }
  }

  Future<bool> _updateDiscount({
    required int id,
    required String name,
    required String type,
    required int amount,
    required List<String> outletIds,
  }) async {
    try {
      final String apiUrl = '$baseUrl/api/discount/$id';
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode({
          'name': name,
          'type': type,
          'amount': amount,
          'outlet_ids': outletIds, // Kirim outletIds ke API
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Error updating discount: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating discount: $e');
      throw Exception('Error updating discount: $e');
    }
  }

  Future<bool> _deleteDiscount(int id) async {
    try {
      final String apiUrl = '$baseUrl/api/discount/$id';
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Error deleting discount: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting discount: $e');
      throw Exception('Error deleting discount: $e');
    }
  }

  List<Diskon> get _filteredDiscounts {
    if (_searchQuery.isEmpty) return _discounts;
    return _discounts
        .where((discount) =>
            discount.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 53, 150, 105),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea:
          false, // Penting! Untuk memungkinkan dialog keluar dari SafeArea
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1, // Posisi tetap
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: _DiscountFormDialog(
                  outlets: _outlets,
                  onSubmit: (name, type, amount, [outletIds]) async {
                    try {
                      final success = await _createDiscount(
                        name: name,
                        type: type,
                        amount: amount,
                        outletIds: outletIds ?? [],
                      );
                      if (success) {
                        _showSuccessSnackBar('Discount created successfully');
                        _loadData();
                        return true;
                      } else {
                        _showErrorSnackBar('Failed to create discount');
                        return false;
                      }
                    } catch (e) {
                      _showErrorSnackBar('Error creating discount: $e');
                      return false;
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Diskon discount) async {
    // Tidak perlu API call lagi
    // Gunakan langsung outletIds yang sudah disimpan
    final selectedOutletIds = discount.outletIds;

    print('Editing discount ${discount.id} with outlets: $selectedOutletIds');

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _DiscountFormDialog(
        outlets: _outlets,
        discount: discount,
        selectedOutletIds:
            selectedOutletIds, // Gunakan data yang sudah disimpan
        onSubmit: (name, type, amount, [outletIds]) async {
          try {
            final success = await _updateDiscount(
              id: discount.id!,
              name: name,
              type: type,
              amount: amount,
              outletIds: outletIds ?? [],
            );
            if (success) {
              _showSuccessSnackBar('Discount updated successfully');
              _loadData();
              return true;
            } else {
              _showErrorSnackBar('Failed to update discount');
              return false;
            }
          } catch (e) {
            _showErrorSnackBar('Error updating discount: $e');
            return false;
          }
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(Diskon discount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Delete Discount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Apakah anda yakin ingin menghapus diskon "${discount.name}"?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      color: Color.fromARGB(255, 145, 145, 145),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
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
    );

    if (confirmed == true) {
      try {
        final success = await _deleteDiscount(discount.id!);
        if (success) {
          _showSuccessSnackBar('Deleted! Discount has been deleted.');
          _loadData();
        } else {
          _showErrorSnackBar('Failed! Something went wrong.');
        }
      } catch (e) {
        _showErrorSnackBar('Failed! ${e.toString()}');
      }
    }
  }

  Future<List<String>> _getOutletIdsForDiscount(int discountId) async {
    try {
      final String apiUrl = '$baseUrl/api/discount/$discountId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Tambahkan print statement untuk melihat response lengkap
        print('API Response: ${response.body}');

        final discountData = data['data'];
        if (discountData != null && discountData['outlets'] != null) {
          final List<dynamic> outletList = discountData['outlets'];

          // Konversi secara eksplisit ke String
          final List<String> result = outletList
              .map<String>((outlet) => outlet['id'].toString())
              .toList();

          print('Outlet IDs dari API: $result');
          return result;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching outlet IDs: $e');
      return [];
    }
  }

  Future<void> _fetchDiscounts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('$baseUrl/api/discount'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: print full response
        print('Full response from /api/discount: ${response.body}');

        if (data['data'] != null) {
          final List<dynamic> discountList = data['data'];

          setState(() {
            _discounts = discountList
                .map((discount) => Diskon.fromJson(discount))
                .toList();

            // Debug: print parsed discounts with outlet IDs
            for (var discount in _discounts) {
              print(
                  'Discount ${discount.id} has outlets: ${discount.outletIds}');
            }

            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching discounts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Row(
              children: [
                Text(
                  "DISCOUNT ",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_outletName.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      _outletName,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color.fromARGB(255, 245, 244, 244),
        // Prevent resizing when keyboard appears
        body: Stack(
          children: [
            // Background image dengan opacity 0.5
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/FixGaSihV2.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
              ),
            ),

            // Konten asli
            Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search discounts...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),

                // Discounts ListView
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredDiscounts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.percent_outlined,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No discounts found',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredDiscounts.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final discount = _filteredDiscounts[index];
                                return Card(
                                  color:
                                      const Color.fromARGB(255, 255, 254, 254),
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 2),
                                  child: ListTile(
                                    title: Text(
                                      discount.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          discount.type == 'percent'
                                              ? '${discount.amount}% off'
                                              : 'Rp ${NumberFormat('#,###').format(discount.amount)} off',
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                                255, 53, 150, 105),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          discount.created_at != null
                                              ? 'Created: ${DateFormat('dd/MM/yyyy').format(discount.created_at!)}'
                                              : '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: const Color.fromARGB(
                                                  255, 61, 63, 65)),
                                          onPressed: () =>
                                              _showEditDialog(discount),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red[700]),
                                          onPressed: () =>
                                              _showDeleteDialog(discount),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 53, 150, 105).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _showCreateDialog,
            backgroundColor: const Color.fromARGB(255, 53, 150, 105),
            elevation: 0,
            // shape: const CircleBorder(),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
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
          print("Tapping on index: $index");
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

              //Menu tambahan khusus untuk manager
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
                  color: Colors.green,
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
        print('More options pressed');
      }
    }
  }
}

class _DiscountFormDialog extends StatefulWidget {
  final Diskon? discount;
  final List<Outlet> outlets;
  final List<String>? selectedOutletIds;
  final Future<bool> Function(String name, String type, int amount,
      [List<String>? outletIds]) onSubmit;

  const _DiscountFormDialog({
    this.discount,
    required this.outlets,
    this.selectedOutletIds,
    required this.onSubmit,
  });

  @override
  State<_DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<_DiscountFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'percent';
  bool _isSubmitting = false;
  List<String> _selectedOutletIds = [];
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    print(
        'Edit dialog received selectedOutletIds: ${widget.selectedOutletIds}');

    _selectedOutletIds = [];

    if (widget.discount != null) {
      _nameController.text = widget.discount!.name;
      _amountController.text = widget.discount!.amount.toString();
      _selectedType = widget.discount!.type;
    }

    // Pastikan data diassign dengan benar
    if (widget.selectedOutletIds != null) {
      _selectedOutletIds = List<String>.from(widget.selectedOutletIds!);
      print('Initialized _selectedOutletIds: $_selectedOutletIds');
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onSubmit(
        _nameController.text.trim(),
        _selectedType,
        int.parse(_amountController.text),
        _selectedOutletIds,
      );
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600 ? 16.0 : 80.0,
          vertical: 24.0,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                      widget.discount != null
                          ? 'Edit Discount'
                          : 'New Discount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  const Text(
                    "NAME",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter discount name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.discount,
                          color: Color.fromARGB(255, 53, 150, 105)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Discount Type
                  const Text(
                    "DISCOUNT TYPE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: _typeSelectionButton(
                            title: 'Percentage',
                            icon: Icons.percent,
                            value: 'percent',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _typeSelectionButton(
                            title: ' Fixed',
                            icon: Icons.attach_money,
                            value: 'fixed',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Amount
                  const Text(
                    "AMOUNT",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(
                        _selectedType == 'fixed'
                            ? Icons.attach_money
                            : Icons.percent,
                        color: Color.fromARGB(255, 53, 150, 105),
                      ),
                      suffixText: _selectedType == 'percent' ? '%' : '',
                      prefixText: _selectedType == 'fixed' ? 'Rp ' : '',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = int.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      if (_selectedType == 'percent' && amount > 100) {
                        return 'Percentage cannot exceed 100%';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Assign Outlet
                  const Text(
                    "ASSIGN OUTLET",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const Divider(thickness: 1.5, height: 24),
                  Container(
                    height: widget.outlets.length > 5 ? 200 : null,
                    decoration: widget.outlets.length > 5
                        ? BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: widget.outlets.length > 5
                          ? null
                          : NeverScrollableScrollPhysics(),
                      itemCount: widget.outlets.length,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      itemBuilder: (context, index) {
                        final outlet = widget.outlets[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Builder(builder: (context) {
                                  // Pastikan kedua nilai dalam format yang sama untuk perbandingan
                                  final outletIdStr = outlet.id.toString();

                                  // Print untuk debugging
                                  print(
                                      'Comparing outlet $outletIdStr (${outlet.outlet_name}) with selected $_selectedOutletIds');

                                  // Periksa apakah ID ada dalam list dengan perbandingan yang lebih ketat
                                  bool isChecked = false;
                                  for (String id in _selectedOutletIds) {
                                    if (id == outletIdStr) {
                                      isChecked = true;
                                      break;
                                    }
                                  }
                                  print('Result: $isChecked');

                                  return Checkbox(
                                    value: isChecked,
                                    onChanged: (bool? selected) {
                                      setState(() {
                                        if (selected == true) {
                                          if (!_selectedOutletIds
                                              .contains(outletIdStr)) {
                                            _selectedOutletIds.add(outletIdStr);
                                            print('Added outlet: $outletIdStr');
                                          }
                                        } else {
                                          _selectedOutletIds
                                              .remove(outletIdStr);
                                          print('Removed outlet: $outletIdStr');
                                        }
                                      });
                                    },
                                    activeColor:
                                        const Color.fromARGB(255, 53, 150, 105),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  );
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  outlet.outlet_name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 53, 150, 105),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
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
      ),
    );
  }

  Widget _typeSelectionButton({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 53, 150, 105)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
