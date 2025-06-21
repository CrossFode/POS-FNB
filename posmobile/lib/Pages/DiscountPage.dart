import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/Diskon.dart';
import '../model/Admin/Outlet.dart';

class DiscountPage extends StatefulWidget {
  final String token;
  final int userRoleId;
  final String outletId;
  final bool isManager;

  const DiscountPage({
    Key? key,
    required this.token,
    required this.userRoleId,
    required this.outletId,
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

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    // Jangan panggil SnackBar di sini!
    // _loadData(); // Jangan panggil di sini jika butuh context
  }

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
      }
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
        backgroundColor: Colors.green,
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
    List<String> selectedOutletIds =
        await _getOutletIdsForDiscount(discount.id!);

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
                  discount: discount,
                  selectedOutletIds: selectedOutletIds,
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
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(Diskon discount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${discount.name}"?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You won\'t be able to revert this!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, delete it!'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _deleteDiscount(discount.id!);
        if (success) {
          _showSuccessSnackBar('Deleted! Discount has been deleted.');
          _loadData(); // ganti dari _fetchDiscountsFromApi()
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
        final discountData = data['data'];

        if (discountData != null && discountData['outlets'] != null) {
          final List<dynamic> outletList = discountData['outlets'];
          return outletList
              .map<String>((outlet) => outlet['id'].toString())
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching outlet IDs for discount: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
      body: Column(
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
                fillColor: Colors.grey[200],
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
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    discount.type == 'percent'
                                        ? '${discount.amount}% off'
                                        : 'Rp ${NumberFormat('#,###').format(discount.amount)} off',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    discount.created_at != null
                                        ? 'Created: ${DateFormat('dd/MM/yyyy').format(discount.created_at!)}'
                                        : '',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Colors.blue[700]),
                                    onPressed: () => _showEditDialog(discount),
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
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: Colors.green,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _DiscountFormDialog extends StatefulWidget {
  final Diskon? discount;
  final List<Outlet> outlets;
  final List<String>? selectedOutletIds; // Tambahkan ini
  final Future<bool> Function(String name, String type, int amount,
      [List<String>? outletIds]) onSubmit;

  const _DiscountFormDialog({
    this.discount,
    required this.outlets,
    this.selectedOutletIds, // Tambahkan ini
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
  List<String> _selectedOutletIds = []; // Tambahkan ini
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.discount != null) {
      _nameController.text = widget.discount!.name;
      _amountController.text = widget.discount!.amount.toString();
      _selectedType = widget.discount!.type;

      _selectedOutletIds = widget.selectedOutletIds ?? [];

      // Initialize selected outlets if editing
      // Implementasi ini perlu disesuaikan dengan struktur data yang sebenarnya
      // _selectedOutletIds = widget.discount?.outlets
      //         ?.map<String>((outlet) => outlet.id.toString())
      //         .toList() ??
      //     [];
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

  // Modifikasi _handleSubmit untuk menyertakan outletIds
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await widget.onSubmit(
        _nameController.text.trim(),
        _selectedType,
        int.parse(_amountController.text),
        _selectedOutletIds, // Kirim outlet yang dipilih
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 600 ? 16.0 : 80.0,
          vertical: 24.0,
        ),
        child: Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.discount != null ? 'Edit Discount' : 'New Discount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Form Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name field
                        const Text(
                          'Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter discount name',
                            contentPadding: const EdgeInsets.all(16),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.green, width: 2),
                            ),
                            prefixIcon:
                                Icon(Icons.discount, color: Colors.green),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Type field
                        const Text(
                          'Discount Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[100],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _typeSelectionButton(
                                  title: 'Percentage',
                                  icon: Icons.percent,
                                  value: 'percent',
                                ),
                              ),
                              Expanded(
                                child: _typeSelectionButton(
                                  title: 'Fixed',
                                  icon: Icons.attach_money,
                                  value: 'fixed',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Amount field
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter amount',
                            contentPadding: const EdgeInsets.all(16),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.green, width: 2),
                            ),
                            prefixIcon: Icon(
                              _selectedType == 'fixed'
                                  ? Icons.attach_money
                                  : Icons.percent,
                              color: Colors.green,
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

                        // ASSIGN OUTLET Section
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          child: const Text(
                            'ASSIGN OUTLET',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7C7C7C),
                            ),
                          ),
                        ),
                        const Divider(thickness: 1.5, height: 24),

                        // Container dengan tinggi terbatas jika outlet > 5
                        Container(
                          // Tinggi container dibatasi jika jumlah outlet > 5
                          // Setiap item outlet tingginya sekitar 40px
                          height: widget.outlets.length > 5
                              ? 200
                              : null, // 5 outlets x 40px = 200px
                          decoration: widget.outlets.length > 5
                              ? BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: ListView.builder(
                            shrinkWrap: true,
                            // Hilangkan NeverScrollableScrollPhysics agar bisa scroll
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
                                      child: Checkbox(
                                        value: _selectedOutletIds
                                            .contains(outlet.id.toString()),
                                        onChanged: (bool? selected) {
                                          setState(() {
                                            if (selected == true) {
                                              if (!_selectedOutletIds.contains(
                                                  outlet.id.toString())) {
                                                _selectedOutletIds
                                                    .add(outlet.id.toString());
                                              }
                                            } else {
                                              _selectedOutletIds.removeWhere(
                                                  (id) =>
                                                      id ==
                                                      outlet.id.toString());
                                            }
                                          });
                                        },
                                        activeColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer/Buttons
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          elevation: 0,
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom button untuk pemilihan tipe diskon
  Widget _typeSelectionButton(
      {required String title, required IconData icon, required String value}) {
    final isSelected = _selectedType == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.transparent,
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
