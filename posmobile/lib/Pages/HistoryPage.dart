import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posmobile/Components/Navbar.dart';
import 'package:posmobile/model/model.dart';
import 'package:posmobile/Pages/Pages.dart';

class HistoryPage extends StatefulWidget {
  final String token;
  final String outletId;
  final int navIndex;
  final Function(int)? onNavItemTap;
  final bool isManager;

  const HistoryPage({
    Key? key,
    required this.token,
    required this.outletId,
    this.navIndex = 3, // Default ke tab History (index 3)
    this.onNavItemTap,
    required this.isManager,
  }) : super(key: key);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Delete Order',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
        content: Text(
          'Apakah anda yakin ingin menghapus history "${order.customer}"?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: () async {
                    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
                    final String token = widget.token;
                    final response = await http.delete(
                      Uri.parse('$baseUrl/api/order/${order.id}'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                    );
                    if (!mounted) return;
                    if (response.statusCode == 200) {
                      setState(() {
                        orders.removeWhere((o) => o.id == order.id);
                        _filterOrders();
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Order ${order.customer} berhasil dihapus'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Gagal menghapus order: ${response.body}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Form(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Center(
                                child: Text(
                                  'Edit Order ${order.customer}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                                      hintText: 'Customer Name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      filled: true,
                                      fillColor: Colors.white,
                                      errorText: errors['customer_id'] ??
                                          errors['customer_name'],
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        editedCustomerName = value;
                                        editedCustomerId = null;
                                        // Jika user mengetip manual, customerId dikosongkan
                                      });
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 18),

                              // Cashier
                              const Text(
                                "CASHIER",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: editedCashierId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'Cashier',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  errorText: errors['order_cashier'],
                                ),
                                items: cashiers.map((cashier) {
                                  return DropdownMenuItem<String>(
                                    value: cashier['id'].toString(),
                                    child: Text(
                                      cashier['name'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => editedCashierId = value),
                              ),
                              const SizedBox(height: 18),

                              // Payment Method
                              const Text(
                                "PAYMENT METHOD",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: editedPaymentId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'Payment Method',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  errorText: errors['order_payment'],
                                ),
                                items: paymentMethods.map((payment) {
                                  return DropdownMenuItem<String>(
                                    value: payment['id'].toString(),
                                    child: Text(
                                      payment['payment_name'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => editedPaymentId = value),
                              ),

                              const SizedBox(height: 18),

                              // Order Date
                              const Text(
                                "ORDER DATE",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                      hintText: 'Order Date',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      filled: true,
                                      fillColor: Colors.white,
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                      errorText: errors['created_at'],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Color.fromARGB(255, 53, 150, 105),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        setState(() => errors = {});
                                        if (editedCustomerName.trim().isEmpty) {
                                          setState(() =>
                                              errors['customer_name'] =
                                                  'Customer wajib diisi');
                                          return;
                                        }
                                        if (editedCashierId == null) {
                                          setState(() =>
                                              errors['order_cashier'] =
                                                  'Cashier wajib diisi');
                                          return;
                                        }
                                        if (editedPaymentId == null) {
                                          setState(() =>
                                              errors['order_payment'] =
                                                  'Payment wajib diisi');
                                          return;
                                        }

                                        if (editedCustomerId != null &&
                                            editedCustomerId!.isNotEmpty) {
                                          if (editedCustomerName.trim() !=
                                              order.customer) {
                                            // Update customer lama (PUT)
                                            final updated =
                                                await _updateCustomer(
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
                                          body['customer_id'] =
                                              editedCustomerId;
                                        }
                                        if (editedCustomerId == null ||
                                            editedCustomerId!.isEmpty) {
                                          body['customer_name'] =
                                              editedCustomerName.trim();
                                        }

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
                                              customer:
                                                  editedCustomerName.trim(),
                                              cashier: cashiers.firstWhere(
                                                  (c) =>
                                                      c['id'].toString() ==
                                                      editedCashierId)['name'],
                                              paymentMethod: paymentMethods
                                                      .firstWhere((p) =>
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
                                                errorsData
                                                    .forEach((key, value) {
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 53, 150, 105),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (fixed)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rincian Pesanan',
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
                ),
                const Divider(height: 1),

                // Content scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info customer & status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Order by ${order.customer}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(height: 16),

                          // Info detail pesanan
                          const Text(
                            'Informasi Pesanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Detail informasi
                          _buildDetailRow('Customer', order.customer),
                          _buildDetailRow('Phone', order.customerPhone),
                          _buildDetailRow('Order Type', order.orderType),
                          if (order.tableNumber != null)
                            _buildDetailRow('Table', order.tableNumber!),
                          _buildDetailRow('Outlet', order.outlet),
                          _buildDetailRow('Cashier', order.cashier),
                          _buildDetailRow(
                              'Payment Method', order.paymentMethod),
                          _buildDetailRow(
                              'Date', _formatDateTime(order.orderDate)),

                          const Divider(height: 32),

                          // Rincian Pesanan (Items)
                          const Text(
                            'Rincian Pesanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // List produk (seperti di gambar tanpa gambar)
                          ...order.products
                              .map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Nama, jumlah dan harga
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item.quantity}x ${item.name}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatPrice(
                                                  item.price * item.quantity),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Hanya tampilkan variant (jika ada)
                                        if (item.variantName != null &&
                                            item.variantName!.isNotEmpty)
                                          Text(
                                            item.variantName!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),

                                        const SizedBox(height: 4),
                                        const Divider(height: 8),
                                      ],
                                    ),
                                  ))
                              .toList(),

                          const SizedBox(height: 12),

                          // Ringkasan harga
                          // Subtotal Pesanan
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.40,
                                  ),
                                  child: const Text(
                                    'Subtotal Pesanan',
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ),
                                Text(
                                  _formatPrice(order.subtotalPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Diskon Regular jika ada
                          if (order.discountName != null &&
                              order.discountAmount != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Voucher Diskon',
                                      style:
                                          const TextStyle(color: Colors.green)),
                                  Text(
                                    '-${_formatPrice(order.discountType == 'percent' ? (order.subtotalPrice * order.discountAmount!) ~/ 100 : order.discountAmount!)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),

                          // Diskon Referral jika ada
                          if (order.referralCode != null &&
                              order.referralDiscount != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Referral',
                                      style:
                                          const TextStyle(color: Colors.green)),
                                  Text(
                                    '-${_formatPrice(_calculateReferralDiscount(order))}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Total Bayar (fixed di bawah)
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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

  int _calculateReferralDiscount(History order) {
    // Jika tidak ada referral atau persentase diskon
    if (order.referralCode == null || order.referralDiscount == null) {
      return 0;
    }

    int priceAfterDiscount = order.subtotalPrice;

    // Jika ada diskon reguler, hitung harga setelah diskon
    if (order.discountName != null && order.discountAmount != null) {
      if (order.discountType == 'percent') {
        priceAfterDiscount -=
            (order.subtotalPrice * order.discountAmount!) ~/ 100;
      } else {
        priceAfterDiscount -= order.discountAmount!;
      }
    }

    // Hitung diskon referral dari harga setelah diskon reguler
    return (priceAfterDiscount * order.referralDiscount!) ~/ 100;
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Order History",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 53, 150, 105),
        elevation: 0,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Color.fromARGB(255, 255, 255, 255)),
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
            icon: const Icon(Icons.download,
                color: Color.fromARGB(255, 255, 255, 255)),
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
      backgroundColor: const Color.fromARGB(255, 245, 244, 244),
      body: Stack(
        children: [
          // Background image (hanya di belakang konten)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/FixGaSihV2.png'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
            ),
          ),

          // Konten utama
          Column(
            children: [
              // Container untuk date range picker (tanpa background image)
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
                  ],
                ),
              ),

              // List order dengan background image
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: filteredOrders.isEmpty
                      ? Center(
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
                        )
                      : ListView.builder(
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
                                    onTap: () =>
                                        _showOrderDetails(order, index),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: order.status ==
                                                              'PAID'
                                                          ? const Color(
                                                              0xFFDCFCE7)
                                                          : _getStatusColor(
                                                                  order.status)
                                                              .withAlpha(30),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      order.status,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: order.status ==
                                                                'PAID'
                                                            ? const Color(
                                                                0xFF16A34A)
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
                                                    color: Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
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
                                                          _markOrderComplete(
                                                              order);
                                                          break;
                                                        case 'print':
                                                          List<
                                                                  Map<String,
                                                                      dynamic>>
                                                              billItems =
                                                              order.products.map(
                                                                  (product) {
                                                            return {
                                                              'name':
                                                                  product.name,
                                                              'quantity':
                                                                  product
                                                                      .quantity,
                                                              'total_price': product
                                                                      .price *
                                                                  product
                                                                      .quantity,
                                                              'variants':
                                                                  product.variantName !=
                                                                          null
                                                                      ? [
                                                                          {
                                                                            'name':
                                                                                product.variantName
                                                                          }
                                                                        ]
                                                                      : [],
                                                              'modifier':
                                                                  [], // Add modifiers if available
                                                              'notes':
                                                                  '', // Add notes if available
                                                            };
                                                          }).toList();
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      Previewbill(
                                                                outletName:
                                                                    order
                                                                        .outlet,
                                                                // orderId: 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
                                                                customerName:
                                                                    order
                                                                        .customer,
                                                                orderType: order
                                                                    .orderType,
                                                                tableNumber:
                                                                    int.tryParse(order.tableNumber ??
                                                                            '0') ??
                                                                        0,
                                                                items:
                                                                    billItems,
                                                                subtotal: order
                                                                    .subtotalPrice,
                                                                discountVoucher:
                                                                    order.discountAmount ??
                                                                        0,
                                                                discountType:
                                                                    order.discountType ??
                                                                        'fixed',
                                                                discountRef:
                                                                    order.referralDiscount ??
                                                                        0,
                                                                total: order
                                                                    .totalPrice,
                                                                paymentMethod: order
                                                                    .paymentMethod,
                                                                orderTime: order
                                                                    .orderDate,
                                                              ),
                                                            ),
                                                          );
                                                          break;
                                                        case 'delete':
                                                          _confirmDeleteOrder(
                                                              order);
                                                          break;
                                                      }
                                                    },
                                                    itemBuilder: (BuildContext
                                                            context) =>
                                                        [
                                                      PopupMenuItem(
                                                        value: 'details',
                                                        height: 40,
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .visibility,
                                                                size: 18,
                                                                color: Colors
                                                                    .grey),
                                                            const SizedBox(
                                                                width: 12),
                                                            const Text(
                                                                'View Details',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        height: 40,
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                                Icons.edit,
                                                                size: 18,
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        98,
                                                                        101,
                                                                        103)),
                                                            const SizedBox(
                                                                width: 12),
                                                            const Text(
                                                                'Edit Order',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                      ),
                                                      if (order.status ==
                                                          'PENDING')
                                                        PopupMenuItem(
                                                          value: 'complete',
                                                          height: 40,
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  size: 18,
                                                                  color: Colors
                                                                      .green),
                                                              const SizedBox(
                                                                  width: 12),
                                                              const Text(
                                                                  'Mark Complete',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14)),
                                                            ],
                                                          ),
                                                        ),
                                                      PopupMenuItem(
                                                        value: 'print',
                                                        height: 40,
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                                Icons.print,
                                                                size: 18,
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        108,
                                                                        115,
                                                                        120)),
                                                            const SizedBox(
                                                                width: 12),
                                                            const Text(
                                                                'Print Receipt',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuDivider(),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        height: 40,
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                                Icons.delete,
                                                                size: 18,
                                                                color:
                                                                    Colors.red),
                                                            const SizedBox(
                                                                width: 12),
                                                            const Text('Delete',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .red)),
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

                                          // Tambahkan indikator diskon jika ada diskon yang diterapkan
                                          if (order.subtotalPrice >
                                              order.totalPrice)
                                            Row(
                                              children: [
                                                const Icon(Icons.discount,
                                                    size: 14,
                                                    color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Diskon: ${_formatPrice(order.subtotalPrice - order.totalPrice)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
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
                                ));
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildNavbar(),
    );
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
                  outletId: widget.outletId,
                  isManager: widget.isManager,
                )),
              ),
              Divider(),
              _buildMenuOption(
                icon: Icons.history,
                label: 'History',
                onTap: () {},
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
    Navigator.pushReplacement(
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
