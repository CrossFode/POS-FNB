import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Model/Payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Pages/Pages.dart';
import 'package:posmobile/Auth/login.dart';
import 'package:posmobile/Pages/Dashboard/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:posmobile/Api/CreateOrder.dart';

class Payment extends StatefulWidget {
  final String token;
  final String outletId;
  final int navIndex;
  final Function(int)? onNavItemTap;
  final bool isManager;
  const Payment({
    Key? key,
    required this.token,
    required this.outletId,
    this.navIndex = 3,
    this.onNavItemTap,
    required this.isManager,
  }) : super(key: key);

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  late Future<PaymentMethodResponse> _paymentFuture;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _outletName = '';

  @override
  void initState() {
    super.initState();
    _paymentFuture = fetchAllPayments();
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

  Future<PaymentMethodResponse> fetchAllPayments() async {
    final url = Uri.parse('$baseUrl/api/payment');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      return PaymentMethodResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load payments');
    }
  }

  Future<void> addPayment() async {
    final url = Uri.parse('$baseUrl/api/payment');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'payment_name': _nameController.text,
        'payment_description': _descController.text,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _paymentFuture = fetchAllPayments();
      });
      _nameController.clear();
      _descController.clear();
    } else {
      throw Exception('Failed to add payment');
    }
  }

  Future<void> updatePayment(PaymentMethod payment) async {
    final url = Uri.parse('$baseUrl/api/payment/${payment.id}');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'payment_name': payment.payment_name,
        'payment_description': payment.payment_description,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _paymentFuture = fetchAllPayments();
      });
    } else {
      throw Exception('Failed to update payment');
    }
  }

  Future<void> deletePayment(int id) async {
    final url = Uri.parse('$baseUrl/api/payment/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _paymentFuture = fetchAllPayments();
      });
    } else {
      throw Exception('Failed to delete payment');
    }
  }

  void _showEditDialog(PaymentMethod payment) {
    final _formKey = GlobalKey<FormState>();
    _nameController.text = payment.payment_name;
    _descController.text = payment.payment_description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const Text('Edit Payment'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Payment Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a payment name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color.fromARGB(255, 53, 150, 105)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 53, 150, 105),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await updatePayment(
                    PaymentMethod(
                      id: payment.id,
                      payment_name: _nameController.text,
                      payment_description: _descController.text,
                      created_at: payment.created_at,
                      updated_at: DateTime.now(),
                    ),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Payment updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final _formKey = GlobalKey<FormState>();
    _nameController.clear();
    _descController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text('Add Payment'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Payment Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a payment name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 53, 150, 105)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 53, 150, 105),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await addPayment();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Payment added successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _onNavTapped(int index) {
    if (widget.onNavItemTap != null) {
      widget.onNavItemTap!(index);
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
                  "PAYMENT METHOD ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_outletName.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      _outletName,
                      style: TextStyle(
                        fontSize: 20,
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
        backgroundColor: const Color.fromARGB(255, 245, 244, 244),
        body: SafeArea(
            child: Stack(children: [
          // Background image - paling bawah dalam Stack

          FutureBuilder<PaymentMethodResponse>(
            future: _paymentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final payments = snapshot.data?.data ?? [];
              return ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(payment.payment_name),
                      subtitle: Text(payment.payment_description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.black),
                            onPressed: () => _showEditDialog(payment),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _showDeleteConfirmationDialog(payment),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )
        ])),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddDialog();
          },
          backgroundColor: const Color.fromARGB(255, 53, 150, 105),
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Create Category',
        ),
        bottomNavigationBar: _buildNavbar());
  }

  void _showDeleteConfirmationDialog(PaymentMethod payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Center(
            child: Text(
              'Delete Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ),
          content: Text(
            'Are you sure want to delete "${payment.payment_name}" payment method?',
            textAlign: TextAlign.center,
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      deletePayment(payment.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment method "${payment.payment_name}" deleted successfully',
                          ),
                        ),
                      );
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
                  color: Colors.green,
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
