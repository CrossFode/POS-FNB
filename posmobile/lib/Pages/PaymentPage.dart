import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Model/Payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Pages/Pages.dart';

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

  @override
  void initState() {
    super.initState();
    _paymentFuture = fetchAllPayments();
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
            padding: const EdgeInsets.only(left: 30), // geser ke kanan 16px
            child: Text(
              "Payment Method",
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
            child: Stack(children: [
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
                            onPressed: () => deletePayment(payment.id),
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
