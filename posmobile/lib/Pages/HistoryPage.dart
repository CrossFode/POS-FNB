import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/Pages/CreateOrderPage.dart';
import 'package:posmobile/Pages/ProductPage.dart';

import '../model/History.dart';

class HistoryPage extends StatefulWidget {
  final String token;
  final String outletId;
  const HistoryPage({Key? key, required this.token, required this.outletId})
      : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<History> orders = [];
  List<History> filteredOrders = [];

  final List<String> paymentOptions = [
    'Cash',
    'QrCode (Lakeside)',
    'QrCode (Telkom University)',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrdersFromApi();
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrdersFromApi() async {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final String token = widget.token;
    final String outletId = widget.outletId;
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API token is missing!')),
      );
      return;
    }
    final String apiUrl =
        '$baseUrl/api/order/outlet/$outletId?start_date=${DateFormat('yyyy-MM-dd').format(startDate)}&end_date=${DateFormat('yyyy-MM-dd').format(endDate)}';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        if (!mounted) return;
        setState(() {
          orders =
              data.map((orderJson) => History.fromJson(orderJson)).toList();
          _filterOrders();
        });
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch orders: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<bool> _updateCustomer(
      String customerId, String newName, String oldPhone) async {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final String token = widget.token;
    final apiUrl = '$baseUrl/api/customer/$customerId';
    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': newName,
        'phone': oldPhone, // selalu kirim nomor lama
      }),
    );
    return response.statusCode == 200;
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = orders.where((order) {
        bool matchesDateRange = order.orderDate.isAfter(
                DateTime(startDate.year, startDate.month, startDate.day)
                    .subtract(const Duration(seconds: 1))) &&
            order.orderDate.isBefore(DateTime(
                endDate.year, endDate.month, endDate.day, 23, 59, 59, 999));
        return matchesDateRange;
      }).toList();
    });
  }

  void _confirmDeleteOrder(History order) {
    int orderNumber = filteredOrders.indexOf(order) + 1;
    String orderNumberStr = orderNumber.toString().padLeft(4, '0');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Order'),
        content:
            Text('Apakah Anda yakin ingin menghapus order ${order.customer}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              // Tambahkan request DELETE ke backend
              final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
              final String token = widget.token;
              final response = await http.delete(
                Uri.parse('$baseUrl/api/order/${order.id}'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );
              if (response.statusCode == 200) {
                setState(() {
                  orders.removeWhere((o) => o.id == order.id);
                  _filterOrders();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.customer} berhasil dihapus'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus order: ${response.body}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editOrder(History order) async {
    // State untuk data edit
    String editedCustomerName = order.customer;
    String? editedCustomerId = order.customerId; // <-- add this line
    String? editedCashierId;
    String? editedPaymentId;
    String? editedOrderType;
    DateTime editedOrderDate = order.orderDate;

    // State untuk dropdown data
    List<Map<String, dynamic>> cashiers = [];
    List<Map<String, dynamic>> paymentMethods = [];
    List<Map<String, dynamic>> orderTypes = [
      {'value': 'dinein', 'label': 'Dine In'},
      {'value': 'takeaway', 'label': 'Take Away'},
      {'value': 'delivery', 'label': 'Delivery'},
    ];
    List<Map<String, dynamic>> customers = []; // fetch dari API

    bool loading = true;
    Map<String, String> errors = {};

    // Fetch data dari API
    Future<void> fetchDropdownData() async {
      try {
        final token = widget.token;
        final outletId = widget.outletId;
        final cashierRes = await http.get(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/outlet/$outletId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final paymentRes = await http.get(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/payment'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final customerRes = await http.get(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/customers'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (cashierRes.statusCode == 200) {
          cashiers = List<Map<String, dynamic>>.from(
              json.decode(cashierRes.body)['data']['users']);
        }
        if (paymentRes.statusCode == 200) {
          paymentMethods = List<Map<String, dynamic>>.from(
              json.decode(paymentRes.body)['data']);
        }
        if (customerRes.statusCode == 200) {
          customers = List<Map<String, dynamic>>.from(
              json.decode(customerRes.body)['data']);
        }
      } catch (e) {
        debugPrint('Error fetching dropdown data: $e');
      }
    }

    await fetchDropdownData();
    loading = false;

    // Set initial value
    editedCashierId = cashiers
        .firstWhere(
          (c) => c['name'] == order.cashier,
          orElse: () => {},
        )['id']
        ?.toString();
    editedPaymentId = paymentMethods
        .firstWhere(
          (p) => p['payment_name'] == order.paymentMethod,
          orElse: () => {},
        )['id']
        ?.toString();
    editedOrderType = orderTypes
        .firstWhere(
          (t) => t['label'] == order.orderType,
          orElse: () => {},
        )['value']
        ?.toString();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Edit Order ${order.customer}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close,
                                        color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                              // Customer Name pakai input field saja
                              Autocomplete<Map<String, dynamic>>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text == '') {
                                    return const Iterable<
                                        Map<String, dynamic>>.empty();
                                  }
                                  return customers.where((c) => c['name']
                                      .toLowerCase()
                                      .contains(
                                          textEditingValue.text.toLowerCase()));
                                },
                                displayStringForOption: (option) =>
                                    option['name'],
                                initialValue:
                                    TextEditingValue(text: order.customer),
                                onSelected: (Map<String, dynamic> selection) {
                                  setState(() {
                                    editedCustomerId =
                                        selection['id'].toString();
                                    editedCustomerName = selection['name'];
                                  });
                                },
                                fieldViewBuilder: (context, controller,
                                    focusNode, onEditingComplete) {
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Customer Name',
                                      border: const OutlineInputBorder(),
                                      errorText: errors['customer_id'] ??
                                          errors['customer_name'],
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        editedCustomerName = value;
                                        // Jika user mengetik manual, customerId dikosongkan
                                      });
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: editedCashierId,
                                decoration: InputDecoration(
                                  labelText: 'Cashier',
                                  border: const OutlineInputBorder(),
                                  errorText: errors['order_cashier'],
                                ),
                                items: cashiers.map((cashier) {
                                  return DropdownMenuItem<String>(
                                    value: cashier['id'].toString(),
                                    child: Text(cashier['name']),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => editedCashierId = value),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: editedPaymentId,
                                decoration: InputDecoration(
                                  labelText: 'Payment Method',
                                  border: const OutlineInputBorder(),
                                  errorText: errors['order_payment'],
                                ),
                                items: paymentMethods.map((payment) {
                                  return DropdownMenuItem<String>(
                                    value: payment['id'].toString(),
                                    child: Text(payment['payment_name']),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => editedPaymentId = value),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: editedOrderType,
                                decoration: InputDecoration(
                                  labelText: 'Order Type',
                                  border: const OutlineInputBorder(),
                                  errorText: errors['order_type'],
                                ),
                                items: orderTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type['value'],
                                    child: Text(type['label']),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => editedOrderType = value),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: editedOrderDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => editedOrderDate = picked);
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: DateFormat('dd MMM yyyy')
                                          .format(editedOrderDate),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Order Date',
                                      border: const OutlineInputBorder(),
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                      errorText: errors['created_at'],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () async {
                                      setState(() => errors = {});
                                      if (editedCustomerName.trim().isEmpty) {
                                        setState(() => errors['customer_name'] =
                                            'Customer wajib diisi');
                                        return;
                                      }
                                      if (editedCashierId == null) {
                                        setState(() => errors['order_cashier'] =
                                            'Cashier wajib diisi');
                                        return;
                                      }
                                      if (editedPaymentId == null) {
                                        setState(() => errors['order_payment'] =
                                            'Payment wajib diisi');
                                        return;
                                      }
                                      if (editedOrderType == null) {
                                        setState(() => errors['order_type'] =
                                            'Order type wajib diisi');
                                        return;
                                      }

                                      if (editedCustomerId != null &&
                                          editedCustomerId!.isNotEmpty) {
                                        if (editedCustomerName.trim() !=
                                            order.customer) {
                                          // Update customer lama (PUT)
                                          final updated = await _updateCustomer(
                                            editedCustomerId!,
                                            editedCustomerName.trim(),
                                            order.customerPhone, // nomor lama
                                          );
                                          if (!updated) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Gagal update customer'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                      }
                                      // Kirim ke API (PUT)
                                      final body = <String, dynamic>{
                                        'order_cashier': editedCashierId,
                                        'order_payment': editedPaymentId,
                                        'order_type': editedOrderType,
                                        'created_at':
                                            editedOrderDate.toIso8601String(),
                                      };
                                      if (editedCustomerId != null &&
                                          editedCustomerId!.isNotEmpty) {
                                        body['customer_id'] = editedCustomerId;
                                      }
                                      if (editedCustomerId == null ||
                                          editedCustomerId!.isEmpty) {
                                        body['customer_name'] =
                                            editedCustomerName.trim();
                                      }

                                      print(json.encode(body));

                                      final response = await http.put(
                                        Uri.parse(
                                            '${dotenv.env['API_BASE_URL']}/api/order/${order.id}'),
                                        headers: {
                                          'Content-Type': 'application/json',
                                          'Authorization':
                                              'Bearer ${widget.token}',
                                        },
                                        body: json.encode(body),
                                      );
                                      if (response.statusCode == 200) {
                                        if (!mounted) return;
                                        setState(() {
                                          orders[orders.indexWhere(
                                                  (o) => o.id == order.id)] =
                                              order.copyWith(
                                            customer: editedCustomerName.trim(),
                                            cashier: cashiers.firstWhere((c) =>
                                                c['id'].toString() ==
                                                editedCashierId)['name'],
                                            paymentMethod:
                                                paymentMethods.firstWhere((p) =>
                                                        p['id'].toString() ==
                                                        editedPaymentId)[
                                                    'payment_name'],
                                            orderType: orderTypes.firstWhere(
                                                (t) =>
                                                    t['value'] ==
                                                    editedOrderType)['label'],
                                            orderDate: editedOrderDate,
                                          );
                                          _filterOrders();
                                        });
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Order updated successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else if (response.statusCode == 422) {
                                        final errorData =
                                            json.decode(response.body);
                                        setState(() {
                                          errors = {};
                                          if (errorData['errors'] != null) {
                                            final errorsData =
                                                errorData['errors'];
                                            if (errorsData is Map) {
                                              errorsData.forEach((key, value) {
                                                if (value is List &&
                                                    value.isNotEmpty) {
                                                  errors[key] =
                                                      value.first.toString();
                                                } else if (value is String) {
                                                  errors[key] = value;
                                                }
                                              });
                                            }
                                          }
                                        });
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed: ${response.body}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Save'),
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

  void _showOrderDetails(History order, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFE2E8F0)),

                // Content yang bisa di-scroll
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order By ${order.customer}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    _getStatusColor(order.status).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(order.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Detail information
                        _buildDetailRow('Customer', order.customer),
                        _buildDetailRow('Phone', order.customerPhone),
                        _buildDetailRow('Order Type', order.orderType),
                        if (order.tableNumber != null)
                          _buildDetailRow('Table', order.tableNumber!),
                        _buildDetailRow('Outlet', order.outlet),
                        _buildDetailRow('Cashier', order.cashier),
                        _buildDetailRow('Payment Method', order.paymentMethod),
                        _buildDetailRow(
                            'Date', _formatDateTime(order.orderDate)),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Items Ordered Section
                        const Text(
                          'Items Ordered:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Items container with max height and scroll
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight: 200, // Maksimal tinggi 200px
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // List produk scrollable
                              Expanded(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: order.products.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = order.products[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                if (item.variantName != null &&
                                                    item.variantName!
                                                        .isNotEmpty)
                                                  Text(
                                                    'Variant: ${item.variantName}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                Text(
                                                  'Qty: ${item.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formatPrice(item.price),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              Text(
                                                _formatPrice(
                                                    item.price * item.quantity),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Subtotal fixed di bawah
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Subtotal:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(order.totalPrice),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Total dengan background berbeda
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markOrderComplete(History order) {
    setState(() {
      final idx = orders.indexWhere((o) => o.id == order.id);
      if (idx != -1) {
        orders[idx] = order.copyWith(status: 'COMPLETED');
      }
      _filterOrders();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id} marked as completed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price).replaceAll(',', '.');
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        _filterOrders();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _printOrder(History order) {
    // Untuk sementara hanya tampilkan SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing receipt... (Coming soon)'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int _currentIndex = 1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Tambahkan baris ini
        title: const Text(
          'Order History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: () {
              _fetchOrdersFromApi();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data refreshed'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date Range',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDate(startDate),
                                      style: const TextStyle(fontSize: 14)),
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward,
                              color: Color(0xFF64748B)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDate(endDate),
                                      style: const TextStyle(fontSize: 14)),
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              filteredOrders.isEmpty
                  ? SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : // Ganti bagian ListView.builder di dalam build method (sekitar baris 850-950)
                  // Ganti bagian ListView.builder di dalam build method (sekitar baris 850-950)
                  ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 1,
                            color: Colors.white,
                            shadowColor: Colors.grey.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1),
                            ),
                            child: InkWell(
                              onTap: () => _showOrderDetails(order, index),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header dengan nama customer dan menu
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Order By ${order.customer}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: order.status == 'PAID'
                                                    ? const Color(0xFFDCFCE7)
                                                    : _getStatusColor(
                                                            order.status)
                                                        .withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                order.status,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: order.status == 'PAID'
                                                      ? const Color(0xFF16A34A)
                                                      : _getStatusColor(
                                                          order.status),
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: Color(0xFF64748B),
                                                size: 20,
                                              ),
                                              offset: const Offset(0, 35),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'edit':
                                                    _editOrder(order);
                                                    break;
                                                  case 'details':
                                                    _showOrderDetails(
                                                        order, index);
                                                    break;
                                                  case 'complete':
                                                    _markOrderComplete(order);
                                                    break;
                                                  case 'print':
                                                    _printOrder(order);
                                                    break;
                                                  case 'delete':
                                                    _confirmDeleteOrder(order);
                                                    break;
                                                }
                                              },
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                PopupMenuItem(
                                                  value: 'details',
                                                  height: 40,
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.visibility,
                                                          size: 18,
                                                          color: Colors.grey),
                                                      const SizedBox(width: 12),
                                                      const Text('View Details',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  height: 40,
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.edit,
                                                          size: 18,
                                                          color: Colors.blue),
                                                      const SizedBox(width: 12),
                                                      const Text('Edit Order',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                                if (order.status == 'PENDING')
                                                  PopupMenuItem(
                                                    value: 'complete',
                                                    height: 40,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.check_circle,
                                                            size: 18,
                                                            color:
                                                                Colors.green),
                                                        const SizedBox(
                                                            width: 12),
                                                        const Text(
                                                            'Mark Complete',
                                                            style: TextStyle(
                                                                fontSize: 14)),
                                                      ],
                                                    ),
                                                  ),
                                                PopupMenuItem(
                                                  value: 'print',
                                                  height: 40,
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.print,
                                                          size: 18,
                                                          color: Colors.blue),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                          'Print Receipt',
                                                          style: TextStyle(
                                                              fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuDivider(),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  height: 40,
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.delete,
                                                          size: 18,
                                                          color: Colors.red),
                                                      const SizedBox(width: 12),
                                                      const Text('Delete',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    // Date
                                    Text(
                                      'Date: ${_formatDateTime(order.orderDate)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Total
                                    Text(
                                      _formatPrice(order.totalPrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: Navbar(
      //   currentIndex: _currentIndex,
      //   onTap: (index) {
      //     // Handle navigation here
      //     if (index != _currentIndex) {
      //       // Example navigation logic - adjust as needed
      //       if (index == 0) {
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(
      //               builder: (context) => ProductPage(
      //                   token: widget.token, outletId: widget.outletId)),
      //         );
      //       } else if (index == 2) {
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(
      //               builder: (context) => CreateOrderPage(
      //                   token: widget.token, outletId: widget.outletId)),
      //         );
      //       }
      //       // And so on for other indices
      //     }
      //   },
      // ),
    );
  }
}
