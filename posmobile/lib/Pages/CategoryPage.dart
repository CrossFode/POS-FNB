import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/Model/Model.dart';

class CategoryPage extends StatefulWidget {
  final String token;
  final String outletId;
  final int navIndex; // Index navbar saat ini
  final Function(int)? onNavItemTap; // Callback untuk navigasi
  final bool isManager;
  const CategoryPage(
      {Key? key,
      required this.token,
      required this.outletId,
      this.navIndex = 2, // Default index
      this.onNavItemTap,
      required this.isManager})
      : super(key: key);
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  late Future<CategoryResponse> _categoryFuture;

  @override
  void initState() {
    super.initState();
    _categoryFuture = fetchCategoryinOutlet(widget.token, widget.outletId);
  }

  Future<CategoryResponse> fetchCategoryinOutlet(token, outletId) async {
    final url = Uri.parse('$baseUrl/api/category/outlet/$outletId');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return CategoryResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load Payment Method: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Category: $e');
    }
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      final url = Uri.parse('$baseUrl/api/category/${category.id}');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
        setState(() {
          _categoryFuture =
              fetchCategoryinOutlet(widget.token, widget.outletId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete category: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Center(
            child: Text(
              'Delete Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ),
          content: Text(
            'Apakah anda yakin akan menghapus "${category.category_name}"?',
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      _deleteCategory(category);
                    },
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
        );
      },
    );
  }

  void _showCreateCategoryDialog({
    required BuildContext context,
    required bool isEdit,
    Category? category,
  }) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController =
        TextEditingController(text: isEdit ? category?.category_name : '');
    int _isFood = isEdit ? category?.is_food ?? 1 : 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        isEdit ? 'Edit Category' : 'Create Category',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Name
                    const Text(
                      "CATEGORY NAME",
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
                        hintText: 'Category Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Type (Food/Non-Food)
                    const Text(
                      "TYPE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _isFood,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Food')),
                        DropdownMenuItem(value: 0, child: Text('Non-Food')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _isFood = value;
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 53, 150, 105),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEdit ? 'Update' : 'Create',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final payload = {
                                  'category_name': _nameController.text,
                                  'is_food': _isFood,
                                  'outlet_id': widget.outletId,
                                };

                                try {
                                  final uri = isEdit
                                      ? Uri.parse('$baseUrl/api/category/${category!.id}')
                                      : Uri.parse('$baseUrl/api/category');

                                  final response = await (isEdit
                                      ? http.put(
                                          uri,
                                          headers: {
                                            'Authorization': 'Bearer ${widget.token}',
                                            'Content-Type': 'application/json',
                                          },
                                          body: jsonEncode(payload),
                                        )
                                      : http.post(
                                          uri,
                                          headers: {
                                            'Authorization': 'Bearer ${widget.token}',
                                            'Content-Type': 'application/json',
                                          },
                                          body: jsonEncode(payload),
                                        ));

                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Category ${isEdit ? 'updated' : 'created'} successfully')),
                                    );
                                    setState(() {
                                      _categoryFuture = fetchCategoryinOutlet(
                                          widget.token, widget.outletId);
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to save category')),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 30), // geser ke kanan 16px
            child: Text(
              "Category",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
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

              // Content asli tetap disini
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  children: [
                    Expanded(
                      child: FutureBuilder<CategoryResponse>(
                        future: _categoryFuture,
                        // Widget FutureBuilder yang sudah ada tetap sama
                        builder: (context, snapshot) {
                          // Isi builder tetap sama...
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
                                child: Text('No categories found.'));
                          } else {
                            // Return ListView.builder yang sudah ada
                            final categories = snapshot.data!.data;
                            return ListView.builder(
                              // Isi ListView.builder tetap sama
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  elevation: 2,
                                  color: Colors.white.withOpacity(0.9),
                                  child: ListTile(
                                    leading: Icon(
                                      category.is_food == 1
                                          ? Icons.fastfood
                                          : Icons.category,
                                      color: category.is_food == 1
                                          ? Colors.green
                                          : Colors.blueGrey,
                                    ),
                                    title: Text(
                                      category.category_name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text('Outlet ID: '),
                                        Flexible(
                                          child: Text(
                                            category.outlet_id,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            _showCreateCategoryDialog(
                                              context: context,
                                              isEdit: true,
                                              category: category,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            _showDeleteConfirmationDialog(
                                                category);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showCreateCategoryDialog(context: context, isEdit: false);
          },
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Create Category',
        ),
        bottomNavigationBar: _buildNavbar());
  }

  Widget _buildNavbar() {
    // Anda bisa membuat navbar khusus atau menggunakan yang sudah ada
    // Contoh dengan NavbarManager:
    return FlexibleNavbar(
      currentIndex: widget.navIndex,
      isManager: widget.isManager,
      onTap: (index) {
        if (index != widget.navIndex) {
          if (widget.onNavItemTap != null) {
            widget.onNavItemTap!(index);
          } else {
            // Default navigation behavior
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
                onTap: () => _navigateTo(ReferralCodePage(
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
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.payment,
                label: 'Payment',
                onTap: () => _navigateTo(Payment(
                  token: widget.token,
                  outletId: widget.outletId,
                  isManager: widget.isManager,
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
        Navigator.pop(context); // Tutup bottom sheet
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

  void _handleNavigation(int index) {
    // Implementasi navigasi berdasarkan index
    if (widget.isManager == true) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              token: widget.token,
              outletId: widget.outletId,
              isManager: widget.isManager,
              // isManager: widget.isManager,
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
                isManager: widget.isManager),
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
    // Tambahkan case lainnya sesuai kebutuhan
  }
}
